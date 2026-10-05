local _, MM = ...
MM.AUTO_CONSENT_VERSION=1

-- Layout defaults: these rank keys on a bar, not the next cast in combat.
-- The user can change the order and pin skills. Procs are never used to move bars.
local rotationRoles={core=true,builder=true,spender=true,filler=true,damage=true,dot=true,execute=true,
    proc_builder=true,proc_spender=true,aoe_proc_spender=true,aoe_builder=true,aoe_spender=true,
    aoe=true,burst=true,mitigation=true,heal=true,empowered=true}
local rolePriority={core=20,builder=30,proc_builder=35,spender=40,proc_spender=45,empowered=48,
    heal=50,mitigation=55,dot=60,execute=65,aoe_builder=70,aoe_spender=75,aoe_proc_spender=78,
    aoe=80,burst=90,filler=95,damage=100}
local specOrder={
    [71]={12294,7384,5308,772,845,1464,167105,107574},
    [72]={184367,23881,85288,5308,1680,1719,107574,1464},
    [73]={23922,6343,2565,190456,6572},
    [70]={85256,383328,184575,20271,53385,24275,31884},
    [253]={34026,217200,193455,257620,19574},
    [259]={32645,1329,1943,703,51723,121411,360194},
    [258]={335467,8092,34914,589,32379,15407},
    [257]={2050,2061,2060,139,585},
    [251]={49020,49143,49184,207230,194913,51271,279302},
    [250]={49998,195182,50842,206930,43265},
    [262]={51505,8042,188389,188196,61882,188443,114050},
    [63]={11366,108853,133,2120,190319},
    [64]={116,30455,44614,84714,12472},
    [267]={116858,17962,29722,348,5740,1122},
    [269]={107428,113656,100784,100780,101546},
    [103]={1079,5221,1822,22568,106785,5217},
    [577]={162794,198013,188499,232893,162243,191427},
    [1467]={357208,359073,356995,361469,357211,375087},
}

function MM:IsLevelingMode()
    return self:Settings().autoMode=="leveling"
end

function MM:LevelingPriority(spell)
    local settings=self:Settings()
    local id=spell.baseID or spell.id
    local custom=settings.levelingPriority or {}
    if custom[spell.id] or custom[id] then return custom[spell.id] or custom[id] end
    for index,knownID in ipairs(specOrder[self.current.spec] or {}) do
        if spell.id==knownID or id==knownID then return 1000+index end
    end
    local rhythm=spell.rotation and spell.rotation.rhythm
    return 2000+(rhythm=="core" and 0 or 100)+(rolePriority[spell.role] or 500)
end

function MM:IsCombatLayoutSpell(spell)
    return rotationRoles[spell.role]==true
end

