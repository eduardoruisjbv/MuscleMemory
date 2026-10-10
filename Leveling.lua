local _, MM = ...
MM.AUTO_CONSENT_VERSION=2

function MM:IsLevelingMode()
    return self:Settings().autoMode=="leveling"
end

local function caster(class,spec)
    return class=="MAGE" or class=="WARLOCK" or class=="PRIEST" or class=="EVOKER"
        or class=="SHAMAN" and (spec==262 or spec==264)
        or class=="DRUID" and (spec==102 or spec==105)
end

-- Resource names and cast style differ across archetypes; the button's intent
-- remains the anchor. Never turn healing/defence/control into generic damage.
function MM:ProgressiveDamageScore(source,target,sourceSpec,targetSpec,sourceClass,targetClass)
    if not self.db or not self.current then return end
    local translator=self:Settings().translator
        and caster(sourceClass,sourceSpec)~=caster(targetClass,targetSpec)
    if not self:IsLevelingMode() and not translator then return end
    if source.action or target.action or not source.curated or not target.curated then return end
    local a,b=self:GetFunctionProfile(source),self:GetFunctionProfile(target)
    if a.damage~="primary" or b.damage~="primary" or a.area~=b.area then return end
    local special={burst=true,execute=true,dot=true,empowered=true}
    if special[source.role] or special[target.role] then return end
    local x,y=self:UsageCooldown(source),self:UsageCooldown(target)
    if x and y and (x>20 or y>20) then return end
    local ap,bp=source.purpose or {},target.purpose or {}
    if bp.condition and bp.condition~=ap.condition then return end
    local score,reason=82,"Dano disponível; substituto temporário sem todas as funções da origem"
    local tags={"generate_resource","spend_resource","prepare_proc","consume_proc"}
    local required,shared=0,0
    for _,tag in ipairs(tags) do
        if a.secondary[tag] then
            required=required+1
            if b.secondary[tag] then shared=shared+1 end
        end
    end
    if required>0 and shared==required then
        score,reason=96,"Mesma função de dano e recurso/proc, mesmo com outra mecânica de classe"
    elseif shared>0 then score,reason=90,"Dano e parte da função de recurso/proc da origem"
    elseif required==0 then score,reason=88,"Mesma função de dano; mecânica de recurso/proc pode diferir" end
    local ar,br=source.rotation or {},target.rotation or {}
    if ar.rhythm and ar.rhythm==br.rhythm then score=score+1 end
    if source.role==target.role then score=score+1 end
    if translator then reason="Translator melee ↔ caster: "..reason end
    if required>shared then reason=reason.."; geração/gasto/proc ausente não é considerado equivalente" end
    return score,reason,true
end

local function functionFamily(mm,spell)
    local p=spell.purpose or {}
    if p.primary=="heal" or p.primary=="self_heal" or spell.role=="heal" then return "heal" end
    if p.primary=="movement" or spell.role=="mobility" then return "movement" end
    local profile=mm:GetFunctionProfile(spell)
    if profile.damage=="primary" or spell.role=="damage" then return profile.area and "area_damage" or "damage" end
    return p.primary or spell.role or "utility"
end

