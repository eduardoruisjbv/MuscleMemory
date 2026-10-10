local addonName, MM = ...
MM.MAX_SLOT = 180
MM.version = "0.7.7"
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
        local context=self.db.levelingContext and self.db.levelingContext[guid]
        if context then settings.sourceKey,settings.translator=context.sourceKey,context.translator end
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

function MM:RefreshLearnedState()
    if InCombatLockdown() then self.scanPending=true; return end
    local guid,_,_,spec=self:Identity()
    if not self.current or self.current.key~=guid..":"..spec or self.spellbookDirty then
        return self:Scan(true)
    end
    self.knownDirty=nil
    self.scanPending=nil
    local changed=false
    for _,spell in pairs(self.current.spells) do
        local learned=not spell.offSpec and (C_SpellBook.IsSpellKnown(spell.id,bank)==true
            or spell.baseID and C_SpellBook.IsSpellKnown(spell.baseID,bank)==true) or false
        if spell.learned~=learned then
            spell.learned=learned
            spell.functions=nil
            if learned then
                -- Future entries may not yet report the passive flag. Resolve
                -- only this newly unlocked entry, rather than rebuilding the book.
                local slot,spellBank=C_SpellBook.FindSpellBookSlotForSpell(spell.id,false,false,false,false)
                local item=slot and spellBank==bank and C_SpellBook.GetSpellBookItemInfo(slot,bank)
                if item then spell.isPassive=item.isPassive end
                if self.ReadUsageMetadata then self:ReadUsageMetadata(spell) end
            end
            changed=true
        end
    end
    if changed then
        self.current.updated=time()
        local observed=self.db.characters[self.current.key]
        if observed then observed.spells=self:Copy(self.current.spells); observed.updated=self.current.updated end
        self:InvalidateContext()
        if self.RefreshUI then self:RefreshUI() end
    end
end

-- Read every ability granted by the active class/spec/hero talent trees. Talent
-- alternatives are retained as candidates, while only the selected entry is
-- marked learned. This supplements the spellbook, which does not expose every
-- unselected or preview-only talent spell as a regular spellbook row.
function MM:ReadTalentSpells(class,spec,spells)
    local snapshot={}
    if not C_ClassTalents or not C_ClassTalents.GetActiveConfigID or not C_Traits
        or not C_Traits.GetConfigInfo or not C_Traits.GetTreeNodes or not C_Traits.GetNodeInfo
        or not C_Traits.GetEntryInfo or not C_Traits.GetDefinitionInfo then
        return snapshot
    end
    local ok,configID=pcall(C_ClassTalents.GetActiveConfigID)
    if not ok or not configID then return snapshot end
    local configOK,config=pcall(C_Traits.GetConfigInfo,configID)
    if not configOK or not config then return snapshot end

    for _,treeID in ipairs(config.treeIDs or {}) do
        local nodesOK,nodeIDs=pcall(C_Traits.GetTreeNodes,treeID)
        if nodesOK then
            for _,nodeID in ipairs(nodeIDs or {}) do
                local nodeOK,node=pcall(C_Traits.GetNodeInfo,configID,nodeID)
                if nodeOK and node and node.isVisible~=false then
                    local active=node.activeEntry
                    local activeEntryID=active and active.entryID
                    local rank=active and active.rank or 0
                    for _,entryID in ipairs(node.entryIDs or {}) do
                        local entryOK,entry=pcall(C_Traits.GetEntryInfo,configID,entryID)
                        local definition
                        if entryOK and entry and entry.definitionID then
                            local definitionOK,value=pcall(C_Traits.GetDefinitionInfo,entry.definitionID)
                            if definitionOK then definition=value end
                        end
                        local spellID=definition and definition.spellID
                        if type(spellID)=="number" and spellID>0 then
                            local selected=entryID==activeEntryID and rank>0
                            local talent={treeID=treeID,nodeID=nodeID,entryID=entryID,
                                selected=selected,rank=selected and rank or 0}
                            snapshot[spellID]=talent
                            local known=spells[spellID]
                            if known then
                                known.talent=true
                                known.talentSelected=selected
                                known.talentNodeID=nodeID
                                known.talentEntryID=entryID
                                if selected then known.learned=true end
                            else
                                local candidate=self:CatalogEntry(spellID,class,spec) or {id=spellID,role="unknown"}
                                candidate.id,candidate.class=spellID,class
                                candidate.name=definition.overrideName or self:SpellInfo(spellID).name
                                candidate.icon=definition.overrideIcon or self:SpellInfo(spellID).iconID
                                candidate.talent,candidate.talentSelected=true,selected
                                candidate.talentNodeID,candidate.talentEntryID=nodeID,entryID
                                candidate.learned=selected
                                local slot,spellBank
                                if C_SpellBook.FindSpellBookSlotForSpell then
                                    slot,spellBank=C_SpellBook.FindSpellBookSlotForSpell(spellID,false,false,false,false)
                                end
                                local item=slot and spellBank==bank and C_SpellBook.GetSpellBookItemInfo(slot,bank)
                                local passiveOK,isPassive
                                if C_Spell and C_Spell.IsSpellPassive then
                                    passiveOK,isPassive=pcall(C_Spell.IsSpellPassive,spellID)
                                end
                                candidate.isPassive=item and item.isPassive or passiveOK and isPassive or false
                                if self.ReadUsageMetadata then self:ReadUsageMetadata(candidate) end
                                spells[spellID]=candidate
                            end
                        end
                    end
                end
            end
        end
    end
    return snapshot
