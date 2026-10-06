local addonName, MM = ...
MM.MAX_SLOT = 180
MM.version = "0.7.0"
local bank = Enum.SpellBookSpellBank.Player
local specAPI = C_SpecializationInfo

function MM:IsManagedSlot(slot)
    -- Excludes stance/form pages, override and extra-action pages.
    return slot >= 1 and (slot <= 72 or (slot >= 145 and slot <= 180))
end

function MM:Copy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k,v in pairs(value) do copy[k] = self:Copy(v) end
    return copy
end

function MM:Print(message)
    print("|cff51d6c6MuscleMemory|r "..message)
end

function MM:SpecInfo(index, classID)
    local fn = specAPI and specAPI.GetSpecializationInfo or GetSpecializationInfo
    return fn(index, false, false, nil, nil, nil, classID)
end

function MM:Identity()
    local _, class, classID = UnitClass("player")
    local index = (specAPI and specAPI.GetSpecialization or GetSpecialization)()
    local spec, name
    if index then spec, name = self:SpecInfo(index) end
    return UnitGUID("player"), class, classID, spec or 0, name or "No specialization"
end

function MM:ProfileKey()
    local guid, _, _, spec = self:Identity()
    return guid..":"..spec
end

function MM:Settings()
    local key = self:ProfileKey()
    self.db.settings[key] = self.db.settings[key] or {}
    local settings=self.db.settings[key]
    if not settings.sourceKey and not settings.sourceClass then
        local preferred=self.db.mainReference and self.db.references[self.db.mainReference]
        if preferred and preferred.key~=key then settings.sourceKey=preferred.key end
        if not settings.sourceKey then
            local newest,newestKey
            for referenceKey,reference in pairs(self.db.references) do
                if referenceKey~=key and (not newest or (reference.captured or 0)>(newest.captured or 0)
                    or (reference.captured or 0)==(newest.captured or 0) and referenceKey<newestKey) then
                    newest,newestKey=reference,referenceKey
                end
            end
            if newest then settings.sourceKey=newestKey end
        end
    end
    local guid,class,_,spec=self:Identity()
    if self.db.levelingAuto and self.db.levelingAuto[guid]==self.AUTO_CONSENT_VERSION then
        settings.autoMode,settings.auto="leveling",true
        settings.autoConsent,settings.autoConsentMode=self.AUTO_CONSENT_VERSION,"leveling"
        settings.targetClass,settings.targetSpec=class,spec
    end
    return settings
end

function MM:SpellInfo(id)
    local info = C_Spell.GetSpellInfo(id)
    if not info then C_Spell.RequestLoadSpellData(id) end
    return info or {name="Ability #"..id, iconID=134400}
end

function MM:ReadActions()
    local result = {}
    for slot=1,self.MAX_SLOT do
        if self:IsManagedSlot(slot) then
            local kind, id, subType = GetActionInfo(slot)
            if kind then
                result[slot] = {kind=kind, id=id, subType=subType}
                if self.DecorateAction then self:DecorateAction(result[slot],slot) end
            end
        end
    end
    return result
end

function MM:InvalidateContext()
    self.contextCache=nil
end

local bindingBars={
    {first=25,last=36,prefix="MULTIACTIONBAR3BUTTON",frame="MultiBarRightButton"},
    {first=37,last=48,prefix="MULTIACTIONBAR4BUTTON",frame="MultiBarLeftButton"},
    {first=49,last=60,prefix="MULTIACTIONBAR2BUTTON",frame="MultiBarBottomRightButton"},
    {first=61,last=72,prefix="MULTIACTIONBAR1BUTTON",frame="MultiBarBottomLeftButton"},
    {first=145,last=156,prefix="MULTIACTIONBAR5BUTTON",frame="MultiBar5Button"},
    {first=157,last=168,prefix="MULTIACTIONBAR6BUTTON",frame="MultiBar6Button"},
    {first=169,last=180,prefix="MULTIACTIONBAR7BUTTON",frame="MultiBar7Button"},
}