function MM:BuildCurrentPlan(reference,matches,known,actions)
    local plan,skipped=self:BuildPlan(reference,matches,known,actions)
    local leveling=self:IsLevelingMode()
    local automatic=self:AutoAuthorized()
    if not leveling and not automatic then return plan,skipped end
    local settings=self:Settings()
    local _,_,overrides=self:Context()
    local layout=self:Copy(actions)
    local plannedSlots,represented,canonical={},{},{}
    for _,change in ipairs(plan) do
        layout[change.slot]=change.after or {kind="spell",id=change.id}
        plannedSlots[change.slot]=true
    end
    local function identity(spell) return spell.baseID or spell.id end
    local function eligible(spell)
        return spell and spell.learned and not spell.isPassive and not spell.offSpec
            and not spell.action and spell.mountID==nil
            and not spell.isAssistant and self:IsActivePurpose(spell)
    end
    -- The reference may deliberately repeat a skill. Keep every such position,
    -- including already-correct slots which BuildPlan does not emit.
    for slot=1,self.MAX_SLOT do
        local source=reference.actions[slot]
        local sourceID=source and self:ActionKey(source)
        local match=sourceID and matches[sourceID]
        local spell=match and match.id and known[match.id]
        if self:IsManagedSlot(slot) and eligible(spell)
            and self:ActionMatches(layout[slot],{kind="spell",id=spell.id}) then
            local id=identity(spell)
            canonical[id]=canonical[id] or {}
            canonical[id][slot]=true
        end
    end
    -- Blizzard may have filled an arbitrary empty button after learning a skill.
    -- In automatic leveling, those copies must not decide its permanent position.
    if automatic and leveling then
        for slot,action in pairs(layout) do
            local spell=action.kind=="spell" and self:FindProfileSpell(known,action.id)
            local id=spell and identity(spell)
            if eligible(spell) and not plannedSlots[slot] and not (canonical[id] and canonical[id][slot]) then
                layout[slot]=nil
            end
        end
    end
    for _,action in pairs(layout) do
        if action.kind=="spell" then
            local spell=self:FindProfileSpell(known,action.id)
            if spell then represented[identity(spell)]=true end
        end
    end
    settings.levelingExtraSlots=settings.levelingExtraSlots or {}
    local key=(settings.sourceKey or "none")..":"..self.current.spec
    settings.levelingExtraSlots[key]=settings.levelingExtraSlots[key] or {}
    local saved=settings.levelingExtraSlots[key]
    local reserved={}
    for _,spell in pairs(known) do
        local id=identity(spell)
        local slot=saved[id]
        if eligible(spell) and not represented[id] and slot and self:IsManagedSlot(slot)
            and not reference.actions[slot] and not layout[slot] and not plannedSlots[slot] then
            reserved[slot]=id
        end
    end
    local remaining={}
    for _,spell in pairs(known) do
        if leveling and eligible(spell) and not represented[identity(spell)] then
            remaining[#remaining+1]=spell
        end
    end
    table.sort(remaining,function(a,b) return a.id<b.id end)
    local missing={}
    for _,spell in ipairs(remaining) do
        local id=identity(spell)
        if not represented[id] then
            local family=functionFamily(self,spell)
            local bestSlot,bestScore,nearSlot
            for slot=1,self.MAX_SLOT do
                local source=reference.actions[slot]
                if self:IsManagedSlot(slot) and source then
                    local sourceID=self:ActionKey(source)
                    local sourceSpell=sourceID and reference.spells[sourceID]
                    local match=sourceID and matches[sourceID]
                    if sourceSpell and not sourceSpell.action and functionFamily(self,sourceSpell)==family then
                        nearSlot=nearSlot or slot
                        -- Approximate placement is separate from an equivalence:
                        -- never replace an established match or a manual choice.
                        if not layout[slot] and not plannedSlots[slot] and overrides[sourceID]==nil
                            and not (match and match.id) then
                            local score=self:Score(sourceSpell,spell,reference.spec,self.current.spec,reference.class,self.current.class)
                            if not bestScore or score>bestScore then bestSlot,bestScore=slot,score end
                        end
                    end
                end
            end
            local function auxiliaryAvailable(slot)
                return slot and self:IsManagedSlot(slot) and not reference.actions[slot]
                    and not layout[slot] and not plannedSlots[slot]
                    and (not reserved[slot] or reserved[slot]==id)
            end
            local slot=bestSlot
            if not slot and auxiliaryAvailable(saved[id]) then slot=saved[id] end
            -- If the main has no vacant slot for this function, reserve a stable
            -- supplementary position nearest the main's related function group.
            if not slot then
                local anchor=nearSlot or 49
                for distance=0,self.MAX_SLOT do
                    if auxiliaryAvailable(anchor+distance) then slot=anchor+distance; break end
                    if auxiliaryAvailable(anchor-distance) then slot=anchor-distance; break end
                end
            end
            if slot then
                local after={kind="spell",id=spell.id}
                if not self:ActionMatches(actions[slot],after) then
                    plan[#plan+1]={slot=slot,id=spell.id,after=after,before=actions[slot] or false,supplemental=true,
                        placementReason=bestSlot and "Posição por função geral; não é equivalência direta"
                            or "Posição complementar estável, próxima da função do main"}
                    plannedSlots[slot]=true
                end
                layout[slot],represented[id]=after,true
                canonical[id]={[slot]=true}
                saved[id]=slot
            else missing[#missing+1]=spell.name or tostring(spell.id) end
        end
    end
    self.levelingUnplaced=missing
    if automatic then
        -- Place the destination first; cleanup comes last and shares the undo
        -- journal. A failed placement stops Apply before removing any copies.
        for slot=1,self.MAX_SLOT do
            local action=actions[slot]
            local spell=action and action.kind=="spell" and self:FindProfileSpell(known,action.id)
            local id=spell and identity(spell)
            if self:IsManagedSlot(slot) and canonical[id] and not canonical[id][slot] and not plannedSlots[slot] then
                plan[#plan+1]={slot=slot,before=self:Copy(action),after=false,clearing=true,
                    placementReason="Cópia extra; habilidade mantida na posição da referência/complementar"}
            end
        end
    end
    return plan,skipped+#missing
end

function MM:RecordLevelingLayout()
    self:InvalidateContext()
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