end

function MM:Scan(force)
    if InCombatLockdown() then self.scanPending = true; return end
    self.scanPending = nil
    local guid, class, classID, spec, specName = self:Identity()
    if not force and not self.spellbookDirty and self.current and self.current.key==guid..":"..spec then
        if self.knownDirty then self:RefreshLearnedState() end
        return
    end
    self.spellbookDirty,self.knownDirty=nil,nil
    local spells = {}
    for line=1,C_SpellBook.GetNumSpellBookSkillLines() do
        local skill = C_SpellBook.GetSpellBookSkillLineInfo(line)
        if skill and not skill.isGuild then
            for slot=skill.itemIndexOffset+1,skill.itemIndexOffset+skill.numSpellBookItems do
                local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
                if item and (item.itemType == Enum.SpellBookItemType.Spell
                    or item.itemType == Enum.SpellBookItemType.FutureSpell) and (item.spellID or item.actionID) then
                    local id = item.spellID or item.actionID
                    local entrySpec=skill.offSpecID or spec
                    local entry = self:CatalogEntry(id,class,entrySpec)
                        or self:CatalogEntry(item.actionID,class,entrySpec)
                        or {id=id, role="unknown"}
                    entry.id = id
                    entry.class=class
                    entry.offSpec=item.isOffSpec or skill.offSpecID~=nil
                    entry.isPassive=item.isPassive
                    entry.learned=not entry.offSpec and C_SpellBook.IsSpellKnown(id,bank)==true or false
                    entry.levelLearned=C_SpellBook.GetSpellBookItemLevelLearned(slot,bank)
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
                    -- Active-spec copies take precedence when a common spell is
                    -- listed again in another specialization's section.
                    if not spells[id] or spells[id].offSpec then spells[id] = entry end
                elseif item and item.itemType == Enum.SpellBookItemType.Flyout and item.actionID
                    and GetFlyoutInfo and GetFlyoutSlotInfo then
                    local ok,_,_,count,isKnown=pcall(GetFlyoutInfo,item.actionID)
                    if ok and type(count)=="number" and isKnown then
                        for flyoutSlot=1,count do
                            local slotOK,spellID,overrideID,slotKnown,name=pcall(GetFlyoutSlotInfo,item.actionID,flyoutSlot)
                            if slotOK and slotKnown and type(spellID)=="number" and spellID>0 then
                                local entry=spells[spellID] or self:CatalogEntry(spellID,class,spec)
                                    or {id=spellID,role="unknown"}
                                entry.id,entry.class=spellID,class
                                entry.name=entry.name or name or self:SpellInfo(spellID).name
                                entry.icon=entry.icon or self:SpellInfo(overrideID or spellID).iconID
                                entry.flyout=true
                                entry.baseID=entry.baseID or C_SpellBook.FindBaseSpellByID(spellID)
                                entry.overrideID=overrideID
                                entry.learned=true
                                local slot,spellBank=C_SpellBook.FindSpellBookSlotForSpell(spellID,false,false,false,false)
                                local spellInfo=slot and spellBank==bank and C_SpellBook.GetSpellBookItemInfo(slot,bank)
                                local passiveOK,isPassive
                                if C_Spell and C_Spell.IsSpellPassive then
                                    passiveOK,isPassive=pcall(C_Spell.IsSpellPassive,spellID)
                                end
                                entry.isPassive=spellInfo and spellInfo.isPassive or passiveOK and isPassive or false
                                if self.ReadUsageMetadata then self:ReadUsageMetadata(entry) end
                                spells[spellID]=entry
                            end
                        end
                    end
                end
            end
        end
    end
    local talents=self:ReadTalentSpells(class,spec,spells)
    if not next(spells) then
        self.spellbookDirty=true
        self.scanPending=true
        return
    end
    local assisted=self:ReadAssistedRotation(spells)
    local playerName, realm = UnitFullName("player")
    local race,raceID
    if UnitRace then local raceName; raceName,race,raceID=UnitRace("player") end
    self.current = {key=guid..":"..spec, class=class, classID=classID, spec=spec,race=race,raceID=raceID,
        specName=specName, name=playerName.." - "..(realm or GetRealmName()), spells=spells,talents=talents,
        updated=time(),assisted=assisted}
    if self.StoreCollectionSnapshot then self:StoreCollectionSnapshot() end
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
    if not self.current or not next(self.current.spells) then return self:Print("The spellbook has not loaded yet. Try again.") end
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
        return self.current.spells, next(self.current.talents or {}) and "Current spellbook + active talents" or "Current spellbook"
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
    return result, observed and "Catalog + visited spellbooks and talents" or "Base catalog; talents not verified"
