local _, MM = ...

local function copy(value)
    if type(value) ~= "table" then return value end
    local result={}
    for key,item in pairs(value) do result[key]=copy(item) end
    return result
end

-- Reviewed intent is separate from rotation flow and from secondary effects.
-- Common racials enter the catalogue, but only an observed spellbook supplies them.
for id,purpose in pairs(MM.purposeCatalog or {}) do
    if not MM.catalog[id] then
        MM.catalog[id]={class=purpose.class,specs=purpose.specs,role=purpose.role or "unknown",curated=true}
    end
    if purpose.specs then MM.catalog[id].specs=copy(purpose.specs) end
    if not purpose.class then MM.catalog[id].racial=true end
end

function MM:ApplyPurposeProfile(entry,class,spec)
    local profile=self.purposeCatalog and self.purposeCatalog[entry.id]
    if not profile or profile.class and profile.class~=class then return entry end
    local purpose=copy(profile)
    purpose.variants=nil
    local variant=profile.variants and profile.variants[spec]
    for key,value in pairs(variant or {}) do purpose[key]=copy(value) end
    entry.purpose=purpose
    if purpose.defenses then entry.defenses=copy(purpose.defenses) end
    if purpose.traits then
        entry.traits=entry.traits or {}
        for key,value in pairs(purpose.traits) do entry.traits[key]=copy(value) end
    end
    if purpose.role then entry.role=purpose.role end
    if purpose.reviewed==false then entry.curated=false end
    if purpose.primary=="self_heal" or purpose.primary=="heal" then
        entry.traits=entry.traits or {}
        entry.traits.recipient=purpose.scope or (purpose.primary=="self_heal" and "self" or "friendly")
        entry.traits.delivery=entry.traits.delivery or purpose.delivery or "direct"
    elseif entry.traits then
        -- A reviewed shield or defensive cooldown must not inherit healing
        -- delivery from a historical broad 'heal' classification.
        entry.traits.recipient=nil
        entry.traits.delivery=nil
    end
    entry.racial=not profile.class or profile.racial
    entry.functions=nil
    return entry
end

local damageRoles={builder=true,spender=true,core=true,filler=true,proc_builder=true,proc_spender=true,
    aoe_builder=true,aoe_spender=true,aoe_proc_spender=true,aoe=true,execute=true,dot=true,empowered=true}
local areaRoles={aoe_builder=true,aoe_spender=true,aoe_proc_spender=true,aoe=true}
local effectAliases={resource_generator="generate_resource",generation="generate_resource",
    resource_spender="spend_resource",spend="spend_resource",proc_builder="prepare_proc",
    proc_generation="prepare_proc",proc_consumer="consume_proc",proc_spender="consume_proc",
    proc_spend="consume_proc",aoe_damage="area_damage",damage_area="area_damage",
    immune_control="control_immunity",remove_harmful_effects="debuff_removal"}
local effectLabels={generate_resource="resource generation",spend_resource="resource spending",
    prepare_proc="proc setup",consume_proc="proc consumption",self_heal="self-healing",
    area_damage="area damage",control_immunity="control immunity",debuff_removal="effect removal",
    slow="slow",stun="stun",disorient="disorient",fear="fear",root="root",
    window_synergy="offensive-window interaction",reflect="reflection",absorb="absorb"}
local controlLabels={stun="stun",disorient="disorient",incapacitate="incapacitate",
    fear="fear",root="root",silence="silence",knockback="knockback",knockup="knock up"}

