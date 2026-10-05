local _, MM = ...

MM.classes = {
    {id=1, token="WARRIOR", name="Guerreiro", specs={71,72,73}},
    {id=2, token="PALADIN", name="Paladino", specs={65,66,70}},
    {id=3, token="HUNTER", name="Caçador", specs={253,254,255}},
    {id=4, token="ROGUE", name="Ladino", specs={259,260,261}},
    {id=5, token="PRIEST", name="Sacerdote", specs={256,257,258}},
    {id=6, token="DEATHKNIGHT", name="Cavaleiro da Morte", specs={250,251,252}},
    {id=7, token="SHAMAN", name="Xamã", specs={262,263,264}},
    {id=8, token="MAGE", name="Mago", specs={62,63,64}},
    {id=9, token="WARLOCK", name="Bruxo", specs={265,266,267}},
    {id=10, token="MONK", name="Monge", specs={268,269,270}},
    {id=11, token="DRUID", name="Druida", specs={102,103,104,105}},
    {id=12, token="DEMONHUNTER", name="Caçador de Demônios", specs={577,581,1480}},
    {id=13, token="EVOKER", name="Evocador", specs={1467,1468,1473}},
}
MM.roles = {
    unknown="Sem classificação", damage="Dano (estimado)", support="Suporte (estimado)",
    builder="Gerador de recurso", spender="Gasto de recurso", core="Ataque principal",
    filler="Ataque de preenchimento", proc_builder="Preparação de proc", proc_spender="Consumo de proc",
    aoe_proc_spender="Consumo de proc em área", empowered="Ataque potencializado", assisted="Assistente de botão único",
    aoe_builder="Gerador em área", aoe_spender="Gasto em área", aoe="Dano em área",
    burst="Cooldown ofensivo", execute="Execução", dot="Dano periódico",
    interrupt="Interrupção", stun="Controle / atordoamento", defensive="Defesa",
    immunity="Imunidade", mitigation="Gasto defensivo", mobility="Mobilidade", pull="Puxar inimigo", heal="Cura",
    cleanse="Dissipação", resurrect="Ressurreição", buff="Buff", taunt="Provocação",
    slow="Reduzir velocidade", cc_break="Resistir a controle",
    mount="Montaria · viajar / voar", utility="Utilitário", water_walk="Caminhar sobre a água",
}
-- Seeds describe intent, not current damage/cost/tuning. Live spellbook determines availability.
-- Spec constraints keep distinct rotations separate. Unknown spells remain manual/estimated.
MM.catalog = {}
local function add(class, role, ids, specs)
    for _, id in ipairs(ids) do
        MM.catalog[id] = {class=class, role=role, specs=specs, curated=true}
    end