end

function MM:Context()
    local settings = self:Settings()
    local reference = self.db.references[settings.sourceKey] or self.db.characters[settings.sourceKey]
    if reference and not reference.actions then reference=nil end
    local key = (settings.sourceKey or "none")..">"..(settings.targetClass or "")..":"..(settings.targetSpec or 0)
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
    local available,planned={},{}
    for id,spell in pairs(targets) do
        if not spell.isPassive and not spell.offSpec then
            planned[id]=spell
            if spell.learned~=false then available[id]=spell end
        end
    end
    local matches = reference and self:Suggest(reference,available,overrides,settings.targetSpec,settings.targetClass) or {}
    if reference then
        local future=self:Suggest(reference,planned,overrides,settings.targetSpec,settings.targetClass)
        for id,match in pairs(matches) do
            local suggestion=future[id]
            if suggestion and suggestion.id and targets[suggestion.id] and targets[suggestion.id].learned==false then
                match.future=self:Copy(suggestion)
                match.future.status="future"
            end
        end
    end
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

function MM:GetClearBarsState()
    if InCombatLockdown() then return false,"Saia do combate para limpar as barras." end
    if GetCursorInfo() then return false,"Solte o que está no cursor antes de limpar." end
    if UnitInVehicle("player") or (HasOverrideActionBar and HasOverrideActionBar())
        or (HasVehicleActionBar and HasVehicleActionBar()) or (HasPossessBar and HasPossessBar()) then
        return false,"Saia do veículo ou da barra temporária antes de limpar."
    end
    for slot=1,self.MAX_SLOT do
        if self:IsManagedSlot(slot) and GetActionInfo(slot) then
            return true,"Esvazia as barras normais, incluindo macros, itens e montarias. Mantém as teclas e a referência salva; pausa o automático. Restaurar barras desfaz."
        end
    end
    return false,"As barras normais já estão vazias."
end

