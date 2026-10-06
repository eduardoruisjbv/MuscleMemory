local _, MM = ...

-- Reviewed functional context, NOT a priority list or a combat recommendation.
-- Talents, hero trees and tier sets change priorities; membership in the native
-- assistant list never establishes a cross-class equivalence by itself.
MM.rotationSources = {}
MM.rotationProfiles = {}
local function guide(spec,class,slug,publisher,url)
    MM.rotationSources[spec]={class=class,publisher=publisher or "Icy Veins",patch="12.1",
        checked="2026-10-03",url=url or ("https://www.icy-veins.com/wow/"..slug)}
    MM.rotationProfiles[spec]={}
end
guide(72,"WARRIOR",nil,"Wowhead","https://www.wowhead.com/guide/classes/warrior/fury/rotation-cooldowns-pve-dps")
guide(71,"WARRIOR",nil,"Wowhead","https://www.wowhead.com/guide/classes/warrior/arms/rotation-cooldowns-pve-dps")
guide(70,"PALADIN","retribution-paladin-pve-dps-easy-mode")
guide(253,"HUNTER","beast-mastery-hunter-pve-dps-easy-mode")
guide(259,"ROGUE","assassination-rogue-pve-dps-easy-mode")
guide(258,"PRIEST","shadow-priest-pve-dps-easy-mode")
guide(257,"PRIEST","holy-priest-pve-healing-easy-mode")
guide(251,"DEATHKNIGHT","frost-death-knight-pve-dps-rotation-cooldowns-abilities")
guide(250,"DEATHKNIGHT","blood-death-knight-pve-tank-easy-mode")
guide(262,"SHAMAN","elemental-shaman-pve-dps-easy-mode")
guide(63,"MAGE","fire-mage-pve-dps-easy-mode")
guide(64,"MAGE","frost-mage-pve-dps-easy-mode")
guide(267,"WARLOCK","destruction-warlock-pve-dps-easy-mode")
guide(269,"MONK","windwalker-monk-pve-dps-easy-mode")
guide(103,"DRUID","feral-druid-pve-dps-easy-mode")
guide(577,"DEMONHUNTER","havoc-demon-hunter-pve-dps-easy-mode")
guide(1467,"EVOKER","devastation-evoker-pve-dps-easy-mode")

-- Spell IDs checked against Wowhead spell metadata; availability is still live.
MM.catalog[184575]={class="PALADIN",role="builder",specs={70},curated=true}
MM.catalog[207230]={class="DEATHKNIGHT",role="aoe_builder",specs={251},curated=true}
MM.catalog[194913]={class="DEATHKNIGHT",role="aoe_spender",specs={251},curated=true}
MM.catalog[845]={class="WARRIOR",role="aoe_spender",specs={71},curated=true}
MM.catalog[772]={class="WARRIOR",role="dot",specs={71},curated=true}
MM.catalog[107574]={class="WARRIOR",role="burst",specs={71,72,73},curated=true}
MM.catalog[227847]={class="WARRIOR",role="burst",specs={71},curated=true}
MM.catalog[45524]={class="DEATHKNIGHT",role="slow",curated=true}
MM.catalog[1715]={class="WARRIOR",role="slow",curated=true}
MM.catalog[18499]={class="WARRIOR",role="cc_break",curated=true,traits={breaks="fear_incapacitate"}}
MM.catalog[49039].role="cc_break"
MM.catalog[49039].traits.breaks="charm_fear_sleep"
-- Overpower does not generate Rage merely because it has no resource cost.
MM.catalog[7384].role="core"

local function profile(spec,ids,role,rhythm,flow,description)
    for _,id in ipairs(ids) do
        MM.rotationProfiles[spec][id]={role=role,rhythm=rhythm,flow=flow,description=description,source=spec}
    end
