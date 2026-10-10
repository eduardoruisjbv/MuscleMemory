local _, MM = ...

-- Native action IDs have separate namespaces. Synthetic IDs are only UI keys;
-- they must never be passed to spell APIs.
local namespaces={summonmount=1000000000,item=2000000000,macro=3000000000,flyout=4000000000}

function MM:ActionKey(action)
    if action.kind=="spell" then return action.id end
    local namespace=namespaces[action.kind]
    if namespace and type(action.id)=="number" then return -namespace-action.id end
end

function MM:DecorateAction(action,slot)
    if action.kind=="macro" and slot and GetMacroInfo then
        action.name,action.icon,action.body=GetMacroInfo(action.id)
    elseif action.kind=="item" and C_Item.GetItemInfo then
        local name,_,_,_,_,_,_,_,_,icon=C_Item.GetItemInfo(action.id)
        action.name,action.icon=name,icon
    elseif action.kind=="spell" and C_MountJournal and C_MountJournal.GetMountFromSpell then
        action.mountID=action.id==150544 and 0 or C_MountJournal.GetMountFromSpell(action.id)
    elseif action.kind=="summonmount" and C_MountJournal then
        if action.id==0 then
            action.name,action.icon,action.spellID="Summon Random Favorite Mount",413588,150544
        else
            local name,spellID,icon=C_MountJournal.GetMountInfoByID(action.id)
            action.name,action.spellID,action.icon=name,spellID,icon
        end
    end
    action.icon=action.icon or (slot and GetActionTexture(slot)) or 134400
    return action
end

function MM:ActionEntry(action)
    local key=self:ActionKey(action)
    if not key then return end
    self:DecorateAction(action)
    if action.kind=="spell" and action.mountID==nil then return end
    local copied=action.mountID~=nil and {kind="summonmount",id=action.mountID} or self:Copy(action)
    self:DecorateAction(copied)
    local role=copied.kind=="summonmount" and "mount" or "utility"
    return {id=key,name=copied.name or ({macro="Source macro (recapture)",item="Item",flyout="Spell menu"})[copied.kind] or "Mount",
        icon=copied.icon,role=role,curated=true,action=copied,spellID=copied.spellID,
        purpose={primary=role=="mount" and "travel" or "utility",cadence="utility",description=role=="mount"
            and "Travel / fly / move faster. Copies the exact source selection; does not choose another mount."
            or "Source utility action; copied only when the same action is available on the destination."}}
end

function MM:FindExactMacro(action)
    if not action.body or not GetMacroInfo then return end
    local account,character=GetNumMacros()
    for _,range in ipairs({{1,account},{(MAX_ACCOUNT_MACROS or 120)+1,(MAX_ACCOUNT_MACROS or 120)+character}}) do
        for index=range[1],range[2] do
            local name,_,body=GetMacroInfo(index)
            if name and body==action.body then return index end
        end
    end
end

function MM:ResolveUtilityAction(action)
    if action.kind=="summonmount" and C_MountJournal then
        if action.id==0 then return self:Copy(action) end
        local name,_,_,_,_,_,_,_,_,hidden,collected=C_MountJournal.GetMountInfoByID(action.id)
        if name and collected and not hidden then return self:Copy(action) end
    elseif action.kind=="macro" then
        local index=self:FindExactMacro(action)
        if index then local copy=self:Copy(action); copy.id=index; return copy end
    elseif action.kind=="item" and C_Item.GetItemCount then
        if C_Item.GetItemCount(action.id,false,false,false)>0 or (PlayerHasToy and PlayerHasToy(action.id)) then
            return self:Copy(action)
        end
    end
end

function MM:EnrichActions(profile)
    profile.spells=profile.spells or {}
    for slot,action in pairs(profile.actions or {}) do
        if self:IsManagedSlot(slot) then
            local entry=self:ActionEntry(action)
            if entry then profile.spells[entry.id]=entry end
        end
    end
end

function MM:UtilityTargets(reference,targets)
    local result=self:Copy(targets)
    for key,entry in pairs(reference and reference.spells or {}) do
        if entry.action then
            local available=self:ResolveUtilityAction(entry.action)
            if available then
                result[key]=self:Copy(entry)
                result[key].action,result[key].learned=available,true
            end
        end
    end
    return result
end