end
add("WARRIOR", "interrupt", {6552})
add("WARRIOR", "mobility", {100,6544})
add("WARRIOR", "defensive", {871,118038,184364,23920})
add("WARRIOR", "stun", {46968,107570})
add("WARRIOR", "taunt", {355})
add("WARRIOR", "heal", {34428,202168})
add("WARRIOR", "buff", {6673})
add("WARRIOR", "core", {12294}, {71})
add("WARRIOR", "builder", {7384}, {71})
add("WARRIOR", "spender", {1464}, {71})
add("WARRIOR", "builder", {23881,85288}, {72})
add("WARRIOR", "spender", {184367}, {72})
add("WARRIOR", "execute", {5308})
add("WARRIOR", "aoe", {1680})
add("WARRIOR", "burst", {1719}, {72})
add("WARRIOR", "burst", {167105,262161}, {71})
add("WARRIOR", "builder", {23922}, {73})
add("WARRIOR", "aoe_builder", {6343}, {73})
add("WARRIOR", "mitigation", {2565,190456}, {73})
add("WARRIOR", "aoe_spender", {6572}, {73})
add("PALADIN", "interrupt", {96231})
add("PALADIN", "mobility", {190784})
add("PALADIN", "immunity", {642,1022})
add("PALADIN", "defensive", {498,31850,86659,403876})
add("PALADIN", "stun", {853})
add("PALADIN", "cleanse", {4987,213644})
add("PALADIN", "heal", {19750,85673,633})
add("PALADIN", "resurrect", {7328,391054})
add("PALADIN", "taunt", {62124})
add("PALADIN", "builder", {35395,20271,24275})
add("PALADIN", "spender", {85256,383328}, {70})
add("PALADIN", "mitigation", {53600}, {66})
add("PALADIN", "aoe_spender", {53385}, {70})
add("PALADIN", "aoe", {26573})
add("PALADIN", "burst", {31884,231895})
add("PALADIN", "heal", {20473,82326,85222}, {65})
add("HUNTER", "interrupt", {147362,187707})
add("HUNTER", "mobility", {781,186257,190925})
add("HUNTER", "immunity", {186265})
add("HUNTER", "defensive", {264735})
add("HUNTER", "heal", {109304})
add("HUNTER", "stun", {19577,187650,109248})
add("HUNTER", "execute", {53351})
add("HUNTER", "core", {34026}, {253,255})
add("HUNTER", "builder", {217200}, {253})
add("HUNTER", "spender", {193455}, {253})
add("HUNTER", "builder", {56641}, {254})
add("HUNTER", "core", {19434}, {254})
add("HUNTER", "spender", {185358}, {254})
add("HUNTER", "spender", {186270,259387}, {255})
add("HUNTER", "aoe", {257620,259495})
add("HUNTER", "burst", {19574}, {253})
add("HUNTER", "burst", {288613}, {254})
add("ROGUE", "interrupt", {1766})
add("ROGUE", "mobility", {2983,36554,195457})
add("ROGUE", "defensive", {5277,1966})
add("ROGUE", "immunity", {31224})
add("ROGUE", "heal", {185311})
add("ROGUE", "stun", {408,1833,2094})
add("ROGUE", "builder", {1329}, {259})
add("ROGUE", "builder", {193315,185763}, {260})
add("ROGUE", "builder", {53,185438}, {261})
add("ROGUE", "spender", {32645}, {259})
add("ROGUE", "spender", {2098}, {260})
add("ROGUE", "spender", {196819}, {261})
add("ROGUE", "dot", {703,1943})
add("ROGUE", "aoe_builder", {51723,197835})
add("ROGUE", "aoe_spender", {121411})
add("ROGUE", "burst", {13750,185313,360194})
add("PRIEST", "interrupt", {15487}, {258})
add("PRIEST", "mobility", {121536})
add("PRIEST", "defensive", {47585,586,33206,47788})
add("PRIEST", "stun", {8122,64044})
add("PRIEST", "cleanse", {527,528,32375,213634})
add("PRIEST", "resurrect", {2006})
add("PRIEST", "buff", {21562,10060})
add("PRIEST", "heal", {2061,2060,139,2050,47540})
add("PRIEST", "builder", {8092,15407}, {258})
add("PRIEST", "spender", {335467}, {258})
add("PRIEST", "dot", {589,34914})
add("PRIEST", "execute", {32379})
add("PRIEST", "core", {585})
add("PRIEST", "burst", {228260,391109}, {258})
add("DEATHKNIGHT", "interrupt", {47528})
add("DEATHKNIGHT", "pull", {49576,108199})
add("DEATHKNIGHT", "mobility", {48265,212552})
add("DEATHKNIGHT", "water_walk", {3714})
add("DEATHKNIGHT", "defensive", {48792,48707,55233,49039})
add("DEATHKNIGHT", "stun", {221562,108194})
add("DEATHKNIGHT", "taunt", {56222})
add("DEATHKNIGHT", "resurrect", {61999})
add("DEATHKNIGHT", "spender", {49998}, {250})
add("DEATHKNIGHT", "heal", {49998}, {251,252})
-- Same spell can have a different function by spec; stored below as variants.
MM.catalog[49998].variants = {[250]="mitigation", [251]="heal", [252]="heal"}
MM.catalog[49998].specs = nil
add("DEATHKNIGHT", "builder", {49020}, {251})
add("DEATHKNIGHT", "spender", {49143}, {251})
add("DEATHKNIGHT", "aoe_builder", {49184}, {251})
add("DEATHKNIGHT", "builder", {55090,85948}, {252})
add("DEATHKNIGHT", "spender", {47541}, {252})
add("DEATHKNIGHT", "aoe_spender", {207317}, {252})
add("DEATHKNIGHT", "builder", {195182,206930}, {250})
add("DEATHKNIGHT", "aoe_builder", {50842}, {250})
add("DEATHKNIGHT", "aoe", {43265})
add("DEATHKNIGHT", "burst", {51271,47568}, {251})
add("DEATHKNIGHT", "burst", {63560,275699,42650}, {252})
add("SHAMAN", "interrupt", {57994})
add("SHAMAN", "mobility", {2645,192063,58875})
add("SHAMAN", "defensive", {108271})
add("SHAMAN", "stun", {192058,51514})
add("SHAMAN", "cleanse", {370,51886,77130})
add("SHAMAN", "resurrect", {2008})
add("SHAMAN", "heal", {8004,77472,1064,61295})
add("SHAMAN", "buff", {2825,32182})
add("SHAMAN", "builder", {188196,51505}, {262})
add("SHAMAN", "spender", {8042}, {262})
add("SHAMAN", "aoe_spender", {61882}, {262})
add("SHAMAN", "aoe_builder", {188443}, {262})
add("SHAMAN", "core", {17364,60103,193796}, {263})
add("SHAMAN", "dot", {188389})
add("SHAMAN", "burst", {114050,114051,51533})
add("MAGE", "interrupt", {2139})
add("MAGE", "mobility", {1953,212653})
add("MAGE", "immunity", {45438})
add("MAGE", "defensive", {11426,235313,235450,342245})
add("MAGE", "stun", {118,31661,122})
add("MAGE", "cleanse", {475,30449})
add("MAGE", "buff", {1459,80353})
add("MAGE", "builder", {30451}, {62})
add("MAGE", "spender", {44425}, {62})
add("MAGE", "aoe_builder", {1449}, {62})
add("MAGE", "builder", {133,108853}, {63})
add("MAGE", "spender", {11366}, {63})
add("MAGE", "aoe_spender", {2120}, {63})
add("MAGE", "builder", {116}, {64})
add("MAGE", "spender", {30455}, {64})
add("MAGE", "core", {44614}, {64})
add("MAGE", "aoe", {190356,84714}, {64})
add("MAGE", "burst", {12042,365350,190319,12472})
add("WARLOCK", "interrupt", {19647,119910})
add("WARLOCK", "mobility", {48020,111771})
add("WARLOCK", "defensive", {104773,108416})
add("WARLOCK", "stun", {30283,5782,6789})
add("WARLOCK", "resurrect", {20707})
add("WARLOCK", "builder", {686,232670}, {265,266})
add("WARLOCK", "builder", {29722,17962}, {267})
add("WARLOCK", "spender", {324536}, {265})
add("WARLOCK", "aoe_spender", {27243}, {265})
add("WARLOCK", "spender", {105174}, {266})
add("WARLOCK", "spender", {116858}, {267})
add("WARLOCK", "aoe_spender", {5740}, {267})
add("WARLOCK", "core", {104316}, {266})
add("WARLOCK", "dot", {172,980,30108,348})
add("WARLOCK", "burst", {1122,265187,205180})
add("MONK", "interrupt", {116705})
add("MONK", "mobility", {109132,115008,101545,119996})
add("MONK", "defensive", {115203,122278,122783,122470})
add("MONK", "stun", {119381,115078})
add("MONK", "cleanse", {115450,218164})
add("MONK", "taunt", {115546})
add("MONK", "resurrect", {115178})
add("MONK", "heal", {116670,115151,124682})
add("MONK", "builder", {100780}, {269})
add("MONK", "spender", {100784,107428,113656}, {269})
add("MONK", "aoe_spender", {101546}, {269})
add("MONK", "core", {121253,100784}, {268})
MM.catalog[100784].variants = {[269]="spender", [268]="core", [270]="core"}
MM.catalog[100784].specs = nil
add("MONK", "aoe", {115181}, {268})
add("MONK", "burst", {137639,123904})
add("DRUID", "interrupt", {106839,78675})
add("DRUID", "mobility", {1850,106898,102401})
add("DRUID", "defensive", {22812,61336,22842,102342})
add("DRUID", "stun", {5211,22570,99})
add("DRUID", "cleanse", {2782,88423,2908})
add("DRUID", "resurrect", {20484,50769})
add("DRUID", "heal", {8936,774,18562,33763,48438})
add("DRUID", "buff", {1126})
add("DRUID", "taunt", {6795})
add("DRUID", "builder", {5176,194153}, {102})
add("DRUID", "spender", {78674}, {102})
add("DRUID", "aoe_spender", {191034}, {102})
add("DRUID", "builder", {5221,1822}, {103})
add("DRUID", "spender", {22568}, {103})
add("DRUID", "dot", {1079}, {103})
add("DRUID", "aoe_builder", {106830,106785}, {103})
add("DRUID", "builder", {33917}, {104})
add("DRUID", "spender", {6807}, {104})
add("DRUID", "mitigation", {192081}, {104})
add("DRUID", "dot", {8921,93402})
add("DRUID", "burst", {102560,194223,106951,102543})
add("DEMONHUNTER", "interrupt", {183752})
add("DEMONHUNTER", "mobility", {195072,198793,189110})
add("DEMONHUNTER", "defensive", {198589,204021,203720})
add("DEMONHUNTER", "immunity", {196555})
add("DEMONHUNTER", "stun", {179057,202137,207684})
add("DEMONHUNTER", "taunt", {185245})
add("DEMONHUNTER", "builder", {162243,232893}, {577})
add("DEMONHUNTER", "spender", {162794}, {577})
add("DEMONHUNTER", "aoe_spender", {188499}, {577})
add("DEMONHUNTER", "aoe", {198013,258920})
add("DEMONHUNTER", "builder", {203782}, {581})
add("DEMONHUNTER", "spender", {228477,247454}, {581})
add("DEMONHUNTER", "burst", {191427,187827})
add("EVOKER", "interrupt", {351338})
add("EVOKER", "mobility", {358267,370665})
add("EVOKER", "defensive", {363916,374348})
add("EVOKER", "stun", {357214,368970})
add("EVOKER", "cleanse", {365585,360823,374251})
add("EVOKER", "resurrect", {361227})
add("EVOKER", "heal", {361469,355913,364343,366155})
add("EVOKER", "buff", {364342,390386})
add("EVOKER", "builder", {361469}, {1467})
MM.catalog[361469].variants = {[1467]="builder", [1468]="heal", [1473]="core"}
MM.catalog[361469].specs = nil
add("EVOKER", "spender", {356995}, {1467})
add("EVOKER", "aoe_spender", {357211}, {1467})
add("EVOKER", "core", {357208,359073}, {1467})
add("EVOKER", "spender", {395160}, {1473})
add("EVOKER", "core", {396286}, {1473})
add("EVOKER", "burst", {375087}, {1467})
add("EVOKER", "buff", {395152,409311}, {1473})