function MM:GetFunctionProfile(spell)
    if spell.functions then return spell.functions end
    local p,t=spell.purpose or {},spell.traits or {}
    local tags={}
    for _,effect in ipairs(p.also or {}) do
        local normalized=effectAliases[effect] or effect
        if effectLabels[normalized] then tags[normalized]=true end
    end
    if spell.rotation and spell.rotation.flow then
        local flow=effectAliases[spell.rotation.flow]
        if flow then tags[flow]=true end
    end
    local hasDamage=false
    for _,effect in ipairs(p.also or {}) do
        if effect=="damage" or effect=="direct_damage" or effect=="area_damage" or effect=="aoe_damage" then hasDamage=true end
    end
    local damage=p.damage
    if not damage then
        if damageRoles[spell.role] then damage="primary"
        elseif hasDamage then damage=p.primary=="offensive_window" and "primary" or "secondary"
        elseif p.primary=="control" then damage="none" end
    end
    local control=p.control or {}
    local kind=control.kind or t.control
    if not kind then
        for _,candidate in ipairs({"stun","fear","disorient","incapacitate","root","silence","knockback","knockup"}) do
            for _,effect in ipairs(p.also or {}) do if effect==candidate then kind=candidate end end
        end
    end
    local area=p.area or areaRoles[spell.role] or tags.area_damage
    local controlScope=control.scope
    if not controlScope and (p.primary=="control" or p.primary=="interrupt") then
        for _,effect in ipairs(p.also or {}) do if effect=="area" or effect=="cone" then controlScope="area" end end
        controlScope=controlScope or "single"
    end
    if p.primary=="control" and kind then tags[kind]=nil end
    if p.primary~="control" and kind and effectLabels[kind] then tags[kind]=true end
    if damage=="primary" then tags.area_damage=nil end
    local functions={primary=p.primary,damage=damage,area=not not area,control=kind,controlScope=controlScope,
        breakOnDamage=control.breakOnDamage,secondary=tags,
        emergency=p.intent=="personal_emergency" and p.emergencySelf==true}
    spell.functions=functions
    return functions
end

local function normalizedName(name)
    if type(name)~="string" or name=="" or name:match("^Ability #") then return end
    return name:lower():gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","")
end

function MM:SameAbility(source,target,sourceClass,targetClass)
    if source.id and source.id==target.id then return "Same ability available on the destination",3 end
    local a,b=source.baseID,target.baseID
    if a and (a==target.id or a==b) or b and b==source.id then return "Same ability; base ID or talent replacement",2 end
    local classA,classB=sourceClass or source.class,targetClass or target.class
    if classA and classA==classB then
        local nameA,nameB=normalizedName(source.name),normalizedName(target.name)
        if nameA and nameA==nameB then return "Same class and name; copy the available ability",1 end
    end
end

function MM:FindProfileSpell(spells,id)
    if spells[id] then return spells[id] end
    local found,foundID
    for key,spell in pairs(spells) do
        if spell.id==id or spell.baseID==id then
            if not foundID or key<foundID then found,foundID=spell,key end
        end
    end
    return found
end

