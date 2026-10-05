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
profile(71,{12294},"core","core","spend","Ataque central da rotação, com gasto de Fúria e cooldown recorrente.")
profile(71,{7384},"core","core","neutral","Ataque recorrente de preparação; não gera Fúria diretamente.")
profile(71,{1464},"spender","filler","spend","Preenche intervalos; procs podem substituí-lo por Heroic Strike.")
profile(71,{5308},"execute","execute","spend","Execução e resposta aos procs de Sudden Death.")
profile(71,{845},"aoe_spender","core","spend","Ataque recorrente em área; também mantém Rend conforme os talentos.")
profile(71,{772},"dot","maintenance","spend","Manutenção do sangramento de Rend.")
profile(71,{107574,167105,262161,227847},"burst","major","neutral","Cooldown ofensivo; a aplicação e as interações variam entre essas habilidades.")
profile(72,{23881,85288},"builder","core","generation","Geração de Fúria; a prioridade muda com talentos e procs.")
profile(72,{184367},"spender","core","spend","Gasto central de Fúria e manutenção de Enrage.")
profile(72,{5308},"execute","execute","spend","Execução, também acessível com Sudden Death.")
profile(72,{1680},"aoe","maintenance","maintenance","Preparação/manutenção de cleave com Improved Whirlwind.")
profile(72,{1719},"burst","major","neutral","Janela ofensiva de Recklessness.")
profile(70,{184575,20271},"builder","core","generation","Geração de Poder Sagrado; Blade of Justice pode responder a procs.")
profile(70,{24275},"execute","execute","generation","Geração de Poder Sagrado condicionada à execução ou à janela ofensiva.")
profile(70,{85256,383328},"spender","core","spend","Finalizador de Poder Sagrado em alvo único.")
profile(70,{53385},"aoe_spender","core","spend","Finalizador de Poder Sagrado em área.")
profile(70,{31884},"burst","major","neutral","Janela ofensiva; alinhar conforme a build.")
profile(253,{34026},"core","core","spend","Ataque recorrente do pet; consome Foco.")
profile(253,{217200},"builder","maintenance","generation","Geração de Foco e manutenção dos efeitos associados ao pet.")
profile(253,{193455},"spender","filler","spend","Gasto de Foco para preencher intervalos da rotação.")
profile(253,{19574},"burst","major","neutral","Janela ofensiva de Bestial Wrath.")
profile(259,{1329},"builder","filler","generation","Gasta Energia e gera pontos de combo em alvo único.")
profile(259,{32645},"spender","core","spend","Finalizador direto de pontos de combo.")
profile(259,{703},"dot","maintenance","generation","Mantém sangramento e participa da geração de pontos de combo.")
profile(259,{1943},"dot","maintenance","spend","Finalizador periódico de pontos de combo.")
profile(259,{51723},"aoe_builder","filler","generation","Geração de pontos de combo em área.")
profile(259,{121411},"aoe_spender","maintenance","spend","Finalizador em área associado à distribuição de sangramentos.")
profile(259,{360194},"burst","major","neutral","Janela ofensiva associada aos efeitos periódicos.")
profile(258,{8092},"builder","core","generation","Gerador de Insanidade com cooldown curto.")
profile(258,{335467},"spender","maintenance","spend","Shadow Word: Madness: gasto de Insanidade com efeito periódico.")
profile(258,{589,34914},"dot","maintenance","maintenance","Manutenção dos efeitos periódicos centrais.")
profile(258,{32379},"execute","execute","generation","Execução que participa da geração de Insanidade.")
profile(257,{2061},"heal","filler","healing","Cura direta recorrente; Surge of Light pode torná-la instantânea.")
profile(257,{2050},"heal","short_cooldown","healing","Cura direta forte de aliado com cooldown reduzido por Serendipity.")
profile(257,{585},"filler","filler","neutral","Preenchimento de dano enquanto não há necessidade de cura.")
profile(251,{49020},"builder","core","generation","Gasta Runas, gera Poder Rúnico e consome Killing Machine quando disponível.")
profile(251,{49143},"spender","core","spend","Gasto de Poder Rúnico; procs e talentos alteram a prioridade.")
profile(251,{49184},"aoe_proc_spender","reactive","proc_spend","Usada principalmente com Rime; não é um gerador em área genérico.")
profile(251,{207230},"aoe_builder","core","generation","Alternativa em área de gasto de Runas, com interação com Killing Machine.")
profile(251,{194913},"aoe_spender","core","spend","Gasto de Poder Rúnico em área.")
profile(251,{51271},"burst","major","neutral","Janela ofensiva de Pillar of Frost.")
profile(251,{279302},"burst","major","neutral","Dano em área alinhado à janela de Pillar; stun e lentidão são efeitos adicionais.")
profile(250,{49998},"mitigation","reactive","spend","Gasto de Poder Rúnico para recuperação; respeitar o momento do dano recebido.")
profile(250,{195182},"builder","maintenance","generation","Gasta Runas e mantém Bone Shield.")
profile(250,{206930},"builder","filler","generation","Gasta Runas para gerar Poder Rúnico.")
profile(250,{50842},"aoe","maintenance","maintenance","Aplica doença em área e usa cargas; não é gerador de recurso garantido.")
profile(250,{43265},"aoe","maintenance","maintenance","Área no chão que sustenta o comportamento de cleave.")
profile(262,{188196},"builder","filler","generation","Preenchimento que gera Maelstrom.")
profile(262,{51505},"builder","core","generation","Gerador recorrente; pode responder a Lava Surge.")
profile(262,{8042},"spender","core","spend","Gasto principal de Maelstrom em alvo único.")
profile(262,{61882},"aoe_spender","core","spend","Gasto de Maelstrom em área persistente.")
profile(262,{188443},"aoe_builder","filler","generation","Geração de Maelstrom em múltiplos alvos.")
profile(262,{188389},"dot","maintenance","maintenance","Manutenção de Flame Shock.")
profile(262,{114050},"burst","major","neutral","Janela ofensiva de Ascendance.")
profile(63,{133},"filler","filler","proc_generation","Preenchimento que participa da geração de Heating Up/Hot Streak.")
profile(63,{108853},"proc_builder","reactive","proc_generation","Converte Heating Up em Hot Streak; pode ser usado durante outro cast.")
profile(63,{11366},"proc_spender","reactive","proc_spend","Consome Hot Streak; Pyroclasm e Hyperthermia oferecem outros contextos.")
profile(63,{2120},"aoe_proc_spender","reactive","proc_spend","Alternativa em área para consumir os procs do mago de Fogo.")
profile(63,{190319},"burst","major","neutral","Janela ofensiva de Combustion.")
profile(64,{116},"filler","filler","proc_generation","Preenchimento da especialização; talentos podem substituí-lo.")
profile(64,{30455},"proc_spender","reactive","proc_spend","Resposta a Fingers of Frost ou acúmulo de Freezing; não é gasto comum de Mana.")
profile(64,{44614},"proc_builder","reactive","proc_generation","Prepara Freezing; interage com Brain Freeze.")
profile(64,{190356},"aoe","short_cooldown","neutral","Dano em área usado conforme disponibilidade e build.")
profile(64,{84714},"aoe","short_cooldown","neutral","Cooldown recorrente em área com interações de rotação.")
profile(267,{29722},"builder","filler","generation","Preenchimento que gera Fragmentos de Alma.")
profile(267,{17962},"builder","core","generation","Gera Fragmentos de Alma e exige gestão das cargas.")
profile(267,{116858},"spender","core","spend","Gasto de Fragmentos de Alma em alvo único.")
profile(267,{5740},"aoe_spender","core","spend","Gasto de Fragmentos de Alma em área no chão.")
profile(267,{348},"dot","maintenance","generation","Manutenção de Immolate, associada à geração de recurso.")
profile(267,{1122},"burst","major","neutral","Cooldown ofensivo de Summon Infernal.")
profile(269,{100780},"builder","filler","generation","Gasta Energia para gerar Chi; evitar repetições que percam Combo Strikes.")
profile(269,{100784},"spender","filler","spend","Gasto de Chi entre ataques de maior prioridade; possui interações de proc.")
profile(269,{107428},"spender","short_cooldown","spend","Gasto de Chi com cooldown recorrente.")
profile(269,{113656},"spender","short_cooldown","spend","Gasto de Chi canalizado; preservar recursos para seu cooldown.")
profile(269,{101546},"aoe_spender","filler","spend","Gasto de Chi em área; procs e bônus de conjunto mudam a prioridade.")
profile(103,{5221},"builder","filler","generation","Gasta Energia para gerar pontos de combo.")
profile(103,{1822},"dot","maintenance","generation","Gera pontos de combo e mantém sangramento.")
profile(103,{22568},"spender","core","spend","Finalizador direto de pontos de combo; pode receber procs gratuitos.")
profile(103,{1079},"dot","maintenance","spend","Finalizador periódico de pontos de combo.")
profile(103,{106785},"aoe_builder","filler","generation","Gasta Energia e gera pontos de combo em área.")
profile(103,{106951,102543},"burst","major","neutral","Janela ofensiva longa; alinhar conforme talentos.")
profile(577,{232893},"builder","core","generation","Geração ativa de Fúria com aproximação ao alvo.")
profile(577,{162794},"spender","filler","spend","Gasto de Fúria entre cooldowns prioritários; muda para Annihilation em Metamorphosis.")
profile(577,{188499},"aoe_spender","short_cooldown","spend","Gasto de Fúria com cooldown; muda para Death Sweep em Metamorphosis.")
profile(577,{198013},"aoe","short_cooldown","spend","Canalização recorrente que inicia interações da janela ofensiva.")
profile(577,{258920},"aoe_builder","short_cooldown","generation","Dano ao redor do personagem e geração de Fúria conforme a build.")
profile(577,{191427},"burst","major","neutral","Janela ofensiva de Metamorphosis.")
profile(1467,{361469},"filler","filler","proc_generation","Preenchimento que pode gerar Essence Burst; não gera Essência diretamente.")
profile(1467,{356995},"spender","core","spend","Gasto de Essência canalizado; Essence Burst permite usos gratuitos.")
profile(1467,{357211},"aoe_spender","core","spend","Gasto de Essência em área; Essence Burst permite usos gratuitos.")
profile(1467,{357208,359073},"empowered","short_cooldown","neutral","Habilidade potencializada: duração do carregamento muda o efeito.")
profile(1467,{375087},"burst","major","neutral","Janela ofensiva de Dragonrage.")

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
    if InCombatLockdown() then return {available=false,reason="Consulta adiada até sair do combate"} end
    local api=C_AssistedCombat
    if not api or not api.IsAvailable or not api.GetRotationSpells then
        return {available=false,reason="API de rotação assistida indisponível"}
    end
    local ok,available,reason=pcall(api.IsAvailable)
    if not ok or not available then
        return {available=false,reason=ok and reason or "Não foi possível consultar a assistência"}
    end
    local success,ids=pcall(api.GetRotationSpells)
    if not success or type(ids)~="table" then
        return {available=false,reason="Lista da rotação assistida indisponível"}
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