-- Functional profiles use effect scope, NOT the spell's own damage school.
-- No tuning numbers are hardcoded. Multiple effects remain distinct capabilities.
MM.schools = {physical="física", magic="mágica", all="geral"}
MM.mechanisms = {reduction="redução", absorb="absorção", avoidance="esquiva / aparo",
    armor="armadura", immunity="imunidade", reflect="reflexão", resistance="resistência",
    health="vida e cura recebida", recovery="recuperação de vida", cheat_death="evitar morte",delay="adiamento de dano"}
MM.recipients = {self="pessoal", friendly="alvo aliado", group="grupo"}
local function protection(school, mechanism, recipient, cadence, coverage)
    return {school=school,mechanism=mechanism,recipient=recipient or "self",
        cadence=cadence or "cooldown",coverage=coverage or "damage"}
end
local function profile(ids, role, defenses, traits)
    for _,id in ipairs(ids) do
        local entry=MM.catalog[id]
        if entry then
            if role then entry.role=role end
            entry.defenses=defenses
            entry.traits=traits
        end
    end
end
profile({871,184364,498,31850,86659,403876,264735,47585,48792,108271,104773,115203,
    122278,22812,61336,198589,363916},"defensive",{protection("all","reduction")})
profile({118038},"defensive",{protection("physical","avoidance",nil,nil,"attacks"),protection("all","reduction")})
profile({23920},"defensive",{protection("magic","reflect",nil,nil,"spells"),protection("magic","reduction")})
profile({2565},nil,{protection("physical","avoidance",nil,"active","attacks")})
profile({190456},nil,{protection("all","absorb",nil,"active")})
profile({53600,192081},nil,{protection("physical","armor",nil,"active")})
profile({5277},"defensive",{protection("physical","avoidance",nil,nil,"attacks")})
profile({1966},"defensive",{protection("all","reduction",nil,"active","area")})
profile({48707},"defensive",{protection("magic","absorb")},{prevents_magic_effects=true})
profile({122783},"defensive",{protection("magic","reduction")},{dispel_magic=true})
profile({11426,235313,235450,108416},"defensive",{protection("all","absorb")})
profile({33206,102342},"defensive",{protection("all","reduction","friendly")})
profile({203720},"defensive",{protection("physical","armor",nil,"active"),protection("physical","avoidance",nil,"active","attacks")})
profile({204021},"defensive",{protection("all","reduction")})
profile({55233},"defensive",{protection("all","health")})
profile({47788},"defensive",{protection("all","cheat_death","friendly")})
profile({342245},"defensive",{protection("all","recovery")})
-- Turtle avoids incoming attacks; existing damage effects still matter. It is not full immunity.
profile({186265},"defensive",{protection("all","avoidance",nil,nil,"attacks"),protection("all","reduction")},{no_attack=true})
profile({31224},"defensive",{protection("magic","resistance",nil,nil,"spells")},{dispel_magic=true})
profile({642,45438,196555},"immunity",{protection("all","immunity")})
profile({1022},"immunity",{protection("physical","immunity","friendly")})
add("PALADIN","immunity",{204018},{66})
profile({204018},"immunity",{protection("magic","immunity","friendly")})
profile({22842},"heal",nil,{recipient="self",delivery="hot"})
profile({34428,202168,109304,185311},nil,nil,{recipient="self",delivery="direct"})
profile({49998},nil,nil,{recipient="self",delivery="direct"})
MM.catalog[49998].defenseVariants={[250]={protection("all","recovery",nil,"active")}}
profile({122470},"defensive",{protection("all","absorb")},{damage_redirect=true})
-- Defensive-looking health restoration/buffs are not automatically damage reducers.
profile({49039},"buff",nil,{recipient="self",utility="control_break"})
profile({374348},"heal",nil,{recipient="self",delivery="delayed"})
profile({139,774,115151,124682,61295,33763},nil,nil,{recipient="friendly",delivery="hot"})
profile({19750,85673,633,82326,2061,2060,2050,8004,77472,116670,8936,18562,361469,364343,366155},nil,nil,{recipient="friendly",delivery="direct"})
profile({1064,85222,48438,355913},nil,nil,{recipient="friendly",delivery="area"})
profile({853,408,1833,119381,5211,46968,107570,19577,109248,64044,221562,108194,192058,30283,179057},nil,nil,{control="stun"})
profile({2094,31661,99,207684},nil,nil,{control="disorient"})
profile({8122,5782,6789},nil,nil,{control="fear"})
profile({118,51514,115078,187650},nil,nil,{control="incapacitate"})
profile({122},nil,nil,{control="root"})
profile({202137},"interrupt",nil,{control="silence"})
profile({100,190925},nil,nil,{movement="gap_closer"})
profile({6544,109132,115008,195072,189110},nil,nil,{movement="displacement"})
profile({1953,212653,36554,195457,119996,48020},nil,nil,{movement="teleport"})
profile({48265,212552,2983,186257,2645,58875,1850,106898,190784,358267},nil,nil,{movement="speed"})