function MM:LevelingSpells()
    local combat,utility={},{}
    local settings=self:Settings()
    local excluded=settings.levelingExcluded or {}
    local candidates={}
    for _,spell in pairs(self.current.spells) do
        local identity=spell.baseID or spell.id
        if not spell.action and not excluded[spell.id] and not excluded[identity]
            and spell.role~="mount" and not spell.isAssistant then
            local previous=candidates[identity]
            local override=C_SpellBook.FindSpellOverrideByID(identity)
            if not previous or spell.id==override or previous.id~=override and spell.id>previous.id then
                candidates[identity]=spell
            end
        end
    end
    for _,spell in pairs(candidates) do
            local list=rotationRoles[spell.role] and combat or utility
            list[#list+1]=spell
    end
    table.sort(combat,function(a,b)
        local x,y=self:LevelingPriority(a),self:LevelingPriority(b)
        return x==y and a.id<b.id or x<y
    end)
    table.sort(utility,function(a,b) return a.id<b.id end)
    return combat,utility
end

function MM:LevelingLayout(actions)
    local settings=self:Settings()
    local combat,utility=self:LevelingSpells()
    local desired,occupied,placed={},{},{}
    local protected=0
    local pins=settings.levelingPins or {}
    local excluded=settings.levelingExcluded or {}
    local previous=settings.levelingOwned or {}
    -- Exact travel/actions, unknown existing spells and utility positions are reserved.
    for slot=1,self.MAX_SLOT do
        if self:IsManagedSlot(slot) then
            local action=actions[slot]
            if action then
                local spell=action.kind=="spell" and self:FindProfileSpell(self.current.spells,action.id)
                if action.kind~="spell" or not spell and not previous[slot]
                    or spell and (not rotationRoles[spell.role] or excluded[spell.id] or excluded[spell.baseID]) then
                    desired[slot]=self:Copy(action); occupied[slot]=true
                    if spell then placed[spell.baseID or spell.id]=true end
                end
            end
        end
    end
    -- Travel keys follow the selected origin, even while combat keys evolve.
    local source=self.db.references[settings.sourceKey] or self.db.characters[settings.sourceKey]
    local pinnedSlots={}
    for _,slot in pairs(pins) do pinnedSlots[slot]=true end
    for slot,action in pairs(source and source.actions or {}) do
        if self:IsManagedSlot(slot) and not pinnedSlots[slot] then
            local entry=self:ActionEntry(action)
            if entry and entry.role=="mount" and (not occupied[slot] or desired[slot].kind=="summonmount" or desired[slot].mountID~=nil) then
                local available=self:ResolveUtilityAction(entry.action)
                if available then desired[slot]=available; occupied[slot]=true end
            end
        end
    end
    -- A pinned ability reserves its current/explicit position before sorting the rest.
    for _,list in ipairs({combat,utility}) do
        for _,spell in ipairs(list) do
            local slot=pins[spell.id] or pins[spell.baseID]
            if slot and self:IsManagedSlot(slot) and not occupied[slot] then
                desired[slot]={kind="spell",id=spell.id}; occupied[slot]=true
                placed[spell.baseID or spell.id]=true
            elseif slot and not placed[spell.baseID or spell.id] then
                -- Never silently move a pinned spell when another protected action occupies its key.
                placed[spell.baseID or spell.id]=true; protected=protected+1
            end
        end
    end
    local available={}
    -- Default main page first, then real bindings and auxiliary bars. Paging the
    -- main bar must not change the chosen layout on the next level-up.
    local bindings=self:ReadBindings()
    for pass=1,4 do
        for slot=1,self.MAX_SLOT do
            if self:IsManagedSlot(slot) and not occupied[slot] then
                local primary=slot<=12
                local bound=bindings[slot] and #bindings[slot]>0
                local auxiliary=slot>=25
                if (pass==1 and primary) or (pass==2 and not primary and bound)
                    or (pass==3 and auxiliary and not bound)
                    or (pass==4 and not primary and not auxiliary and not bound) then available[#available+1]=slot end
            end
        end
    end
    local cursor,skipped=1,protected
    for _,list in ipairs({combat,utility}) do
        for _,spell in ipairs(list) do
            local identity=spell.baseID or spell.id
            if not placed[identity] then
                local slot=available[cursor]
                if slot then
                    desired[slot]={kind="spell",id=spell.id}; placed[identity]=true; cursor=cursor+1
                else skipped=skipped+1 end
            end
        end
    end
    return desired,skipped
end

function MM:LevelingReference()
    if InCombatLockdown() then
        if self.levelingReferenceSnapshot and self.levelingReferenceSnapshot.key==self.current.key then
            return self.levelingReferenceSnapshot
        end
        local reference=self:Copy(self.current)
        reference.actions,reference.bindings={},self.bindingSnapshot or {}
        reference.leveling=true
        return reference
    end
    local reference=self:Copy(self.current)
    reference.actions=self:LevelingLayout(self:ReadActions())
    reference.bindings=self:Copy(self:ReadBindings())
    reference.name=self.current.name.." · prioridade de barras"
    reference.leveling=true
    self:EnrichActions(reference)
    self.levelingReferenceSnapshot=reference
    return reference
end

function MM:BuildCurrentPlan(reference,matches,known,actions)
    if not self:IsLevelingMode() then return self:BuildPlan(reference,matches,known,actions) end
    local desired,skipped=self:LevelingLayout(actions)
    local plan={}
    for slot=1,self.MAX_SLOT do
        if self:IsManagedSlot(slot) then
            local action=desired[slot]
            if action and not self:ActionMatches(actions[slot],action) then
                local id=self:ActionKey(action)
                plan[#plan+1]={slot=slot,id=id,after=action,before=actions[slot] or false,sourceID=id}
            elseif not action and actions[slot] and actions[slot].kind=="spell" then
                local spell=self:FindProfileSpell(self.current.spells,actions[slot].id)
                if (self:Settings().levelingOwned or {})[slot] or spell and rotationRoles[spell.role] then
                    plan[#plan+1]={slot=slot,after=false,before=actions[slot],clearing=true}
                end
            end
        end
    end
    return plan,skipped
end

function MM:RecordLevelingLayout()
    if not self:IsLevelingMode() then return end
    local owned={}
    local combat,utility=self:LevelingSpells()
    local eligible={}
    for _,list in ipairs({combat,utility}) do for _,spell in ipairs(list) do eligible[spell.id]=true end end
    for slot,action in pairs(self:ReadActions()) do
        if action.kind=="spell" and eligible[action.id] then owned[slot]=action.id end
    end
    self:Settings().levelingOwned=owned
    self:InvalidateContext()
end

function MM:MoveLevelingPriority(id,offset)
    local list=self:LevelingSpells()
    local index
    for i,spell in ipairs(list) do if spell.id==id then index=i end end
    if not index then return end
    local other=math.max(1,math.min(#list,index+offset))
    list[index],list[other]=list[other],list[index]
    local priorities=self:Settings().levelingPriority or {}
    self:Settings().levelingPriority=priorities
    for i,spell in ipairs(list) do priorities[spell.baseID or spell.id]=i end
    self:InvalidateContext(); self:RefreshUI()
    if self:Settings().auto then self:QueueAuto() end
end

function MM:AutoAuthorized()
    local settings=self:Settings()
    local leveling=self.db.levelingAuto and self.db.levelingAuto[(self:Identity())]
    return settings.auto and (not self:IsLevelingMode() or leveling==self.AUTO_CONSENT_VERSION)
        and settings.autoConsent==self.AUTO_CONSENT_VERSION
        and settings.autoConsentMode==(settings.autoMode or "equivalence")
end

function MM:DisableAutomatic()
    local guid=self:Identity()
    self.db.levelingAuto=self.db.levelingAuto or {}
    self.db.levelingAuto[guid]=nil
    for key,settings in pairs(self.db.settings) do
        if key:sub(1,#guid+1)==guid..":" and settings.autoMode=="leveling" then settings.auto=false end
    end
    self:Settings().auto=false
end
