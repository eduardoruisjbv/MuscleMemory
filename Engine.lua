local _, MM = ...
local protectionRoles={defensive=true,immunity=true,mitigation=true}
local roleFamilies={builder="rotation",spender="rotation",core="rotation",filler="rotation",
    proc_builder="rotation",proc_spender="rotation",aoe_builder="area",aoe_spender="area",
    aoe_proc_spender="area",aoe="area"}
MM.AUTO_SCORE=72

local function defenseKey(defense)
    return table.concat({defense.school or "?",defense.mechanism or "?",defense.recipient or "?",
        defense.cadence or "?",defense.coverage or "?"},":")
end

-- Suggest by habit of use. Protection scope, healing targets and control types
-- remain constraints; rotation context ranks candidates instead of blocking them.
function MM:Score(source,target,sourceSpec,targetSpec,sourceClass,targetClass)
    if source.action or target.action then
        if source.action and target.action and source.id==target.id then
            return 100,"Exact copy of the utility action",false,{identity=true,rank=4}
        end
        return 0,"Mounts and utilities require the same action as the source"
    end
    local identity,identityRank
    if self.SameAbility then identity,identityRank=self:SameAbility(source,target,sourceClass,targetClass) end
    if identity and (target.learned or not self.IsActivePurpose or self:IsActivePurpose(source) and self:IsActivePurpose(target)) then
        return 100,identity,false,{identity=true,rank=identityRank}
    end
    if self.IsActivePurpose and (not self:IsActivePurpose(source) or not self:IsActivePurpose(target)) then
        return 0,"Passive or removed ability; not an equivalent active button"
    end
    local sourceID,targetID=source.baseID or source.id,target.baseID or target.id
    -- Identical learned racials and common abilities do not need a class-specific
    -- guess. Preserve them first, including references captured by older versions.
    if source.id==target.id or sourceID==targetID then return 100,"Same ability available on the destination",false,{identity=true,rank=3} end
    if source.role == "unknown" or target.role == "unknown" then return 0,"Purpose not yet classified" end
    if not source.curated or not target.curated then return 35,"Estimated purpose; choose manually" end
    local usageOK,usageReason,usageApproximate,usagePenalty,usageContext=true,"",false,0,{}
    if self.CompareUsage then usageOK,usageReason,usageApproximate,usagePenalty,usageContext=self:CompareUsage(source,target) end
    if not usageOK then return 60,usageReason end
    usageContext=usageContext or {}
    local emergency=usageContext.emergency
    local a,b=source.traits or {},target.traits or {}
    local approach=source.role=="pull" and target.role=="mobility" and b.movement=="gap_closer"
        or target.role=="pull" and source.role=="mobility" and a.movement=="gap_closer"
    local sameRole=source.role==target.role
    local sharedPurpose=source.purpose and target.purpose and source.purpose.primary==target.purpose.primary
        and source.purpose.primary~="rotation"
    local family=roleFamilies[source.role]
    if not sameRole and not emergency and not usageContext.damageWindow and not sharedPurpose and not approach and (not family or family~=roleFamilies[target.role]) then return 0,"Different purposes" end
    local approximate=not sameRole or usageApproximate
    local purpose=source.purpose and source.purpose.primary
    if not emergency and protectionRoles[source.role] and (not purpose or purpose=="damage_reduction" or purpose=="immunity") then
        if not source.defenses or not target.defenses then return 35,"Protection type not yet classified" end
        local available={}
        for _,defense in ipairs(target.defenses) do available[defenseKey(defense)]=true end
        for _,defense in ipairs(source.defenses) do
            if not available[defenseKey(defense)] then
                local compatible=false
                for _,other in ipairs(target.defenses) do
                    if source.role=="defensive" and defense.school==other.school
                        and defense.recipient==other.recipient and defense.cadence==other.cadence
                        and defense.coverage==other.coverage then compatible=true end
                end
                if not compatible then return 60,"Different protections: "..self:RoleLabel(source).." > "..self:RoleLabel(target) end
                approximate=true
            end
        end
    end
    for _,field in ipairs({"recipient","delivery","control","movement"}) do
        if a[field] ~= b[field] and (a[field] or b[field]) then
            if emergency then
                approximate=true
            elseif field=="control" and usageContext.collective then
                approximate=true
            elseif field=="control" and source.purpose and target.purpose
                and source.purpose.primary~="control" and target.purpose.primary~="control" then
                approximate=true
            elseif field=="movement" and (approach or source.role=="mobility" and target.role=="mobility") then
                approximate=true
            elseif field=="control" and source.purpose and target.purpose
                and source.purpose.primary=="interrupt" and target.purpose.primary=="interrupt" then
                -- An extra silence does not change the primary habit of stopping
                -- a cast, but the alternative cannot promise that secondary effect.
                approximate=true
            else return 60,"Different behavior (target, healing, or control)" end
        end
    end
    if source.role=="cc_break" and a.breaks~=b.breaks then approximate=true end
    if a.no_attack ~= b.no_attack then
        if not emergency then return 60,"The alternative changes whether you can attack" end
        approximate=true
        usageReason=usageReason.."; whether actions or attacks are possible during the effect differs"
    end
    local pair=self.preferredPairs and self.preferredPairs[(sourceSpec or 0)..":"..(targetSpec or 0)]
    local choices=pair and pair[sourceID] or self.emergencyPairs and self.emergencyPairs[sourceID]
    if choices then
        for index,id in ipairs(choices) do
            if id==targetID then
                local x,y=source.rotation,target.rotation
                local differs=x and y and (x.rhythm~=y.rhythm or x.flow~=y.flow)
                local reason="Suggested by purpose and usage pattern; resources and mechanics may differ"
                if usageReason~="" then reason=reason.."; "..usageReason end
                return math.max(self.AUTO_SCORE,math.min(98,98-index-usagePenalty+(usageContext.bonus or 0))),reason,approximate or differs or false
            end
        end
    end
    local sourceRotation,targetRotation=source.rotation,target.rotation
    local score=approximate and self.AUTO_SCORE or 80
    if sourceRotation and targetRotation then
        if sourceRotation.rhythm==targetRotation.rhythm then score=score+6
        elseif family then approximate=true end
        if sourceRotation.flow==targetRotation.flow then score=score+2
        elseif family then approximate=true end
    end
    if source.castTime and target.castTime then
        score=score+math.max(0,6-math.abs(source.castTime-target.castTime)/500)
    end
    if source.costRatio and target.costRatio then
        score=score+math.max(0,4-math.abs(source.costRatio-target.costRatio)*10)
    end
    local reason=approximate and "Alternative by purpose and usage pattern; see tooltip for differences" or self:RoleLabel(source)
    if usageReason~="" then reason=reason.."; "..usageReason end
    return math.min(98,math.max(self.AUTO_SCORE,math.min(score,94)-usagePenalty+(usageContext.bonus or 0))),reason,approximate