function MM:RoleLabel(spell)
    if not spell then return self.roles.unknown end
    local purposeLabel=self.PurposeLabel and self:PurposeLabel(spell)
    if purposeLabel then return purposeLabel end
    local defense=spell.defenses and spell.defenses[1]
    if defense then
        local prefix=defense.mechanism == "immunity" and "Imunidade " or "Defesa "
        local result=prefix..(self.schools[defense.school] or "não classificada")
        if defense.mechanism ~= "immunity" then result=result.." · "..(self.mechanisms[defense.mechanism] or defense.mechanism) end
        if defense.recipient == "friendly" then result=result.." · aliado" end
        return result
    end
    local result=self.roles[spell.role] or self.roles.unknown
    local traits=spell.traits or {}
    local detail=({stun="atordoar",fear="medo",root="enraizar",incapacitate="incapacitar",disorient="desorientar",silence="silenciar",knockback="empurrar",knockup="lançar ao ar"})[traits.control]
        or ({self="pessoal",friendly="aliado"})[traits.recipient]
        or ({gap_closer="aproximação",displacement="deslocamento",teleport="teleporte",speed="velocidade"})[traits.movement]
    if not detail and spell.rotation then
        detail=({core="recorrente",filler="preenchimento",reactive="reativo",maintenance="manutenção",
            short_cooldown="cooldown curto",major="janela ofensiva",execute="execução"})[spell.rotation.rhythm]
    end
    return result..(detail and " · "..detail or "")