end
profile(71,{12294},"core","core","spend","Core rotation attack that spends Rage and has a recurring cooldown.")
profile(71,{7384},"core","core","neutral","Recurring setup attack; does not generate Rage directly.")
profile(71,{1464},"spender","filler","spend","Fills gaps; procs may replace it with Heroic Strike.")
profile(71,{5308},"execute","execute","spend","Execute attack and response to Sudden Death procs.")
profile(71,{845},"aoe_spender","core","spend","Recurring area attack; also maintains Rend depending on talents.")
profile(71,{772},"dot","maintenance","spend","Maintains Rend’s bleed.")
profile(71,{107574,167105,262161,227847},"burst","major","neutral","Offensive cooldown; usage and interactions vary across these abilities.")
profile(72,{23881,85288},"builder","core","generation","Rage generation; priority changes with talents and procs.")
profile(72,{184367},"spender","core","spend","Core Rage spender and Enrage maintenance.")
profile(72,{5308},"execute","execute","spend","Execute attack, also available through Sudden Death.")
profile(72,{1680},"aoe","maintenance","maintenance","Cleave setup and maintenance with Improved Whirlwind.")
profile(72,{1719},"burst","major","neutral","Recklessness offensive window.")
profile(70,{184575,20271},"builder","core","generation","Holy Power generation; Blade of Justice can respond to procs.")
profile(70,{24275},"execute","execute","generation","Holy Power generation conditional on execute range or the offensive window.")
profile(70,{85256,383328},"spender","core","spend","Single-target Holy Power finisher.")
profile(70,{53385},"aoe_spender","core","spend","Area Holy Power finisher.")
profile(70,{31884},"burst","major","neutral","Offensive window; align with the build.")
profile(253,{34026},"core","core","spend","Recurring pet attack; spends Focus.")
profile(253,{217200},"builder","maintenance","generation","Generates Focus and maintains pet-related effects.")
profile(253,{193455},"spender","filler","spend","Focus spender used to fill gaps in the rotation.")
profile(253,{19574},"burst","major","neutral","Bestial Wrath offensive window.")
profile(259,{1329},"builder","filler","generation","Spends Energy and generates single-target combo points.")
profile(259,{32645},"spender","core","spend","Direct combo point finisher.")
profile(259,{703},"dot","maintenance","generation","Maintains a bleed and contributes to combo point generation.")
profile(259,{1943},"dot","maintenance","spend","Damage-over-time combo point finisher.")
profile(259,{51723},"aoe_builder","filler","generation","Area combo point generation.")
profile(259,{121411},"aoe_spender","maintenance","spend","Area finisher associated with spreading bleeds.")
profile(259,{360194},"burst","major","neutral","Offensive window associated with damage-over-time effects.")
profile(258,{8092},"builder","core","generation","Insanity generator with a short cooldown.")
profile(258,{335467},"spender","maintenance","spend","Shadow Word: Madness: Insanity spender with a damage-over-time effect.")
profile(258,{589,34914},"dot","maintenance","maintenance","Maintains core damage-over-time effects.")
profile(258,{32379},"execute","execute","generation","Execute attack that contributes to Insanity generation.")
profile(257,{2061},"heal","filler","healing","Recurring direct heal; Surge of Light can make it instant.")
profile(257,{2050},"heal","short_cooldown","healing","Powerful direct ally heal whose cooldown is reduced by Serendipity.")
profile(257,{585},"filler","filler","neutral","Damage filler when healing is not needed.")
profile(251,{49020},"builder","core","generation","Spends Runes, generates Runic Power, and consumes Killing Machine when available.")
profile(251,{49143},"spender","core","spend","Runic Power spender; procs and talents change its priority.")
profile(251,{49184},"aoe_proc_spender","reactive","proc_spend","Primarily used with Rime; not a generic area generator.")
profile(251,{207230},"aoe_builder","core","generation","Area Rune spender that interacts with Killing Machine.")
profile(251,{194913},"aoe_spender","core","spend","Area Runic Power spender.")
profile(251,{51271},"burst","major","neutral","Pillar of Frost offensive window.")
profile(251,{279302},"burst","major","neutral","Area damage aligned with the Pillar window; stun and slow are secondary effects.")
profile(250,{49998},"mitigation","reactive","spend","Runic Power spender for recovery; time it around incoming damage.")
profile(250,{195182},"builder","maintenance","generation","Spends Runes and maintains Bone Shield.")
profile(250,{206930},"builder","filler","generation","Spends Runes to generate Runic Power.")
profile(250,{50842},"aoe","maintenance","maintenance","Applies an area disease and consumes charges; does not guarantee resource generation.")
profile(250,{43265},"aoe","maintenance","maintenance","Ground area effect that supports cleave.")
profile(262,{188196},"builder","filler","generation","Filler that generates Maelstrom.")
profile(262,{51505},"builder","core","generation","Recurring generator; can respond to Lava Surge.")
profile(262,{8042},"spender","core","spend","Primary single-target Maelstrom spender.")
profile(262,{61882},"aoe_spender","core","spend","Persistent area Maelstrom spender.")
profile(262,{188443},"aoe_builder","filler","generation","Maelstrom generation against multiple targets.")
profile(262,{188389},"dot","maintenance","maintenance","Flame Shock maintenance.")
profile(262,{114050},"burst","major","neutral","Ascendance offensive window.")
profile(63,{133},"filler","filler","proc_generation","Filler that contributes to Heating Up/Hot Streak generation.")
profile(63,{108853},"proc_builder","reactive","proc_generation","Converts Heating Up into Hot Streak; can be used during another cast.")
profile(63,{11366},"proc_spender","reactive","proc_spend","Consumes Hot Streak; Pyroclasm and Hyperthermia provide other contexts.")
profile(63,{2120},"aoe_proc_spender","reactive","proc_spend","Area option for consuming Fire Mage procs.")
profile(63,{190319},"burst","major","neutral","Combustion offensive window.")
profile(64,{116},"filler","filler","proc_generation","Specialization filler; talents may replace it.")
profile(64,{30455},"proc_spender","reactive","proc_spend","Response to Fingers of Frost or Freezing stacks; not a regular Mana spender.")
profile(64,{44614},"proc_builder","reactive","proc_generation","Prepares Freezing and interacts with Brain Freeze.")
profile(64,{190356},"aoe","short_cooldown","neutral","Area damage used according to availability and build.")
profile(64,{84714},"aoe","short_cooldown","neutral","Recurring area cooldown with rotation interactions.")
profile(267,{29722},"builder","filler","generation","Filler that generates Soul Shards.")
profile(267,{17962},"builder","core","generation","Generates Soul Shards and requires charge management.")
profile(267,{116858},"spender","core","spend","Single-target Soul Shard spender.")
profile(267,{5740},"aoe_spender","core","spend","Ground-targeted area Soul Shard spender.")
profile(267,{348},"dot","maintenance","generation","Immolate maintenance, associated with resource generation.")
profile(267,{1122},"burst","major","neutral","Summon Infernal offensive cooldown.")
profile(269,{100780},"builder","filler","generation","Spends Energy to generate Chi; avoid repeats that lose Combo Strikes.")
profile(269,{100784},"spender","filler","spend","Chi spender between higher-priority attacks; interacts with procs.")
profile(269,{107428},"spender","short_cooldown","spend","Chi spender with a recurring cooldown.")
profile(269,{113656},"spender","short_cooldown","spend","Channeled Chi spender; preserve resources for its cooldown.")
profile(269,{101546},"aoe_spender","filler","spend","Area Chi spender; procs and set bonuses change its priority.")
profile(103,{5221},"builder","filler","generation","Spends Energy to generate combo points.")
profile(103,{1822},"dot","maintenance","generation","Generates combo points and maintains a bleed.")
profile(103,{22568},"spender","core","spend","Direct combo point finisher; can benefit from free-cast procs.")
profile(103,{1079},"dot","maintenance","spend","Damage-over-time combo point finisher.")
profile(103,{106785},"aoe_builder","filler","generation","Spends Energy and generates area combo points.")
profile(103,{106951,102543},"burst","major","neutral","Long offensive window; align with talents.")
profile(577,{232893},"builder","core","generation","Active Fury generation while closing in on the target.")
profile(577,{162794},"spender","filler","spend","Fury spender between priority cooldowns; becomes Annihilation during Metamorphosis.")
profile(577,{188499},"aoe_spender","short_cooldown","spend","Fury spender with a cooldown; becomes Death Sweep during Metamorphosis.")
profile(577,{198013},"aoe","short_cooldown","spend","Recurring channel that starts offensive-window interactions.")
profile(577,{258920},"aoe_builder","short_cooldown","generation","Deals damage around the character and generates Fury depending on the build.")
profile(577,{191427},"burst","major","neutral","Metamorphosis offensive window.")
profile(1467,{361469},"filler","filler","proc_generation","Filler that can generate Essence Burst; does not generate Essence directly.")
profile(1467,{356995},"spender","core","spend","Channeled Essence spender; Essence Burst enables free casts.")
profile(1467,{357211},"aoe_spender","core","spend","Area Essence spender; Essence Burst enables free casts.")
profile(1467,{357208,359073},"empowered","short_cooldown","neutral","Empowered ability: charge duration changes its effect.")
profile(1467,{375087},"burst","major","neutral","Dragonrage offensive window.")

