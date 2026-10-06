local _, MM = ...

-- Effects have different weight in the player's decision: direct damage,
-- collective control and a reserved survival button are not interchangeable.
-- This supplements the per-spell audit; the active spellbook gates availability.
local function amend(id,fields)
    local entry=MM.purposeCatalog[id] or {}
    for key,value in pairs(fields) do entry[key]=value end
    MM.purposeCatalog[id]=entry
end

amend(207167,{class="DEATHKNIGHT",name="Blinding Sleet",role="stun",primary="control",
    cadence="utility",recovery="cooldown",cooldown=60,scope="enemy",damage="none",
    control={kind="disorient",scope="area",breakOnDamage=true},traits={control="disorient"},
    also={"area","disorient","slow"},reviewed=true,checkedAt="2026-10-04",patch="12.1",
    description="Stop multiple enemies in a cone without dealing damage; damage can break the disorient. Applies a slow afterward.",
    sources={"https://www.wowhead.com/spell=207167/blinding-sleet"}})
amend(279302,{class="DEATHKNIGHT",name="Frostwyrm's Fury",specs={251},role="burst",
    primary="offensive_window",cadence="window",recovery="cooldown",cooldown=90,scope="enemy",
    damage="primary",area=true,control={kind="stun",scope="area"},
    also={"area_damage","stun","slow","window_synergy"},reviewed=true,checkedAt="2026-10-04",patch="12.1",
    description="Area-damage burst during an offensive window; also stuns and slows enemies hit. Apex talents add interactions with Pillar of Frost and recasts.",
    sources={"https://www.wowhead.com/spell=279302/frostwyrms-fury",
        "https://www.icy-veins.com/wow/frost-death-knight-pve-dps-rotation-cooldowns-abilities"}})
amend(5246,{class="WARRIOR",name="Intimidating Shout",role="stun",primary="control",
    cadence="utility",recovery="cooldown",cooldown=90,scope="enemy",damage="none",
    control={kind="fear",scope="area",breakOnDamage=true},traits={control="fear"},
    also={"area","fear","slow"},reviewed=true,checkedAt="2026-10-04",patch="12.1",
    description="Control the target and nearby enemies with fear, without direct damage; enemies may flee, and damage can break the effect.",
    sources={"https://www.wowhead.com/spell=5246/intimidating-shout"}})
amend(227847,{class="WARRIOR",name="Bladestorm",specs={71,72},role="burst",
    primary="offensive_window",cadence="window",recovery="cooldown",cooldown=90,scope="enemy",
    damage="primary",area=true,also={"area_damage","control_immunity","generate_resource"},
    variants={[71]={also={"area_damage","control_immunity"}}},
    reviewed=true,checkedAt="2026-10-04",patch="12.1",
    description="Heavy area damage during an offensive window; control immunity protects the warrior and does not stun enemies.",
    sources={"https://www.wowhead.com/spell=227847/bladestorm"}})

-- Shared emergency decision, with deliberately different mechanisms. No claim
-- that healing restores immunity, or that immunity restores health.
for _,id in ipairs({48743,642,45438,633}) do
    amend(id,{intent="personal_emergency",emergencySelf=true})
end
amend(45438,{primary="immunity",role="immunity",traits={no_attack=true}})
MM.emergencyPairs={[48743]={642,45438,633},[642]={48743,45438},[45438]={48743,642}}

-- Confirmed collective controls. A missing area flag is not inferred from a CD.
for _,id in ipairs({46968,119381,30283,192058,8122,99,132469,357214,368970,202137}) do
    local entry=MM.purposeCatalog[id]
    if entry then
        entry.control=entry.control or {}
        entry.control.scope="area"
    end
end
amend(46968,{damage="secondary",control={kind="stun",scope="area"}})
for _,id in ipairs({119381,30283,192058,8122}) do amend(id,{damage="none"}) end

MM.purposeReview.total,MM.purposeReview.reviewed,MM.purposeReview.classes=0,0,{}
for _,entry in pairs(MM.purposeCatalog) do
    MM.purposeReview.total=MM.purposeReview.total+1
    if entry.reviewed then MM.purposeReview.reviewed=MM.purposeReview.reviewed+1 end
    local class=entry.class or "RACIAL"
    MM.purposeReview.classes[class]=(MM.purposeReview.classes[class] or 0)+1
end