function MM:ActionMatches(actual,desired)
    if not desired then return not actual end
    if not actual then return false end
    if desired.mountID~=nil and actual.kind=="summonmount" then return actual.id==desired.mountID end
    if desired.kind=="summonmount" and actual.kind=="spell" and C_MountJournal.GetMountFromSpell then
        local mountID=actual.id==150544 and 0 or C_MountJournal.GetMountFromSpell(actual.id)
        return mountID==desired.id
    end
    if desired.kind=="spell" then
        if actual.kind~="spell" then return false end
        return actual.id==desired.id or actual.id==C_SpellBook.FindBaseSpellByID(desired.id)
            or actual.id==C_SpellBook.FindSpellOverrideByID(desired.id)
    end
    if actual.kind~=desired.kind then return false end
    if desired.kind=="macro" and desired.body then
        return select(3,GetMacroInfo(actual.id))==desired.body
    end
    return actual.id==desired.id
end

function MM:PutAction(slot,action)
    if not action then
        PickupAction(slot); ClearCursor()
        return GetActionInfo(slot)==nil,"Could not clear slot "..slot
    end
    if action.kind=="spell" then
        if action.mountID~=nil then return self:PutAction(slot,{kind="summonmount",id=action.mountID}) end
        return self:PutSpell(slot,action.id)
    end
    if action.kind=="summonmount" then
        -- Pickup takes a DISPLAY index, not a mount ID. Do not alter journal filters.
        local index=action.id==0 and 0 or nil
        if not index then
            for display=1,C_MountJournal.GetNumDisplayedMounts() do
                if C_MountJournal.GetDisplayedMountID(display)==action.id then index=display; break end
            end
        end
        if not index then return false,"The mount is hidden by collection filters. Open Mounts and clear the filters." end
        C_MountJournal.Pickup(index)
        local kind,id=GetCursorInfo()
        if kind~="mount" or id~=action.id then
            ClearCursor(); return false,"Could not pick up the exact source mount."
        end
    elseif action.kind=="flyout" then
        local bank=Enum.SpellBookSpellBank.Player
        local found
        for line=1,C_SpellBook.GetNumSpellBookSkillLines() do
            local skill=C_SpellBook.GetSpellBookSkillLineInfo(line)
            if skill then
                for index=skill.itemIndexOffset+1,skill.itemIndexOffset+skill.numSpellBookItems do
                    local item=C_SpellBook.GetSpellBookItemInfo(index,bank)
                    if item and item.itemType==Enum.SpellBookItemType.Flyout and item.actionID==action.id then
                        found=index; break
                    end
                end
            end
            if found then break end
        end
        if not found then return false,"O menu de habilidades não está disponível no grimório atual." end
        C_SpellBook.PickupSpellBookItem(found,bank)
        local kind,id=GetCursorInfo()
        if kind~="flyout" or id~=action.id then ClearCursor(); return false,"Não foi possível recuperar o menu de habilidades." end
    elseif action.kind=="macro" then
        local id=self:FindExactMacro(action)
        if not id then return false,"The exact macro is unavailable on this character." end
        PickupMacro(id)
        if GetCursorInfo()~="macro" then ClearCursor(); return false,"Could not pick up the macro." end
    elseif action.kind=="item" then
        if PlayerHasToy and PlayerHasToy(action.id) and C_ToyBox and C_ToyBox.PickupToyBoxItem then
            C_ToyBox.PickupToyBoxItem(action.id)
        else C_Item.PickupItem(action.id) end
        local kind,id=GetCursorInfo()
        if kind~="item" or id~=action.id then ClearCursor(); return false,"Could not pick up the item." end
    else return false,"This action type cannot be copied yet: "..tostring(action.kind) end
    PlaceAction(slot); ClearCursor()
    local kind,id=GetActionInfo(slot)
    return self:ActionMatches(kind and {kind=kind,id=id},action),"The game rejected the action in slot "..slot
end

function MM:SaveVisitedBars()
    if not self.current or InCombatLockdown() or self:Settings().auto or GetCursorInfo() then return end
    local profile=self.db.characters[self.current.key]
    if not profile then return end
    profile.actions=self:ReadActions()
    profile.bindings=self:Copy(self:ReadBindings())
    profile.captured=time()
    self:EnrichActions(profile)
    self:InvalidateContext()
end

function MM:ReferenceOptions(class)
    local profiles={}
    for key,profile in pairs(self.db.characters) do
        if profile.class==class then profiles[key]=profile end
    end
    for key,profile in pairs(self.db.references) do
        if profile.class==class then profiles[key]=profile end
    end
    -- Pre-specialization records should not duplicate a character with a proper spec.
    local specialized={}
    for key,profile in pairs(profiles) do
        if profile.spec~=0 then specialized[key:match("^(.-):[^:]+$") or key]=true end
    end
    for key,profile in pairs(profiles) do
        if profile.spec==0 and specialized[key:match("^(.-):[^:]+$") or key] then profiles[key]=nil end
    end
    return profiles
end