-- Editorial defaults for analogous keyboard habits, not identical spell effects.
-- Lists are alternatives in preference order, filtered by the live target book.
-- Each target is reserved once; manual choices always take precedence.
MM.preferredPairs={
    ["251:71"]={
        [49020]={12294,7384}, [49143]={7384,1464}, [49184]={845,1680},
        [207230]={845,1680}, [194913]={1680,845},
        [51271]={107574,167105,262161}, [47568]={167105,262161,107574},
    },
    ["251:72"]={
        [49020]={23881,85288}, [49143]={184367}, [49184]={1680},
        [207230]={1680}, [194913]={1680}, [51271]={1719,107574}, [47568]={107574,1719},
    },
    ["251:73"]={
        [49020]={23922}, [49143]={6572}, [49184]={6343},
        [207230]={6343}, [194913]={6572},
    },
    ["250:71"]={ [206930]={12294,7384}, [195182]={7384,12294}, [50842]={845,1680}, [43265]={1680,845} },
    ["250:72"]={ [206930]={23881,85288}, [195182]={85288,23881}, [50842]={1680}, [43265]={1680} },
    ["250:73"]={ [206930]={23922}, [195182]={23922}, [50842]={6343}, [43265]={6343} },
    ["252:71"]={
        [55090]={12294}, [85948]={7384}, [47541]={1464}, [207317]={845,1680},
        [63560]={107574,167105}, [275699]={167105,262161}, [42650]={227847},
    },
    ["252:72"]={
        [55090]={23881}, [85948]={85288}, [47541]={184367}, [207317]={1680},
        [63560]={1719,107574}, [275699]={107574,1719},
    },
    ["252:73"]={ [55090]={23922}, [85948]={6343}, [47541]={6572}, [207317]={6572,6343} },
}
local reverse={}
for key,pairsForSpec in pairs(MM.preferredPairs) do
    local origin,destination=key:match("^(%d+):(%d+)$")
    local list={}
    local sourceIDs={}; for id in pairs(pairsForSpec) do sourceIDs[#sourceIDs+1]=id end
    table.sort(sourceIDs)
    for _,sourceID in ipairs(sourceIDs) do
        for _,targetID in ipairs(pairsForSpec[sourceID]) do
            list[targetID]=list[targetID] or {}
            list[targetID][#list[targetID]+1]=sourceID
        end
    end
    reverse[destination..":"..origin]=list
end
for key,list in pairs(reverse) do MM.preferredPairs[key]=list end
for _,dk in ipairs({250,251,252}) do
    for _,warrior in ipairs({71,72,73}) do
        local forward,back=MM.preferredPairs[dk..":"..warrior],MM.preferredPairs[warrior..":"..dk]
        forward[49576]={100}; forward[48265]={6544}; forward[212552]={6544}
        forward[45524]={1715}; forward[49039]={18499}
        forward[48743]={202168}
        forward[207167]={5246,46968}
        if dk==251 then forward[279302]={227847} end
        back[100]={49576}; back[6544]={48265,212552}
        back[1715]={45524}; back[18499]={49039}
        back[202168]={48743}
        back[5246]={207167}
    end
end

function MM:ApplyRotationProfile(entry,class,spec)
    local source=self.rotationSources[spec]
    local reviewed=source and source.class==class and self.rotationProfiles[spec][entry.id]
    if not reviewed then return entry end
    entry.rotation={}
    for k,v in pairs(reviewed) do entry.rotation[k]=v end
    entry.role=reviewed.role
    return entry
end

local function publicID(value)
    return type(value)=="number" and not (issecretvalue and issecretvalue(value)) and value>0
end

function MM:ReadAssistedRotation(spells)
    if InCombatLockdown() then return {available=false,reason="Query postponed until combat ends"} end
    local api=C_AssistedCombat
    if not api or not api.IsAvailable or not api.GetRotationSpells then
        return {available=false,reason="Assisted rotation API is unavailable"}
    end
    local ok,available,reason=pcall(api.IsAvailable)
    if not ok or not available then
        return {available=false,reason=ok and reason or "Could not query assisted rotation"}
    end
    local success,ids=pcall(api.GetRotationSpells)
    if not success or type(ids)~="table" then
        return {available=false,reason="Assisted rotation list is unavailable"}
    end
    local membership={}
    for _,id in ipairs(ids) do if publicID(id) then membership[id]=true end end
    for _,spell in pairs(spells) do
        spell.assistedRotation=membership[spell.id] or (spell.baseID and membership[spell.baseID]) or nil
    end
    -- Only classify a button actually present in the active spellbook. Never
    -- inject spells from the rotation list or assume its ordering is priority.
    if api.GetActionSpell then
        local found,id=pcall(api.GetActionSpell)
        if found and publicID(id) and spells[id] then
            spells[id].role,spells[id].curated,spells[id].isAssistant="assisted",true,true
        end
    end
    return {available=true,members=membership}
end