function MM:CompareEffects(source,target)
    local a,b=self:GetFunctionProfile(source),self:GetFunctionProfile(target)
    local context={emergency=a.emergency and b.emergency,collective=false,bonus=0}
    local cooldownA,cooldownB=self:UsageCooldown(source),self:UsageCooldown(target)
    context.damageWindow=a.damage=="primary" and b.damage=="primary" and a.area and b.area
        and (source.role=="burst" or target.role=="burst") and cooldownA and cooldownB
        and cooldownA>=20 and cooldownB>=20
    local notes,penalty,approximate={},0,false
    if context.emergency then
        approximate=true
        if a.primary~=b.primary then
            penalty=4
            notes[#notes+1]="Same emergency use; healing and protection have different effects, and immunity does not restore health"
        end
    else
        if a.damage=="primary" and b.damage==nil and target.role=="burst"
            or b.damage=="primary" and a.damage==nil and source.role=="burst" then
            return false,"Direct damage is not confirmed on the other cooldown; do not assume a buff deals area damage"
        end
        if a.damage=="primary" and b.damage=="none" or a.damage=="none" and b.damage=="primary" then
            return false,"Primary direct damage and a no-damage button play different roles in the rotation"
        end
        if a.damage=="primary" and b.damage=="primary" and a.area~=b.area then
            return false,"Area damage and single-target damage serve different purposes"
        end
        if context.damageWindow and a.primary~=b.primary then
            approximate=true; penalty=penalty+3
            notes[#notes+1]="Area damage on cooldown; offensive window and rotation interactions differ"
        end
        if a.primary==b.primary and (a.primary=="control" or a.primary=="interrupt") then
            if a.controlScope~=b.controlScope then return false,"Group control is not equivalent to single-target control" end
            context.collective=a.controlScope=="area"
            if a.control~=b.control then
                if a.primary=="control" and not context.collective then return false,"Different types of single-target control" end
                approximate=true; penalty=penalty+2
                notes[#notes+1]="Different control effects: "..(controlLabels[a.control] or "interrupt").." > "..(controlLabels[b.control] or "interrupt")
            end
        end
        if a.damage~=b.damage and a.damage and b.damage then
            approximate=true; penalty=penalty+2
            notes[#notes+1]="Secondary damage presence differs"
        end
    end
    for effect in pairs(a.secondary) do
        if b.secondary[effect] then context.bonus=math.min(6,context.bonus+2)
        else
            approximate=true; penalty=penalty+2
            notes[#notes+1]="Secondary effect not confirmed on the alternative: "..effectLabels[effect]
        end
    end
    if a.breakOnDamage~=b.breakOnDamage and (a.breakOnDamage~=nil or b.breakOnDamage~=nil) then
        approximate=true; penalty=penalty+2; notes[#notes+1]="Damage breaks crowd control differently"
    end
    local x,y=source.rotation,target.rotation
    if x and y and (x.rhythm~=y.rhythm or x.flow~=y.flow) then
        approximate=true
        notes[#notes+1]="Different rotation cadence or resource/proc interaction"
    end
    return true,table.concat(notes,"; "),approximate,math.min(penalty,12),context
end

function MM:IsActivePurpose(spell)
    local purpose=spell and spell.purpose
    return not purpose or purpose.availability~="passive"
        and not (purpose.availability and purpose.availability:match("^removed"))
        and purpose.recovery~="passive"
end

local function publicNumber(value)
    return type(value)=="number" and not (issecretvalue and issecretvalue(value))
        and value>=0 and value==value and value<math.huge
end

function MM:ReadUsageMetadata(entry)
    if InCombatLockdown() then return end
    -- Base cooldown is static; current remaining cooldown would misclassify a
    -- ready emergency button as a freely repeatable action. Never read that here.
    if GetSpellBaseCooldown then
        local ok,milliseconds=pcall(GetSpellBaseCooldown,entry.id)
        if ok and publicNumber(milliseconds) then entry.baseCooldown=milliseconds/1000 end
    end
    if C_Spell and C_Spell.GetSpellCharges then
        local ok,charges=pcall(C_Spell.GetSpellCharges,entry.id)
        if ok and type(charges)=="table" and not (issecretvalue and issecretvalue(charges)) then
            if publicNumber(charges.maxCharges) and charges.maxCharges>0 then entry.chargeCount=charges.maxCharges end
            if publicNumber(charges.cooldownDuration) and charges.cooldownDuration>0 then entry.rechargeDuration=charges.cooldownDuration end
        end
    end
end

function MM:UsageCooldown(spell)
    if publicNumber(spell.rechargeDuration) and spell.rechargeDuration>0 then return spell.rechargeDuration,"recarga observada" end
    local purpose=spell.purpose
    if publicNumber(spell.baseCooldown) and spell.baseCooldown>0 then return spell.baseCooldown,"cooldown base do cliente" end
    if purpose and publicNumber(purpose.cooldown) then return purpose.cooldown,"cooldown nominal revisado" end
    if publicNumber(spell.baseCooldown) then return spell.baseCooldown,"cooldown base do cliente" end
end

local function seconds(value)
    if value>=60 and value%60==0 then return string.format("%d min",value/60) end
    return string.format("%g s",value)
end

local function isHeal(purpose)
    return purpose and (purpose.primary=="self_heal" or purpose.primary=="heal")
end

local function isRepeatable(spell)
    local purpose=spell.purpose
    local cooldown=MM:UsageCooldown(spell)
    if purpose then
        if purpose.condition or purpose.recovery=="kill_reset" or purpose.recovery=="proc" then return false end
        if cooldown and cooldown>1.5 then return false end
        if purpose.cadence=="repeatable" then return true end
        if purpose.cadence=="short" or purpose.cadence=="emergency" or purpose.cadence=="window" then return false end
    end
    if cooldown then return cooldown<=1.5 end
end

local breaksFor={stun_break="stun",fear_break="fear"}
local function controlBreak(purpose)
    return purpose and (breaksFor[purpose.primary] or purpose.primary=="control_break")
end

-- Returns a veto before preferred pairs are considered, then ranking differences.
function MM:CompareUsage(source,target)
    local a,b=source.purpose,target.purpose
    local effectsOK,effectsReason,approximate,penalty,context=self:CompareEffects(source,target)
    if not effectsOK then return false,effectsReason end
    local notes={}
    if effectsReason~="" then notes[#notes+1]=effectsReason end
    if a and b then
        local approach=a.primary=="pull" and b.primary=="movement" or a.primary=="movement" and b.primary=="pull"
        local sharedHeal=isHeal(a) and isHeal(b)
        local sharedBreak=controlBreak(a) and controlBreak(b)
        if a.primary~=b.primary and not context.emergency and not context.damageWindow and not approach and not sharedHeal and not sharedBreak then
            return false,"Different primary purposes"
        end
        if not context.emergency and isHeal(a)~=isHeal(b) then return false,"Different primary purpose: healing versus another function" end
        if isHeal(a) and not context.emergency then
            local scopeA=a.scope or (a.primary=="self_heal" and "self" or "friendly")
            local scopeB=b.scope or (b.primary=="self_heal" and "self" or "friendly")
            if scopeA~=scopeB then return false,"Self, ally, and group healing serve different purposes" end
            if a.condition~=b.condition and (a.condition=="after_kill" or b.condition=="after_kill") then
                return false,"A heal that requires a kill does not replace an on-demand heal"
            end
        end
        if controlBreak(a) or controlBreak(b) then
            if not controlBreak(a) or not controlBreak(b) then return false,"Breaking crowd control is the primary purpose" end
            local required=breaksFor[a.primary]
            if required then
                if not (b.breaks and b.breaks[required]) then
                    return false,"The alternative does not remove "..({stun="stun",fear="fear"})[required]
                end
            else
                local shared=false
                for kind in pairs(a.breaks or {}) do if b.breaks and b.breaks[kind] then shared=true end end
                if not shared then return false,"The abilities remove different control effects" end
            end
            for kind in pairs(a.breaks or {}) do
                if not (b.breaks and b.breaks[kind]) then approximate=true; notes[#notes+1]="Does not remove all the same control effects"; break end
            end
        end
        if not context.emergency and (a.primary=="immunity")~=(b.primary=="immunity") then return false,"Immunity and damage reduction serve different purposes" end
        if not context.emergency and a.scope and b.scope and a.scope~=b.scope then return false,"Different primary targets" end
    end
    if source.role=="heal" or target.role=="heal" or isHeal(a) or isHeal(b) then
        local recurringA,recurringB=isRepeatable(source),isRepeatable(target)
        if recurringA~=nil and recurringB~=nil and recurringA~=recurringB then
            return false,"Repeatable resource-based healing is not equivalent to cooldown healing or healing that requires a kill"
        end
    end
    if a and b and a.condition~=b.condition and (a.condition or b.condition) then
        approximate=true; penalty=penalty+4
        notes[#notes+1]="Different usage conditions; check availability"
    end
    local x,y=self:UsageCooldown(source),self:UsageCooldown(target)
    if x and y and x>1.5 and y>1.5 then
        local ratio=math.max(x,y)/math.min(x,y)
        if ratio>=1.5 then
            approximate=true; penalty=penalty+math.min(6,math.floor(math.log(ratio)/math.log(2)*3))
            notes[#notes+1]="Reference cooldowns: "..seconds(x).." > "..seconds(y)
        end
    end
    local chargesA=source.chargeCount or a and a.charges or 1
    local chargesB=target.chargeCount or b and b.charges or 1
    if chargesA~=chargesB then
        approximate=true; penalty=penalty+2
        notes[#notes+1]="Different number of charges"
    end
    return true,table.concat(notes,"; "),approximate,penalty,context
end

function MM:PurposeLabel(spell)
    local purpose=spell.purpose
    if not purpose then return end
    local functions=self:GetFunctionProfile(spell)
    if functions.emergency then
        return "Emergency · "..(purpose.primary=="immunity" and "immunity" or "healing")
    end
    if purpose.primary=="control" and functions.controlScope=="area" then
        return "Group control · "..(controlLabels[functions.control] or "area")
    end
    if purpose.primary=="interrupt" and functions.controlScope=="area" then return "Group interrupt" end
    if functions.damage=="primary" and functions.area and spell.role=="burst" then return "Area damage · burst" end
    local labels={stun_break="Break stun",fear_break="Break fear",control_break="Break crowd control"}
    local label=labels[purpose.primary]
    if isHeal(purpose) then
        label=({self="Personal healing",friendly="Ally healing",group="Group healing"})[purpose.scope or (purpose.primary=="self_heal" and "self" or "friendly")]
        if purpose.condition=="after_kill" then return label.." · after a kill" end
        if isRepeatable(spell) then return label.." · repeatable" end
        return label.." · with a cooldown"
    end
    if label then return label end
    local utilityLabels={threat_drop="Threat reduction",interrupt="Interrupt",taunt="Taunt",
        resurrect="Resurrection",resurrection="Resurrection",water_walk="Water walking",
        travel="Mount · travel / fly",utility="Utility",buff="Group buff"}
    if purpose.primary=="cleanse" then
        return purpose.scope=="enemy" and "Remove an enemy effect" or "Dispel an ally effect"
    end
    return utilityLabels[purpose.primary]
end

function MM:UsageDetails(spell)
    local purpose=spell.purpose
    local details={}
    if purpose and purpose.description then details[#details+1]="Primary purpose: "..purpose.description end
    local functions=self:GetFunctionProfile(spell)
    local secondary={}
    for effect in pairs(functions.secondary) do secondary[#secondary+1]=effectLabels[effect] end
    table.sort(secondary)
    if #secondary>0 then details[#details+1]="Secondary effects: "..table.concat(secondary,", ") end
    if functions.controlScope then
        details[#details+1]="Control: "..(controlLabels[functions.control] or "control").." · "..
            (functions.controlScope=="area" and "group" or "single target")
    end
    if functions.damage=="none" then details[#details+1]="No direct damage." end
    if functions.emergency then details[#details+1]="Emergency-survival option; each has its own mechanism and consequences. Immunity does not imply healing." end
    local cooldown,source=self:UsageCooldown(spell)
    if cooldown then
        details[#details+1]=cooldown>1.5 and (seconds(cooldown).." · "..source.."; talents may change it.")
            or "No long cooldown of its own; resource and usage conditions still apply."
    end
    local charges=spell.chargeCount or purpose and purpose.charges
    if charges and charges>1 then details[#details+1]="Charges: "..charges end
    if purpose then
        if purpose.condition=="after_kill" then details[#details+1]="Available only after a valid kill; the usage window is not a cooldown." end
        if purpose.recovery=="kill_reset" then details[#details+1]="A valid kill resets the cooldown; without a kill, the cooldown still applies." end
        if purpose.resetCondition then details[#details+1]="Cooldown: "..purpose.resetCondition end
        if purpose.chargeNote then details[#details+1]=purpose.chargeNote end
        if purpose.intentNote then details[#details+1]=purpose.intentNote end
        if purpose.condition and purpose.condition~="after_kill" then details[#details+1]="Usage condition: "..purpose.condition end
        if purpose.reviewed==false then details[#details+1]="Incomplete or legacy profile; do not use for automatic mapping." end
        for _,url in ipairs(purpose.sources or {}) do details[#details+1]=url end
    end
    return details
end