end

function MM:FunctionDetails(spell)
    local details=self.UsageDetails and self:UsageDetails(spell) or {}
    for _,defense in ipairs(spell.defenses or {}) do
        details[#details+1]=(self.schools[defense.school] or defense.school).." · "..
            (self.mechanisms[defense.mechanism] or defense.mechanism).." · "..
            (self.recipients[defense.recipient] or defense.recipient)
    end
    local traits=spell.traits or {}
    if traits.no_attack then details[#details+1]="Impede atacar enquanto está ativo." end
    if traits.prevents_magic_effects then details[#details+1]="Também previne a aplicação de efeitos mágicos." end
    if traits.dispel_magic then details[#details+1]="Também remove ou devolve efeitos mágicos." end
    if spell.rotation then
        details[#details+1]="Na rotação: "..spell.rotation.description
        local source=self.rotationSources[spell.rotation.source]
        if source then
            details[#details+1]="Fonte: "..source.publisher.." · patch "..source.patch.." · consulta "..source.checked
            details[#details+1]=source.url
        end
    end
    if spell.assistedRotation then details[#details+1]="Incluída na rotação assistida deste perfil; não indica prioridade." end
    if spell.isAssistant then details[#details+1]="Botão nativo de assistência de dano; não é uma habilidade individual nem uma rotação de cura." end
    return details
end

function MM:Class(token)
    for _, class in ipairs(self.classes) do
        if class.token == token then return class end
    end
end

function MM:CatalogEntry(id, class, spec)
    local entry = self.catalog[id]
    if not entry or entry.class and entry.class ~= class then return end
    if entry.specs then
        local found = false
        for _, allowed in ipairs(entry.specs) do if allowed == spec then found = true end end
        if not found then return end
    end
    local role = entry.variants and entry.variants[spec] or entry.role
    local result={id=id,class=class,role=role,curated=true}
    for _,field in ipairs({"defenses","traits"}) do
        local values=field == "defenses" and entry.defenseVariants and entry.defenseVariants[spec] or entry[field]
        if values then
            result[field]={}
            for key,value in pairs(values) do
                if type(value) == "table" then
                    local copy={}; for k,v in pairs(value) do copy[k]=v end
                    result[field][key]=copy
                else result[field][key]=value end
            end
        end
    end
    -- Hybrid spells only use healing traits when their current spec role is healing.
    if result.traits and role ~= "heal" and role ~= "mitigation" then
        result.traits.recipient=nil; result.traits.delivery=nil
    end
    if self.ApplyRotationProfile then self:ApplyRotationProfile(result,class,spec) end
    if self.ApplyPurposeProfile then self:ApplyPurposeProfile(result,class,spec) end
    return result
end

function MM:RefreshClassification(spell,class,spec)
    spell.class,spell.functions=class,nil
    if spell.isAssistant then spell.role,spell.curated="assisted",true; return spell end
    local entry=self:CatalogEntry(spell.id,class,spec) or (spell.baseID and self:CatalogEntry(spell.baseID,class,spec))
    if entry then
        spell.role,spell.curated,spell.defenses,spell.traits=entry.role,entry.curated,entry.defenses,entry.traits
        spell.rotation,spell.purpose,spell.racial=entry.rotation,entry.purpose,entry.racial
    elseif self.ApplyPurposeProfile then
        -- Keep removal/spec notes for historical captured buttons even when the
        -- corrected catalogue no longer offers them in this specialization.
        self:ApplyPurposeProfile(spell,class,spec)
    end
    return spell
end