function MM:ClearBars()
    local allowed,reason=self:GetClearBarsState()
    if not allowed then return self:Print(reason) end
    self:Scan()
    local actions=self:ReadActions()
    local undo={key=self.current.key,changes={},created=time(),clearPending=true}
    -- Journal the complete snapshot before touching the first slot. A later
    -- Apply merges into this journal, so Restore returns to before the cleanup.
    for slot=1,self.MAX_SLOT do
        if self:IsManagedSlot(slot) and actions[slot] then
            undo.changes[#undo.changes+1]={slot=slot,before=self:Copy(actions[slot]),after=false,clearing=true}
        end
    end
    self.db.undo[self.current.key]=undo
    self:DisableAutomatic()
    self.autoPending=nil
    self.applying=true
    local cleared=0
    for _,change in ipairs(undo.changes) do
        local ok,success,errorMessage=pcall(self.PutAction,self,change.slot,nil)
        if not ok or not success then
            ClearCursor()
            self:Print("Limpeza interrompida: "..tostring(ok and errorMessage or success)..". Restaurar barras recupera as posições removidas.")
            break
        end
        cleared=cleared+1
    end
    self.applying=nil
    self:InvalidateContext()
    self:Print(cleared.." posições limpas. Use Aplicar sugestões para preencher; Restaurar barras desfaz. Automático pausado.")
    self:RefreshUI()
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

-- Coalesce native changes into one availability update of the cached list.
function MM:QueueSpellRefresh()
    self.knownDirty=true
    if self.spellRefreshQueued then return end
    self.spellRefreshQueued=true
    C_Timer.After(0.25,function()
        self.spellRefreshQueued=nil
        self:Scan()
        self:QueueAuto()
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
    local previous=self.db.undo[self.current.key]
    local undo=previous and previous.clearPending and previous or (automatic and previous)
    if not undo or not undo.automatic and not undo.clearPending then
        undo={key=self.current.key,changes={},created=time(),automatic=automatic}
    end
    undo.clearPending=nil
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
    if self:IsLevelingMode() and self.levelingUnplaced and #self.levelingUnplaced>0 then
        self:Print("Aprendidas ainda sem espaço nas barras: "..table.concat(self.levelingUnplaced,", "))
    end
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
events:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE")
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
        for _,key in ipairs({"characters","references","settings","overrides","undo","levelingAuto","levelingContext"}) do
            MM.db[key] = MM.db[key] or {}
        end
        MM.db.collection = MM.db.collection or {characters={}}
        MM.db.collection.characters = MM.db.collection.characters or {}
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
            if event == "UPDATE_BINDINGS" then MM:QueueAuto() end
            if event == "ACTIONBAR_PAGE_CHANGED" and MM.RefreshUI then MM:RefreshUI() end
        elseif event == "ACTIONBAR_SLOT_CHANGED" then
            MM:InvalidateContext()
            if not MM.applying then
                if MM:AutoAuthorized() then MM:QueueAuto() end
                if MM.RefreshUI then MM:RefreshUI() end
            end
        elseif event == "CURSOR_CHANGED" or event == "UPDATE_VEHICLE_ACTIONBAR" or event == "UPDATE_OVERRIDE_ACTIONBAR" then
            if MM.autoPending and not GetCursorInfo() then MM:QueueAuto() end
        elseif event == "SPELL_DATA_LOAD_RESULT" then
            MM:InvalidateContext()
        elseif event == "PLAYER_REGEN_ENABLED" then
            if MM.bindingsPending then MM.bindingsPending=nil; MM:ReadBindings() end
            if MM.scanPending then MM:Scan() end
            if MM.autoPending then MM:QueueAuto() end
        elseif event == "PLAYER_LEVEL_UP" or event == "LEARNED_SPELL_IN_SKILL_LINE" or event == "SPELLS_CHANGED" then
            -- An ability absent from the cached book means the book itself changed,
            -- e.g. a new profession; ordinary level unlocks only change availability.
            if event=="LEARNED_SPELL_IN_SKILL_LINE" and not MM:FindProfileSpell(MM.current.spells,arg) then
                MM.spellbookDirty=true
            end
            MM:QueueSpellRefresh()
        elseif event == "TRAIT_CONFIG_UPDATED" or event == "NEW_MOUNT_ADDED"
            or (event == "PLAYER_SPECIALIZATION_CHANGED" and arg == "player") then
            MM.spellbookDirty=true
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
    elseif message == "clear" or message == "limpar" then MM:ClearBars()
    elseif message == "collect" then MM:ToggleCollection()
    elseif message == "collect on" or message == "collect start" then MM:SetCollectionEnabled(true)
    elseif message == "collect off" or message == "collect stop" then MM:SetCollectionEnabled(false)
    elseif message == "collect status" then MM:PrintCollectionStatus()
    elseif message == "collect clear" then MM:ClearCollection()
    elseif message == "export" or message == "collect export" then MM:ShowCollectionExport()
    else MM:ToggleUI() end
end