function MM:ReadBindings()
    if InCombatLockdown() then return self.bindingSnapshot or {} end
    local result={}
    for slot=1,self.MAX_SLOT do if self:IsManagedSlot(slot) then result[slot]={} end end
    local function collect(slot,command,frameName)
        if not result[slot] or not GetBindingKey then return end
        local commands={command}
        if frameName then commands[#commands+1]="CLICK "..frameName..":LeftButton" end
        for _,binding in ipairs(commands) do
            for _,key in ipairs({GetBindingKey(binding)}) do
                -- Include real click bindings and discard overridden commands when observable.
                local effective=GetBindingAction and GetBindingAction(key,true)
                if not effective or effective == "" or effective == binding then
                    local found=false
                    for _,stored in ipairs(result[slot]) do if stored == key then found=true end end
                    if not found then result[slot][#result[slot]+1]=key end
                end
            end
        end
    end
    local page=GetActionBarPage and GetActionBarPage() or 1
    for index=1,12 do
        local frameName="ActionButton"..index
        local frame=_G[frameName]
        local slot=frame and frame.action or (page-1)*12+index
        collect(slot,frame and frame.bindingAction or "ACTIONBUTTON"..index,frameName)
    end
    for _,bar in ipairs(bindingBars) do
        for slot=bar.first,bar.last do
            local index=slot-bar.first+1
            collect(slot,bar.prefix..index,bar.frame..index)
        end
    end
    self.bindingSnapshot=result
    return result
end

function MM:GetBindingForSlot(slot,reference)
    local keys
    if reference then
        if not reference.bindings then return "Keybinding not captured",{} end
        keys=reference.bindings[slot] or {}
    else
        local settings=self:Settings()
        if settings.targetClass~=self.current.class or settings.targetSpec~=self.current.spec then
            return "Log in to the destination",{}
        end
        keys=(self.bindingSnapshot or self:ReadBindings())[slot] or {}
    end
    local labels={}
    for _,key in ipairs(keys) do labels[#labels+1]=GetBindingText and GetBindingText(key,1) or key end
    return #labels>0 and table.concat(labels," / ") or "No keybinding",keys
end

function MM:Scan()
    if InCombatLockdown() then self.scanPending = true; return end
    self.scanPending = nil
    local guid, class, classID, spec, specName = self:Identity()
    local spells = {}
    for line=1,C_SpellBook.GetNumSpellBookSkillLines() do
        local skill = C_SpellBook.GetSpellBookSkillLineInfo(line)
        if skill and not skill.isGuild and not skill.offSpecID then
            for slot=skill.itemIndexOffset+1,skill.itemIndexOffset+skill.numSpellBookItems do
                local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
                if item and item.itemType == Enum.SpellBookItemType.Spell
                    and item.spellID and not item.isPassive and not item.isOffSpec then
                    local id = item.spellID
                    local entry = self:CatalogEntry(id,class,spec)
                        or self:CatalogEntry(item.actionID,class,spec)
                        or {id=id, role="unknown"}
                    entry.id = id
                    entry.class,entry.learned=class,true
                    entry.baseID = item.actionID
                    entry.name, entry.icon = item.name, item.iconID
                    local info = self:SpellInfo(id)
                    entry.castTime = info.castTime
                    if self.ReadUsageMetadata then self:ReadUsageMetadata(entry) end
                    -- Metadata is collected outside combat and never stored if secret.
                    local costs = C_Spell.GetSpellPowerCost(id)
                    for _, cost in ipairs(costs or {}) do
                        local amount, power = cost.cost, cost.type
                        if type(amount) == "number" and type(power) == "number"
                            and not (issecretvalue and (issecretvalue(amount) or issecretvalue(power))) then
                            local maximum = UnitPowerMax("player",power)
                            if not (issecretvalue and issecretvalue(maximum)) and maximum and maximum > 0 and amount > 0 then
                                entry.costRatio = amount/maximum
                            end
                        end
                    end
                    if entry.role == "unknown" then
                        if C_SpellBook.IsSpellBookItemHarmful(slot,bank) then entry.role="damage"
                        elseif C_SpellBook.IsSpellBookItemHelpful(slot,bank) then entry.role="support" end
                    end
                    if C_MountJournal and C_MountJournal.GetMountFromSpell and C_MountJournal.GetMountFromSpell(id) then
                        entry.role="mount"
                        entry.purpose={primary="travel",cadence="utility",description="Travel / fly / move faster using the selected mount."}
                    end
                    spells[id] = entry
                end
            end
        end
    end
    local assisted=self:ReadAssistedRotation(spells)
    local playerName, realm = UnitFullName("player")
    local race,raceID
    if UnitRace then local raceName; raceName,race,raceID=UnitRace("player") end
    self.current = {key=guid..":"..spec, class=class, classID=classID, spec=spec,race=race,raceID=raceID,
        specName=specName, name=playerName.." - "..(realm or GetRealmName()), spells=spells,
        updated=time(),assisted=assisted}
    local previous=self.db.characters[self.current.key]
    local observed=self:Copy(self.current)
    if previous then
        observed.actions,observed.bindings,observed.captured=previous.actions,previous.bindings,previous.captured
    end
    self.db.characters[self.current.key] = observed
    self:ReadBindings()
    self:InvalidateContext()
    local classEntry = self:Class(class)
    local found = false
    for _, id in ipairs(classEntry.specs) do if id == spec then found=true end end
    if spec ~= 0 and not found then classEntry.specs[#classEntry.specs+1]=spec end
    local settings = self:Settings()
    settings.targetClass = settings.targetClass or class
    settings.targetSpec = settings.targetSpec or spec
    if self.RefreshUI then self:RefreshUI() end
end

function MM:Capture()
    if InCombatLockdown() then return self:Print("Leave combat to capture action bars.") end
    if self:Settings().auto then
        return self:Print("Disable automatic application before capturing a new reference.")
    end
    self:Scan()
    if not next(self.current.spells) then return self:Print("The spellbook has not loaded yet. Try again.") end
    local reference = self:Copy(self.current)
    reference.actions = self:ReadActions()
    reference.bindings = self:Copy(self:ReadBindings())
    reference.captured = time()
    self.db.references[reference.key] = reference
    self.db.mainReference=reference.key
    self:InvalidateContext()
    self:Settings().sourceKey = reference.key
    self:RefreshUI()
    self:Print("Reference saved: "..reference.name.." / "..reference.specName..".")
end

function MM:TargetSpells(class, spec)
    if self.current and class == self.current.class and spec == self.current.spec then
        return self.current.spells, "Current spellbook"
    end
    local result = {}
    for id,catalog in pairs(self.catalog) do
        local entry = self:CatalogEntry(id,class,spec)
        if entry and not catalog.racial and (not self.IsActivePurpose or self:IsActivePurpose(entry)) then
            local info = self:SpellInfo(id)
            entry.name,entry.icon = info.name,info.iconID
            result[id] = entry
        end
    end
    local observed = false
    for _, character in pairs(self.db.characters) do
        if character.class == class and character.spec == spec then
            for id,spell in pairs(character.spells) do
                if not spell.action then
                    local entry=self:Copy(spell)
                    self:RefreshClassification(entry,class,spec)
                    if not self.IsActivePurpose or self:IsActivePurpose(entry) then result[id]=entry end
                end
            end
            observed=true
        end
    end
    return result, observed and "Catalog + visited characters" or "Base catalog; talents not verified"
end

function MM:Context()
    local settings = self:Settings()
    local reference = self.db.references[settings.sourceKey] or self.db.characters[settings.sourceKey]
    if reference and not reference.actions then reference=nil end
    if self:IsLevelingMode() then reference=self:LevelingReference() end
    local key = (self:IsLevelingMode() and ("leveling:"..self.current.key) or settings.sourceKey or "none")..">"..(settings.targetClass or "")..":"..(settings.targetSpec or 0)
    if self.contextCache and self.contextCache.key == key then
        local cache=self.contextCache
        return cache.reference,cache.targets,cache.overrides,cache.matches,cache.label
    end
    if reference then
        for _,spell in pairs(reference.spells) do
            if not spell.action and spell.role~="mount" then self:RefreshClassification(spell,reference.class,reference.spec) end
        end
        self:EnrichActions(reference)
        -- Action bars can save a base/override ID different from the book key.
        -- Enrich that frozen action without changing its original bar position.
        for slot=1,self.MAX_SLOT do
            local action=reference.actions[slot]
            if self:IsManagedSlot(slot) and action and action.kind=="spell" and not reference.spells[action.id] then
                local learned=self.FindProfileSpell and self:FindProfileSpell(reference.spells,action.id)
                local entry=learned and self:Copy(learned) or self:CatalogEntry(action.id,reference.class,reference.spec)
                    or {role="unknown"}
                if learned then entry.baseID=learned.baseID or learned.id end
                entry.id,entry.class=action.id,reference.class
                local info=self:SpellInfo(action.id)
                entry.name,entry.icon=entry.name or info.name,entry.icon or info.iconID
                self:RefreshClassification(entry,reference.class,reference.spec)
                reference.spells[action.id]=entry
            end
        end
    end
    self.db.overrides[key] = self.db.overrides[key] or {}
    local targets, label = self:TargetSpells(settings.targetClass,settings.targetSpec)
    targets=self:UtilityTargets(reference,targets)
    local overrides = self.db.overrides[key]
    local matches = reference and self:Suggest(reference,targets,overrides,settings.targetSpec,settings.targetClass) or {}
    self.contextCache={key=key,reference=reference,targets=targets,overrides=overrides,matches=matches,label=label}
    return reference, targets, overrides, matches, label
end

function MM:SetMapping(sourceID, targetID)
    if InCombatLockdown() then return self:Print("Leave combat to edit mappings.") end
    local reference, targets, overrides = self:Context()
    if not reference or not reference.spells[sourceID] then return end
    if self:IsLevelingMode() then return self:Print("In leveling mode, right-click to adjust priority or pin the position.") end
    if targetID and not targets[targetID] then return self:Print("This ability does not belong to the selected destination.") end
    overrides[sourceID] = targetID -- nil restores automatic matching, false explicitly excludes.
    self:InvalidateContext()
    self:RefreshUI()
    if self:Settings().auto then self:QueueAuto() end
end

function MM:UseAutomaticSuggestions()
    if InCombatLockdown() then return self:Print("Leave combat to restore suggestions.") end
    local reference,_,overrides=self:Context()
    if not reference then return end
    for id in pairs(overrides) do overrides[id]=nil end
    self:InvalidateContext()
    self:RefreshUI()
end

function MM:GetApplyState()
    local empty={plan={},skipped=0,changed=0}
    if InCombatLockdown() then return false,"Leave combat to preview and apply changes.",empty end
    if GetCursorInfo() then return false,"Drop the ability or item on your cursor before applying.",empty end
    if UnitInVehicle("player") or (HasOverrideActionBar and HasOverrideActionBar())
        or (HasVehicleActionBar and HasVehicleActionBar()) or (HasPossessBar and HasPossessBar()) then
        return false,"Leave the vehicle or temporary action bar.",empty
    end
    local settings=self:Settings()
    if settings.targetClass~=self.current.class or settings.targetSpec~=self.current.spec then
        return false,"Log in to the destination character and specialization.",empty
    end
    local reference,_,_,matches=self:Context()
    if not reference then return false,"Capture and select your main’s action bars.",empty end
    if reference.key==self.current.key and not self:IsLevelingMode() then return false,"Select a reference from another character or specialization.",empty end
    local _,targets=self:Context()
    local plan,skipped=self:BuildCurrentPlan(reference,matches,targets,self:ReadActions())
    local differences=self:DescribePlanBindings(reference,plan)
    local preview={plan=plan,skipped=skipped,changed=#plan,bindingMismatches=differences}
    if #plan==0 then return false,"No changes available; review pending items.",preview end
    local reason=#plan.." positions will change out of combat."
    if differences>0 then reason=reason.." "..differences.." keybindings differ from the main; review the preview." end
    return true,reason,preview
end

function MM:DescribePlanBindings(reference,plan)
    local differences=0
    for _,change in ipairs(plan) do
        local sourceLabel,sourceKeys=self:GetBindingForSlot(change.slot,reference)
        local targetLabel,targetKeys=self:GetBindingForSlot(change.slot)
        change.sourceBinding,change.targetBinding=sourceLabel,targetLabel
        local shared=false
        for _,sourceKey in ipairs(sourceKeys) do
            for _,targetKey in ipairs(targetKeys) do if sourceKey==targetKey then shared=true end end
        end
        if #sourceKeys>0 and not shared then
            change.bindingWarning="Main keybinding: "..sourceLabel.."; destination: "..targetLabel..". Keybindings will not be changed."
            differences=differences+1
        end
    end
    return differences
end

function MM:GetPreview()
    local _,reason,preview=self:GetApplyState()
    preview.reason=reason
    return preview
end

function MM:GetUndoState()
    if InCombatLockdown() then return false,"Leave combat to restore action bars." end
    if GetCursorInfo() then return false,"Drop the item on your cursor before restoring." end
    if UnitInVehicle("player") or (HasOverrideActionBar and HasOverrideActionBar())
        or (HasVehicleActionBar and HasVehicleActionBar()) or (HasPossessBar and HasPossessBar()) then
        return false,"Leave the vehicle or temporary action bar." end
    local undo=self.db.undo[self:ProfileKey()]
    if not undo or #undo.changes==0 then return false,"No previous application for this specialization." end
    return true,"Restores the last application and preserves subsequent edits."
end

function MM:QueueAuto()
    if self.autoQueued then return end
    self.autoQueued=true
    C_Timer.After(1,function()
        self.autoQueued=nil
        if InCombatLockdown() then self.autoPending=true; return end
        self.autoPending=nil
        if self:AutoAuthorized() then self:Apply(true) end
    end)
end

function MM:PutSpell(slot,id)
    C_Spell.PickupSpell(id)
    local kind = GetCursorInfo()
    if kind ~= "spell" then ClearCursor(); return false, "Could not pick up ability #"..id end
    PlaceAction(slot)
    ClearCursor()
    local actualKind, actualID = GetActionInfo(slot)
    if actualKind ~= "spell" then return false, "The game rejected slot "..slot end
    if actualID ~= id then
        local base = C_SpellBook.FindBaseSpellByID(id)
        local override = C_SpellBook.FindSpellOverrideByID(id)
        if actualID ~= base and actualID ~= override then return false, "Different ability in slot "..slot end
    end
    return true
end

function MM:RestoreChange(change)
    local before = change.before
    return self:PutAction(change.slot,before or nil)
end

function MM:Apply(automatic)
    if automatic and not self:AutoAuthorized() then return end
    if InCombatLockdown() then
        if automatic then self.autoPending=true else self:Print("Leave combat to apply changes.") end
        return
    end
    if GetCursorInfo() then
        if automatic then self.autoPending=true end
        if not automatic then self:Print("Drop the item on your cursor before applying.") end
        return
    end
    if UnitInVehicle("player") or (HasOverrideActionBar and HasOverrideActionBar())
        or (HasVehicleActionBar and HasVehicleActionBar()) or (HasPossessBar and HasPossessBar()) then
        if automatic then self.autoPending=true; return end
        return self:Print("Wait until you leave the vehicle or temporary action bar.")
    end
    self:Scan()
    local settings = self:Settings()
    if settings.targetClass ~= self.current.class or settings.targetSpec ~= self.current.spec then
        if not automatic then self:Print("Log in to the destination character and specialization to apply.") end
        return
    end
    local reference, targets, _, matches = self:Context()
    if not reference then
        if not automatic then self:Print("Capture your main’s action bars and select that reference.") end
        return
    end
    if reference.key == self.current.key and not self:IsLevelingMode() then
        if not automatic then self:Print("This is the current reference. Select another character or specialization.") end
        return
    end
    local plan, skipped = self:BuildCurrentPlan(reference,matches,targets,self:ReadActions())
    if automatic and self:DescribePlanBindings(reference,plan)>0 then
        self:DisableAutomatic()
        self:Print("Automatic mode disabled: keybindings differ from the main. Review the preview before applying.")
        self:RefreshUI()
        return
    end
    if #plan == 0 then
        if not automatic then self:Print("No changes available. Pending / protected: "..skipped..".") end
        return
    end
    -- Persist before first mutation. If a protected call errors, /mm undo can recover touched slots.
    local undo = automatic and self.db.undo[self.current.key]
    if not undo or not undo.automatic then undo={key=self.current.key,changes={},created=time(),automatic=automatic} end
    self.db.undo[self.current.key] = undo
    local applied = 0
    self.applying=true
    for _, change in ipairs(plan) do
        local recorded
        for _,old in ipairs(undo.changes) do
            if old.slot==change.slot then
                old.after,old.id,old.clearing=change.after,change.id,change.clearing
                recorded=true; break
            end
        end
        if not recorded then undo.changes[#undo.changes+1] = self:Copy(change) end
        local after=change.after or (not change.clearing and {kind="spell",id=change.id}) or nil
        local ok, success, reason = pcall(self.PutAction,self,change.slot,after)
        if not ok or not success then
            ClearCursor()
            self:DisableAutomatic()
            self:Print("Application interrupted: "..tostring(ok and reason or success)..". Use /mm undo.")
            break
        end
        applied=applied+1
    end
    self.applying=nil
    self:RecordLevelingLayout()
    self:Print(applied.." slots applied. Pending / protected: "..skipped..". /mm undo will undo this.")
    self:RefreshUI()
end

function MM:Undo()
    if InCombatLockdown() then return self:Print("Leave combat to undo changes.") end
    if GetCursorInfo() then return self:Print("Drop the item on your cursor before undoing.") end
    if UnitInVehicle("player") or (HasOverrideActionBar and HasOverrideActionBar())
        or (HasVehicleActionBar and HasVehicleActionBar()) or (HasPossessBar and HasPossessBar()) then
        return self:Print("Wait until you leave the temporary action bar before undoing.")
    end
    local key = self:ProfileKey()
    local undo = self.db.undo[key]
    if not undo then return self:Print("There is no application to undo for this specialization.") end
    self:DisableAutomatic()
    local remaining, restored, changed = {}, 0, 0
    self.applying=true
    for _, change in ipairs(undo.changes) do
        local kind,id = GetActionInfo(change.slot)
        local after=change.after or (not change.clearing and {kind="spell",id=change.id}) or nil
        if self:ActionMatches(kind and {kind=kind,id=id},after) then
            local ok, success = pcall(self.RestoreChange,self,change)
            if not ok then ClearCursor() end
            if ok and success then restored=restored+1 else remaining[#remaining+1]=change end
        elseif (not change.before and not kind)
            or (change.before and kind == change.before.kind and id == change.before.id) then
            -- Already restored / mutation never happened.
        else
            changed=changed+1 -- Preserve edits the player made after applying.
        end
    end
    self.applying=nil
    self:InvalidateContext()
    if #remaining == 0 then self.db.undo[key]=nil else undo.changes=remaining end
    self:Print(restored.." slots restored; "..changed.." later edits preserved; "..#remaining.." pending. Automatic mode disabled.")
    self:RefreshUI()
end

local events = CreateFrame("Frame")
MM.events=events
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("NEW_MOUNT_ADDED")
events:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
events:RegisterEvent("CURSOR_CHANGED")
events:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
events:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
events:RegisterEvent("TRAIT_CONFIG_UPDATED")
events:RegisterEvent("UPDATE_BINDINGS")
events:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
events:RegisterEvent("SPELL_DATA_LOAD_RESULT")
events:SetScript("OnEvent",function(_,event,arg)
    if event == "ADDON_LOADED" and arg == addonName then
        MuscleMemoryDB = MuscleMemoryDB or {}
        MM.db=MuscleMemoryDB
        for _,key in ipairs({"characters","references","settings","overrides","undo","levelingAuto"}) do
            MM.db[key] = MM.db[key] or {}
        end
        MM.db.schema=3
        for _,settings in pairs(MM.db.settings) do
            if settings.autoConsent~=MM.AUTO_CONSENT_VERSION then settings.auto=false end
        end
        MM:InvalidateContext()
        for _,profiles in ipairs({MM.db.references,MM.db.characters}) do
            for _,profile in pairs(profiles) do
                for _,spell in pairs(profile.spells or {}) do
                    if not spell.action then MM:RefreshClassification(spell,profile.class,profile.spec) end
                end
                MM:EnrichActions(profile)
            end
        end
    elseif event == "PLAYER_LOGIN" then
        MM:Scan()
        C_Timer.After(2,function() MM:SaveVisitedBars(); if MM.RefreshUI then MM:RefreshUI() end end)
        MM:QueueAuto()
        MM:Print("/mm opens the editor. Start by capturing your main’s action bars.")
    elseif event == "PLAYER_LOGOUT" then
        if not InCombatLockdown() then MM:Scan(); MM:SaveVisitedBars() end
    elseif MM.db and MM.current then
        if event == "UPDATE_BINDINGS" or event == "ACTIONBAR_PAGE_CHANGED" then
            if InCombatLockdown() then MM.bindingsPending=true else MM:ReadBindings() end
            if event == "ACTIONBAR_PAGE_CHANGED" and MM.RefreshUI then MM:RefreshUI() end
        elseif event == "ACTIONBAR_SLOT_CHANGED" then
            MM:InvalidateContext()
            if not MM.applying and MM.RefreshUI then MM:RefreshUI() end
        elseif event == "CURSOR_CHANGED" or event == "UPDATE_VEHICLE_ACTIONBAR" or event == "UPDATE_OVERRIDE_ACTIONBAR" then
            if MM.autoPending and not GetCursorInfo() then MM:QueueAuto() end
        elseif event == "SPELL_DATA_LOAD_RESULT" then
            MM:InvalidateContext()
        elseif event == "PLAYER_REGEN_ENABLED" then
            if MM.bindingsPending then MM.bindingsPending=nil; MM:ReadBindings() end
            if MM.scanPending then MM:Scan() end
            if MM.autoPending then MM:QueueAuto() end
        elseif event == "SPELLS_CHANGED" or event == "TRAIT_CONFIG_UPDATED" or event == "PLAYER_LEVEL_UP" or event == "NEW_MOUNT_ADDED"
            or (event == "PLAYER_SPECIALIZATION_CHANGED" and arg == "player") then
            if MM.scanQueued then return end
            MM.scanQueued=true
            C_Timer.After(0.5,function()
                MM.scanQueued=nil
                MM:Scan()
                MM:QueueAuto()
            end)
        end
    end
end)

SLASH_MUSCLEMEMORY1="/mm"
SLASH_MUSCLEMEMORY2="/musclememory"
SlashCmdList.MUSCLEMEMORY=function(message)
    message=message:lower():match("^%s*(.-)%s*$")
    if message == "capture" then MM:Capture()
    elseif message == "apply" then MM:Apply()
    elseif message == "undo" then MM:Undo()
    else MM:ToggleUI() end
end
