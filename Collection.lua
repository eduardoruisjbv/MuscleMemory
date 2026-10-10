local _, MM = ...

local function jsonString(value)
    return '"' .. tostring(value):gsub('[%z\1-\31\\"]', function(char)
        local escapes = {['\\']='\\\\', ['"']='\\"', ['\b']='\\b', ['\f']='\\f', ['\n']='\\n', ['\r']='\\r', ['\t']='\\t'}
        return escapes[char] or string.format('\\u%04x', char:byte())
    end) .. '"'
end

local function isArray(value)
    local count, max = 0, 0
    for key in pairs(value) do
        if type(key) ~= 'number' or key < 1 or key % 1 ~= 0 then return false end
        count, max = count + 1, math.max(max, key)
    end
    return count == max
end

local function encodeJSON(value)
    local kind = type(value)
    if value == nil then return 'null' end
    if kind == 'boolean' then return value and 'true' or 'false' end
    if kind == 'number' then
        if value ~= value or value == math.huge or value == -math.huge then return 'null' end
        return tostring(value)
    end
    if kind == 'string' then return jsonString(value) end
    if kind ~= 'table' then return 'null' end

    local items = {}
    if isArray(value) then
        for index = 1, #value do items[#items + 1] = encodeJSON(value[index]) end
        return '[' .. table.concat(items, ',') .. ']'
    end
    local keys = {}
    for key in pairs(value) do if type(key) == 'string' then keys[#keys + 1] = key end end
    table.sort(keys)
    for _, key in ipairs(keys) do items[#items + 1] = jsonString(key) .. ':' .. encodeJSON(value[key]) end
    return '{' .. table.concat(items, ',') .. '}'
end

local function abilitySnapshot(spell)
    local purpose = spell.purpose or {}
    return {
        spellID=spell.id, baseSpellID=spell.baseID, name=spell.name, icon=spell.icon,
        role=spell.role, primaryPurpose=purpose.primary, cadence=purpose.cadence,
        curated=spell.curated == true,
        reviewNeeded=spell.curated ~= true or not spell.role or spell.role == 'unknown',
        learned=spell.learned == true,
        talent=spell.talent == true, talentSelected=spell.talentSelected == true,
        talentNodeID=spell.talentNodeID, talentEntryID=spell.talentEntryID,
        passive=spell.isPassive == true or spell.passive == true,
    }
end

function MM:StoreCollectionSnapshot()
    if not self.db or not self.db.collection or not self.db.collection.enabled or not self.current then return end
    local abilities = {}
    for _, spell in pairs(self.current.spells or {}) do
        if not spell.isPassive and not spell.passive then abilities[#abilities + 1] = abilitySnapshot(spell) end
    end
    table.sort(abilities, function(a, b)
        if (a.spellID or 0) == (b.spellID or 0) then return (a.name or '') < (b.name or '') end
        return (a.spellID or 0) < (b.spellID or 0)
    end)

    self.db.collection.characters[self.current.key] = {
        character=self.current.name, class=self.current.class, classID=self.current.classID,
        specialization=self.current.spec, specializationName=self.current.specName,
        race=self.current.race, raceID=self.current.raceID, level=UnitLevel('player'),
        clientVersion=GetBuildInfo and select(1, GetBuildInfo()) or nil,
        updated=self.current.updated, abilities=abilities,
    }
end

function MM:SetCollectionEnabled(enabled)
    self.db.collection.enabled = enabled == true
    if enabled then
        if self.current then self:StoreCollectionSnapshot() end
        self:Print('Coleta ativada neste computador. Os dados ficam locais; use /mm export para copiá-los.')
    else
        self:Print('Coleta desativada. Os dados já coletados continuam salvos localmente.')
    end
end

function MM:ToggleCollection()
    self:SetCollectionEnabled(not self.db.collection.enabled)
end

function MM:PrintCollectionStatus()
    local count = 0
    for _ in pairs(self.db.collection.characters) do count = count + 1 end
    self:Print(('Coleta %s; %d perfil(is) local(is). Use /mm export para exportar.'):format(
        self.db.collection.enabled and 'ativada' or 'desativada', count))
end

function MM:ClearCollection()
    self.db.collection.characters = {}
    self:Print('Dados coletados foram apagados deste computador.')
end

function MM:ShowCollectionExport()
    local profiles = {}
    for _, profile in pairs(self.db.collection.characters) do profiles[#profiles + 1] = profile end
    table.sort(profiles, function(a, b)
        local left = (a.character or '') .. ':' .. tostring(a.specialization or 0)
        local right = (b.character or '') .. ':' .. tostring(b.specialization or 0)
        return left < right
    end)
    if #profiles == 0 then
        self:Print('Ainda não há dados. Ative /mm collect e entre nos personagens que deseja coletar.')
        return
    end

    local frame = _G.MuscleMemoryCollectionExport
    if not frame then
        frame = CreateFrame('Frame', 'MuscleMemoryCollectionExport', UIParent, 'BasicFrameTemplateWithInset')
        frame:SetSize(620, 470)
        frame:SetPoint('CENTER')
        frame:SetFrameStrata('DIALOG')
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag('LeftButton')
        frame:SetScript('OnDragStart', frame.StartMoving)
        frame:SetScript('OnDragStop', frame.StopMovingOrSizing)
        frame.TitleText:SetText('MuscleMemory — exportar coleta')

        local instructions = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
        instructions:SetPoint('TOPLEFT', 16, -34)
        instructions:SetPoint('TOPRIGHT', -16, -34)
        instructions:SetJustifyH('LEFT')
        instructions:SetText('Selecione e copie o JSON. Salve como .json para enviar ao autor. O arquivo não é enviado automaticamente.')

        local scroll = CreateFrame('ScrollFrame', nil, frame, 'UIPanelScrollFrameTemplate')
        scroll:SetPoint('TOPLEFT', 16, -70)
        scroll:SetPoint('BOTTOMRIGHT', -34, 54)
        local edit = CreateFrame('EditBox', nil, scroll)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(false)
        edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(550)
        edit:SetScript('OnEscapePressed', function(box) box:ClearFocus() end)
        scroll:SetScrollChild(edit)
        frame.exportEdit = edit
        frame.exportScroll = scroll

        local selectButton = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
        selectButton:SetSize(120, 24)
        selectButton:SetPoint('BOTTOMLEFT', 16, 16)
        selectButton:SetText('Selecionar tudo')
        selectButton:SetScript('OnClick', function()
            frame.exportEdit:SetFocus()
            frame.exportEdit:HighlightText()
        end)
        local closeButton = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
        closeButton:SetSize(90, 24)
        closeButton:SetPoint('BOTTOMRIGHT', -16, 16)
        closeButton:SetText('Fechar')
        closeButton:SetScript('OnClick', function() frame:Hide() end)
    end

    local data = {format='MuscleMemoryCollection', schema=1, exportedAt=time(), characters=profiles}
    frame.exportEdit:SetText(encodeJSON(data))
    frame.exportEdit:SetCursorPosition(0)
    frame:Show()
end