end

function MM:Suggest(reference,targets,overrides,targetSpec,targetClass)
    local sources,edges,result,used,candidates,rejected={},{},{},{},{},{}
    local identities={}
    for slot=1,self.MAX_SLOT do
        local action=reference.actions[slot]
        if self:IsManagedSlot(slot) and action then
            local key=self:ActionKey(action)
            if key then sources[key]=reference.spells[key] or {id=key,role="unknown"} end
        end
    end
    for sourceID,choice in pairs(overrides or {}) do
        if sources[sourceID] then
            if choice == false then
                result[sourceID]={blocked=true,manual=true,status="excluded",reason="You excluded this mapping"}
            else
                local target=targets[choice]
                local score,reason=0,"Ability unavailable"
                if target then score,reason=self:Score(sources[sourceID],target,reference.spec,targetSpec,reference.class,targetClass) end
                result[sourceID]={id=choice,score=score,manual=true,
                    status=target and "matched" or "unavailable",reason="Your choice",
                    warning=(not target or score<self.AUTO_SCORE) and reason or nil}
                used[choice]=sourceID
            end
        end
    end
    for sourceID,source in pairs(sources) do
        if not result[sourceID] then
            for targetID,target in pairs(targets) do
                local score,reason,approximate,detail=self:Score(source,target,reference.spec,targetSpec,reference.class,targetClass)
                if detail and detail.identity then
                    local previous=identities[sourceID]
                    if not previous or detail.rank>previous.rank or detail.rank==previous.rank and targetID<previous.id then
                        identities[sourceID]={source=sourceID,id=targetID,score=100,rank=detail.rank,
                            reason=reason,status="matched",copied=true}
                    end
                elseif score>=self.AUTO_SCORE then
                    candidates[sourceID]=true
                    edges[#edges+1]={source=sourceID,id=targetID,score=score,reason=reason,status="matched",approximate=approximate}
                elseif score>0 and source.role==target.role then
                    local previous=rejected[sourceID]
                    if not previous or score>previous.score or score==previous.score and targetID<previous.id then
                        rejected[sourceID]={score=score,id=targetID,reason=reason}
                    end
                end
            end
        end
    end
    -- Repeated IDs/overrides of the same ability may copy to the same learned
    -- button. Reserving it must never turn an identity copy into a pending row.
    for sourceID,identity in pairs(identities) do result[sourceID]=identity; used[identity.id]=sourceID end
    table.sort(edges,function(a,b)
        if a.score~=b.score then return a.score>b.score end
        if a.source~=b.source then return a.source<b.source end
        return a.id<b.id
    end)
    for _,edge in ipairs(edges) do
        if not result[edge.source] and not used[edge.id] then result[edge.source]=edge; used[edge.id]=edge.source end
    end
    for sourceID,source in pairs(sources) do
        if not result[sourceID] then
            local unknown=not source.curated or source.role == "unknown" or source.role == "damage" or source.role == "support"
                or (protectionRoles[source.role] and not source.defenses)
            if source.action then
                result[sourceID]={status="unavailable",reason=source.action.kind=="macro"
                    and (source.action.body and "A macro with identical content must exist on the destination; the source index is not reused."
                        or "This older capture did not save the macro contents. Capture the source action bars again.")
                    or "The same utility action is unavailable on this character; the current slot will be preserved."}
            elseif unknown then
                result[sourceID]={status="not_configured",reason="Classify or choose an ability manually"}
            elseif candidates[sourceID] then
                result[sourceID]={status="not_configured",reason="Equivalent already reserved; choose whether to reuse it"}
            else
                local refusal=rejected[sourceID]
                result[sourceID]={status="no_direct_equivalent",reason=(refusal and refusal.reason or "No compatible alternative available").."; the current action will be preserved"}
            end
        end
    end
    return result
end

function MM:BuildPlan(reference,matches,known,actions)
    local plan,skipped={},0
    for slot=1,self.MAX_SLOT do
        local source=reference.actions[slot]
        if self:IsManagedSlot(slot) and source and self:ActionKey(source) then
            local sourceID=self:ActionKey(source)
            local match,current=matches[sourceID],actions[slot]
            if match and match.id and known[match.id] then
                local after=known[match.id].action or {kind="spell",id=match.id}
                if current and current.kind~="spell" and current.kind~="summonmount" and not self:ActionMatches(current,after) then skipped=skipped+1
                elseif not self:ActionMatches(current,after) then
                    plan[#plan+1]={slot=slot,id=match.id,after=self:Copy(after),before=current or false,sourceID=sourceID}
                end
            else skipped=skipped+1 end
        end
    end
    return plan,skipped
end
