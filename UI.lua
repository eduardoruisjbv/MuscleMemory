local _, MM = ...
local colors = {
    bg={0.055,0.06,0.065,0.98}, panel={0.09,0.10,0.11,1}, row={0.115,0.125,0.135,1},
    text={0.93,0.90,0.83,1}, muted={0.66,0.68,0.67,1}, teal={0.29,0.82,0.75,1},
    amber={0.94,0.69,0.35,1}, border={0.27,0.28,0.27,1}, selected={0.12,0.22,0.22,1},
}
local QUESTION = 134400
local WHITE = "Interface\\Buttons\\WHITE8X8"
local ROW_HEIGHT, PALETTE_HEIGHT = 96, 62

local function panel(parent,width,height,name)
    local frame=CreateFrame("Frame",name,parent,"BackdropTemplate")
    frame:SetSize(width,height)
    frame:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1})
    frame:SetBackdropColor(unpack(colors.panel))
    frame:SetBackdropBorderColor(unpack(colors.border))
    return frame
end

local function label(parent,text,x,y,width,font)
    local value=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
    value:SetPoint("TOPLEFT",x,y)
    if width then value:SetWidth(width) end
    value:SetJustifyH("LEFT")
    value:SetTextColor(unpack(colors.text))
    value:SetText(text)
    return value
end

local function hint(owner,title,detail)
    GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
    GameTooltip:AddLine(title,colors.text[1],colors.text[2],colors.text[3])
    if detail then GameTooltip:AddLine(detail,0.66,0.68,0.67,true) end
    GameTooltip:Show()
end

local function button(parent,text,x,y,width,callback,primary)
    local value=CreateFrame("Button",nil,parent,"BackdropTemplate")
    value:SetSize(width,30)
    value:SetPoint("TOPLEFT",x,y)
    value:SetNormalTexture("")
    value:SetPushedTexture("")
    value:SetDisabledTexture("")
    value:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    value:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1})
    value:SetBackdropColor(unpack(primary and colors.selected or colors.row))
    value:SetBackdropBorderColor(unpack(primary and colors.teal or colors.border))
    value.caption=label(value,text,8,-8,width-16,"GameFontNormal")
    value.caption:SetJustifyH("CENTER")
    value.caption:SetMaxLines(1)
    value.SetText=function(_,newText) value.caption:SetText(newText) end
    value:SetScript("OnClick",callback)
    if value.SetMotionScriptsWhileDisabled then value:SetMotionScriptsWhileDisabled(true) end
    value:SetScript("OnEnter",function()
        value:SetBackdropBorderColor(unpack(colors.teal))
        if value.tip then hint(value,value.caption:GetText() or text,value.tip) end
    end)
    value:SetScript("OnLeave",function()
        value:SetBackdropBorderColor(unpack(primary and colors.teal or colors.border))
        GameTooltip:Hide()
    end)
    return value
end

local function enabled(control,allowed,reason)
    control:SetEnabled(not not allowed)
    if control.caption then control.caption:SetTextColor(unpack(allowed and colors.text or colors.muted)) end
    control.tip=reason
end

local function scroll(parent,x,y,width,height)
    local frame=CreateFrame("ScrollFrame",nil,parent,"UIPanelScrollFrameTemplate")
    frame:SetPoint("TOPLEFT",x,y)
    frame:SetSize(width-24,height)
    local child=CreateFrame("Frame",nil,frame)
    child:SetSize(width-24,1)
    frame:SetScrollChild(child)
    return frame,child
end

local function roleLabel(spell)
    if MM.RoleLabel then return MM:RoleLabel(spell) end
    return MM.roles[spell.role] or "Unclassified"
end

local function searchMatches(spell,search)
    search=(search or ""):lower()
    return search == "" or (spell.name or ""):lower():find(search,1,true)
        or roleLabel(spell):lower():find(search,1,true) or tostring(spell.id):find(search,1,true)
end

local function sortedSpells(spells,search)
    local list={}
    for _,spell in pairs(spells or {}) do
        if searchMatches(spell,search) and (not MM.ui.roleFilter or MM.ui.roleFilter == roleLabel(spell)) then
            list[#list+1]=spell
        end
    end
    table.sort(list,function(a,b)
        local ar,br=roleLabel(a),roleLabel(b)
        if ar ~= br then return ar<br end
        return (a.name or tostring(a.id))<(b.name or tostring(b.id))
    end)
    return list
end

local function bindings(slots,reference)
    local list,seen={},{}
    for _,slot in ipairs(slots or {}) do
        local text=MM.GetBindingForSlot and MM:GetBindingForSlot(slot,reference) or "No keybinding"
        if text and text ~= "No keybinding" and not seen[text] then list[#list+1]=text; seen[text]=true end
    end
    return #list>0 and table.concat(list," / ") or "No keybinding"
end

local function technicalSlots(slots)
    local list={}
    for _,slot in ipairs(slots or {}) do list[#list+1]=tostring(slot) end
    return "Technical slots: "..table.concat(list,", ")
end

function MM:Menu(anchor,options)
    if self.menu then self.menu:Hide() end
    local popup=self.menu
    if not popup then
        popup=panel(self.ui,290,320)
        popup.scroll,popup.child=scroll(popup,8,-8,274,304)
        popup.buttons={}
        self.menu=popup
    end
    popup:SetSize(math.max(anchor:GetWidth(),290),math.min(#options*34+16,320))
    popup:ClearAllPoints()
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(self.ui:GetFrameLevel()+30)
    popup:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,-4)
    local scroller,child=popup.scroll,popup.child
    scroller:SetSize(popup:GetWidth()-40,popup:GetHeight()-16)
    scroller:SetVerticalScroll(0)
    child:SetWidth(popup:GetWidth()-40)
    for index,option in ipairs(options) do
        local value=popup.buttons[index] or button(child,"",0,-(index-1)*34,child:GetWidth(),function() end)
        popup.buttons[index]=value
        value:SetWidth(child:GetWidth())
        value.caption:SetWidth(child:GetWidth()-16)
        value:SetText(option.text)
        value:SetScript("OnClick",function() popup:Hide(); option.action() end)
        enabled(value,not option.disabled,option.reason)
        value:Show()
    end
    for index=#options+1,#popup.buttons do popup.buttons[index]:Hide() end
    child:SetHeight(math.max(1,#options*34))
    popup:Show()
end

function MM:SpecOptions(class)
    local entry=self:Class(class)
    local count=(C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID)
        and C_SpecializationInfo.GetNumSpecializationsForClassID(entry.id) or #entry.specs
    local list={}
    for index=1,count do
        local id,name=self:SpecInfo(index,entry.id)
        if id and id ~= 0 then list[#list+1]={id=id,name=name or tostring(id)} end
    end
    if #list == 0 then
        for _,id in ipairs(entry.specs) do list[#list+1]={id=id,name="Specialization #"..id} end
    end
    return list
end

function MM:SpecName(class,spec)
    for _,entry in ipairs(self:SpecOptions(class)) do if entry.id == spec then return entry.name end end
    return "Specialization #"..(spec or 0)
end

function MM:ClassMenu(anchor,side)
    local options={}
    for _,entry in ipairs(self.classes) do
        local class=entry
        options[#options+1]={text=class.name,action=function()
            local settings=self:Settings()
            if side == "source" then
                settings.sourceClass=class.token
                settings.sourceKey=nil
                local newest
                for key,reference in pairs(self.db.references) do
                    if reference.class == class.token and (not newest or reference.captured>newest) then
                        settings.sourceKey=key
                        newest=reference.captured
                    end
                end
            else
                settings.targetClass=class.token
                local specs=self:SpecOptions(class.token)
                settings.targetSpec=specs[1] and specs[1].id or 0
            end
            self:DisableAutomatic()
            self.selectedSource=nil
            self:StopDrag()
            if self.ui.preview then self.ui.preview:Hide() end
            self:RefreshUI()
        end}
    end
    self:Menu(anchor,options)
end

function MM:ReferenceMenu(anchor)
    local settings=self:Settings()
    local reference=self.db.references[settings.sourceKey]
    local class=reference and reference.class or settings.sourceClass or self.current.class
    local options={}
    for key,value in pairs(self:ReferenceOptions(class)) do
        if value.class == class then
            local profileKey=key
            options[#options+1]={text=value.name.." / "..value.specName..(not value.actions and " · sem captura" or ""),
                disabled=not value.actions,reason=value.name.." / "..value.specName..(not value.actions
                    and " — log in to this character and save its bars; this version also records bars visited outside automatic mode."
                    or " — this character and realm’s individual reference."),action=function()
                settings.sourceKey=profileKey
                self:DisableAutomatic()
                self.selectedSource=nil
                self:StopDrag()
                if self.ui.preview then self.ui.preview:Hide() end
                self:RefreshUI()
            end}
        end
    end
    table.sort(options,function(a,b) return a.text<b.text end)
    if #options == 0 then
        options[1]={text="Log in to your main and capture its bars",action=function() end}
    end
    self:Menu(anchor,options)
end

function MM:TargetSpecMenu(anchor)
    local settings=self:Settings()
    local options={}
    for _,entry in ipairs(self:SpecOptions(settings.targetClass)) do
        local spec=entry
        options[#options+1]={text=spec.name,action=function()
            settings.targetSpec=spec.id
            self:DisableAutomatic()
            self.selectedSource=nil
            self:StopDrag()
            if self.ui.preview then self.ui.preview:Hide() end
            self:RefreshUI()
        end}
    end
    self:Menu(anchor,options)
end

local function tooltip(value)
    GameTooltip:SetOwner(value,"ANCHOR_RIGHT")
    if value.spell then
        if value.spell.action then
            if value.spell.action.kind=="summonmount" and value.spell.spellID and GameTooltip.SetMountBySpellID then
                GameTooltip:SetMountBySpellID(value.spell.spellID)
            elseif value.spell.action.kind=="item" then GameTooltip:SetItemByID(value.spell.action.id)
            else GameTooltip:AddLine(value.spell.name or "Utility",0.93,0.90,0.83) end
        else GameTooltip:SetSpellByID(value.spell.id) end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(roleLabel(value.spell),0.29,0.82,0.75)
        if MM.FunctionDetails then
            for _,detail in ipairs(MM:FunctionDetails(value.spell) or {}) do
                GameTooltip:AddLine(detail,0.66,0.68,0.67,true)
            end
        end
    else
        GameTooltip:AddLine(value.emptyTitle or "Not configured",0.93,0.90,0.83)
    end
    if value.note then GameTooltip:AddLine(value.note,0.66,0.68,0.67,true) end
    GameTooltip:Show()
end

local function icon(parent,size)
    local value=CreateFrame("Button",nil,parent,"BackdropTemplate")
    value:SetSize(size,size)
    value:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1})
    value:SetBackdropColor(0.045,0.05,0.055,1)
    value:SetBackdropBorderColor(unpack(colors.border))
    value.texture=value:CreateTexture(nil,"ARTWORK")
    value.texture:SetPoint("TOPLEFT",3,-3)
    value.texture:SetPoint("BOTTOMRIGHT",-3,3)
    value.texture:SetTexCoord(0.08,0.92,0.08,0.92)
    value:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    value:RegisterForClicks("LeftButtonUp","RightButtonUp")
    value:RegisterForDrag("LeftButton")
    value:SetScript("OnEnter",tooltip)
    value:SetScript("OnLeave",function() GameTooltip:Hide() end)
    return value
end

local function animateOpening(frame)
    -- Blizzard animation groups tick only during this short transition; no polling script.
    if not frame.CreateAnimationGroup then return end
    local group=frame:CreateAnimationGroup()
    if not group or not group.CreateAnimation then return end
    local alpha=group:CreateAnimation("Alpha")
    if not alpha then return end
    alpha:SetFromAlpha(0.7)
    alpha:SetToAlpha(1)
    alpha:SetDuration(0.12)
    group:SetScript("OnFinished",function() frame:SetAlpha(1) end)
    frame.openAnimation=group
    frame:SetScript("OnShow",function() group:Stop(); group:Play() end)
end

function MM:RoleFilterMenu(anchor)
    local reference,targets=self:Context()
    local found={}
    for _,spell in pairs(reference and reference.spells or {}) do found[roleLabel(spell)]=true end
    for _,spell in pairs(targets or {}) do found[roleLabel(spell)]=true end
    local labels={}
    for value in pairs(found) do labels[#labels+1]=value end
    table.sort(labels)
    local options={{text="All purposes",action=function() self.ui.roleFilter=nil; self:RefreshUI() end}}
    for _,value in ipairs(labels) do
        local choice=value
        options[#options+1]={text=choice,action=function() self.ui.roleFilter=choice; self:RefreshUI() end}
    end
    self:Menu(anchor,options)
end

function MM:StartDrag(side,spell)
    if not spell then return end
    if InCombatLockdown() then return self:Print("Edit mappings out of combat.") end
    if GetCursorInfo() then return end
    self.drag={side=side,id=spell.id}
    SetCursor("CAST_CURSOR")
    if side == "source" then self.selectedSource=spell.id end
    self.ui.feedback:SetText(side == "target" and "Drop onto the destination for the mapping you want." or "Choose an ability in the destination column.")
    self.ui.feedback:SetTextColor(unpack(colors.teal))
    self:RefreshSelection()
end

function MM:StopDrag()
    self.drag=nil
    ResetCursor()
    if self.ui then self:RefreshSelection() end
end

function MM:FinishDrag()
    if self.drag and self.drag.side == "target" then
        for _,row in ipairs(self.ui.rows) do
            if row:IsShown() and (row.target:IsMouseOver() or row:IsMouseOver()) then
                self:DroppedTarget(row.sourceID)
                break
            end
        end
    elseif self.drag and self.drag.side == "source" then
        for _,value in ipairs(self.ui.targetChild.buttons or {}) do
            if value:IsShown() and (value:IsMouseOver() or value.icon:IsMouseOver()) then
                self:DropOnPalette("target",value.icon.spell)
                break
            end
        end
    end
    if self.drag then self:StopDrag() end
end

function MM:DropOnPalette(side,spell)
    if not spell or not self.drag or InCombatLockdown() then return end
    if side == "source" and self.drag.side == "target" then
        self:DroppedTarget(spell.id)
    elseif side == "target" and self.drag.side == "source" then
        self.selectedSource=self.drag.id
        self:SetMapping(self.drag.id,spell.id)
        self:StopDrag()
        self.ui.feedback:SetText("Mapping saved. Review the preview before applying.")
        self.ui.feedback:SetTextColor(unpack(colors.teal))
    end
end

function MM:DroppedTarget(sourceID)
    if InCombatLockdown() then self:StopDrag(); return self:Print("Edit mappings out of combat.") end
    local targetID
    if self.drag then
        if self.drag.side ~= "target" then return end
        targetID=self.drag.id
    else
        local kind,_,_,spellID=GetCursorInfo()
        if kind == "spell" then targetID=spellID end
    end
    if not targetID then return end
    local _,targets=self:Context()
    if not targets[targetID] then return self:Print("Choose an ability from the destination class and specialization.") end
    self.selectedSource=sourceID
    self:SetMapping(sourceID,targetID)
    if GetCursorInfo() then ClearCursor() end
    self:StopDrag()
    self.ui.feedback:SetText("Mapping saved. Review the preview before applying.")
    self.ui.feedback:SetTextColor(unpack(colors.teal))
end

function MM:RefreshSelection()
    if not self.ui then return end
    for _,row in ipairs(self.ui.rows) do
        local selected=row.sourceID == self.selectedSource
        row:SetBackdropBorderColor(unpack(selected and colors.teal or colors.border))
        row:SetBackdropColor(unpack(selected and colors.selected or colors.row))
        row.target:SetBackdropBorderColor(unpack(self.drag and self.drag.side == "target" and colors.teal or colors.border))
    end
    for _,value in ipairs(self.ui.sourceChild.buttons or {}) do
        value:SetBackdropBorderColor(unpack(value.icon.spell and value.icon.spell.id == self.selectedSource and colors.teal or colors.panel))
    end
    if not self.drag then
        local spell=self.ui.placed and self.ui.placed[self.selectedSource]
        self.ui.feedback:SetText(InCombatLockdown() and "Application is available after combat."
            or not self.ui.editing and "Suggestions are ready. Editing is optional."
            or spell and ("Selected:  "..(spell.name or tostring(spell.id))..". Choose a destination ability.")
            or "Click a source ability and a destination ability to adjust the mapping.")
        self.ui.feedback:SetTextColor(unpack(InCombatLockdown() and colors.amber or colors.muted))
    end
end

function MM:FillPalette(container,spells,side,search)
    container.buttons=container.buttons or {}
    local list=sortedSpells(spells,search)
    local reference=self.ui.reference
    for index,spell in ipairs(list) do
        local value=container.buttons[index]
        if not value then
            value=CreateFrame("Button",nil,container,"BackdropTemplate")
            value:SetSize(container:GetWidth(),PALETTE_HEIGHT-4)
            value:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1})
            value:SetBackdropColor(unpack(colors.panel))
            value:SetBackdropBorderColor(unpack(colors.panel))
            value.icon=icon(value,36)
            value.icon:SetPoint("TOPLEFT",5,-10)
            value.name=label(value,"",48,-7,value:GetWidth()-55,"GameFontHighlight")
            value.name:SetMaxLines(1)
            value.role=label(value,"",48,-25,value:GetWidth()-55)
            value.role:SetTextColor(unpack(colors.muted))
            value.role:SetMaxLines(1)
            value.binding=label(value,"",48,-42,value:GetWidth()-55)
            value.binding:SetTextColor(unpack(colors.teal))
            value.binding:SetMaxLines(1)
            value:RegisterForDrag("LeftButton")
            value:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            local function start() MM:StartDrag(side,value.icon.spell) end
            value:RegisterForClicks("LeftButtonUp","RightButtonUp")
            local function click(_,mouse)
                if MM:IsLevelingMode() then
                    if mouse=="RightButton" then MM:LevelingMenu(value,value.icon.spell)
                    else MM.ui.feedback:SetText("Right-click: priority, pin position, or exclude from leveling.") end
                    return
                end
                if side == "source" then
                    MM.selectedSource=value.icon.spell.id
                    MM:RefreshSelection()
                elseif InCombatLockdown() then MM:Print("Edit mappings out of combat.")
                elseif MM.selectedSource then
                    MM:SetMapping(MM.selectedSource,value.icon.spell.id)
                    MM.ui.feedback:SetText("Mapping saved. Review the preview before applying.")
                    MM.ui.feedback:SetTextColor(unpack(colors.teal))
                else
                    MM.ui.feedback:SetText("First select an ability in the source or mapping column.")
                    MM.ui.feedback:SetTextColor(unpack(colors.amber))
                end
            end
            value:SetScript("OnDragStart",start)
            value.icon:SetScript("OnDragStart",start)
            value:SetScript("OnDragStop",function() MM:FinishDrag() end)
            value.icon:SetScript("OnDragStop",function() MM:FinishDrag() end)
            value:SetScript("OnClick",click)
            value.icon:SetScript("OnClick",click)
            local function drop() MM:DropOnPalette(side,value.icon.spell) end
            value:SetScript("OnReceiveDrag",drop)
            value.icon:SetScript("OnReceiveDrag",drop)
            value:SetScript("OnMouseUp",function(_,mouse) if mouse == "LeftButton" then drop() end end)
            value.icon:SetScript("OnMouseUp",function(_,mouse) if mouse == "LeftButton" then drop() end end)
            value:SetScript("OnEnter",function() tooltip(value.icon) end)
            value:SetScript("OnLeave",function() GameTooltip:Hide() end)
            container.buttons[index]=value
        end
        value:SetPoint("TOPLEFT",0,-(index-1)*PALETTE_HEIGHT)
        value.icon.spell=spell
        value.icon.texture:SetTexture(spell.icon or QUESTION)
        value.name:SetText(spell.name or "#"..spell.id)
        value.role:SetText(roleLabel(spell))
        local slots=side == "source" and self.ui.grouped[spell.id] or self.ui.targetSlots[spell.id]
        value.binding:SetText(side == "source" and bindings(slots,reference)
            or self.ui.isCurrentTarget and ("Current: "..bindings(slots)) or "Select to map")
        value.icon.note=(side == "source" and "Captured keybinding: "..bindings(slots,reference)
            or "Click to map to the selected source; drag to create a mapping.")
            ..(slots and "\n"..technicalSlots(slots) or "")
        value:Show()
    end
    for index=#list+1,#container.buttons do container.buttons[index]:Hide() end
    container:SetHeight(math.max(1,#list*PALETTE_HEIGHT))
    return #list
end

function MM:CreateRow(index)
    local row=panel(self.ui.mappingChild,self.ui.mappingChild:GetWidth(),ROW_HEIGHT)
    row:SetPoint("TOPLEFT",0,-(index-1)*(ROW_HEIGHT+6))
    row:EnableMouse(true)
    row.role=label(row,"",12,-9,row:GetWidth()-166,"GameFontNormal")
    row.role:SetTextColor(unpack(colors.text))
    row.role:SetMaxLines(1)
    row.slots=label(row,"",row:GetWidth()-150,-9,138,"GameFontNormal")
    row.slots:SetJustifyH("RIGHT")
    row.slots:SetMaxLines(1)
    row.slots:SetTextColor(unpack(colors.teal))
    row.source=icon(row,36)
    row.source:SetPoint("TOPLEFT",12,-32)
    row.target=icon(row,36)
    local half=row:GetWidth()/2
    row.target:SetPoint("TOPLEFT",half+10,-32)
    row.sourceName=label(row,"",56,-37,half-74,"GameFontHighlight")
    row.sourceName:SetMaxLines(2)
    row.arrow=label(row,">",half-13,-42,22,"GameFontNormal")
    row.arrow:SetTextColor(unpack(colors.muted))
    row.targetName=label(row,"",half+54,-37,half-68,"GameFontHighlight")
    row.targetName:SetMaxLines(2)
    row.reason=label(row,"",12,-77,row:GetWidth()-24)
    row.reason:SetMaxLines(1)
    local function select()
        self.selectedSource=row.sourceID
        if not self.ui.editing then self:SetEditing(true) else self:RefreshSelection() end
    end
    row:SetScript("OnMouseUp",function(_,mouse)
        if mouse == "LeftButton" and self.drag then self:DroppedTarget(row.sourceID)
        elseif mouse == "LeftButton" then select() end
    end)
    row:SetScript("OnEnter",function()
        hint(row,roleLabel(row.source.spell),row.details)
    end)
    row:SetScript("OnLeave",function() GameTooltip:Hide() end)
    row.source:SetScript("OnClick",select)
    row.source:SetScript("OnDragStart",function() self:StartDrag("source",row.source.spell) end)
    row.source:SetScript("OnDragStop",function() self:FinishDrag() end)
    row.source:SetScript("OnReceiveDrag",function()
        if self.drag and self.drag.side == "source" then
            self.selectedSource=self.drag.id; self:StopDrag()
        end
    end)
    row:SetScript("OnReceiveDrag",function() self:DroppedTarget(row.sourceID) end)
    row.target:SetScript("OnReceiveDrag",function() self:DroppedTarget(row.sourceID) end)
    row.target:SetScript("OnMouseUp",function(_,mouse)
        if mouse == "LeftButton" and self.drag then self:DroppedTarget(row.sourceID) end
    end)
    row.target:SetScript("OnClick",function(_,mouse)
        if mouse == "RightButton" then
            if InCombatLockdown() then return self:Print("Edit mappings out of combat.") end
            if self:IsLevelingMode() then return self:LevelingMenu(row.target,row.target.spell or row.source.spell) end
            self:Menu(row.target,{
                {text="Restore automatic suggestion",action=function() self:SetMapping(row.sourceID,nil) end},
                {text="Exclude this ability",action=function() self:SetMapping(row.sourceID,false) end},
            })
        else select() end
    end)
    self.ui.rows[index]=row
    self:LayoutRow(row,index)
    return row
end

function MM:LayoutRow(row,index)
    local width=self.ui.mappingChild:GetWidth()
    local editing=self.ui.editing
    local height=editing and ROW_HEIGHT or 72
    row:SetSize(width,height)
    row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-(index-1)*(height+6))
    local function place(value,x,y,w)
        value:ClearAllPoints(); value:SetPoint("TOPLEFT",x,y)
        if w then value:SetWidth(w) end
    end
    if editing then
        local half=width/2
        place(row.role,12,-9,width-166); row.role:SetMaxLines(1)
        place(row.slots,width-150,-9,138); row.slots:SetJustifyH("RIGHT")
        place(row.source,12,-32); place(row.sourceName,56,-37,half-74)
        place(row.target,half+10,-32); place(row.targetName,half+54,-37,half-68)
        place(row.reason,12,-77,width-24)
        place(row.arrow,half-13,-42,22); row.arrow:Show()
    else
        local middle,right=width*0.34,width*0.68
        place(row.source,12,-17); place(row.sourceName,56,-14,middle-70)
        place(row.slots,56,-46,middle-70); row.slots:SetJustifyH("LEFT")
        place(row.role,middle,-14,right-middle-22); row.role:SetMaxLines(2)
        place(row.reason,middle,-46,right-middle-22)
        place(row.target,right,-17); place(row.targetName,right+44,-14,width-right-56)
        row.arrow:Hide()
    end
end

function MM:SetEditing(editing)
    local ui=self.ui
    if not ui then return end
    ui.editing=not not editing
    self:StopDrag()
    ui.edit:SetText(ui.editing and "Finish editing" or "Edit mappings")
    ui.sourcePanel:SetShown(ui.editing); ui.targetPanel:SetShown(ui.editing)
    ui.roleFilterButton:SetShown(ui.editing); ui.pending:SetShown(ui.editing)
    ui.pendingLabel:SetShown(ui.editing); ui.clearFilters:SetShown(ui.editing)
    ui.editHint:SetShown(ui.editing)
    ui.targetNote:SetShown(ui.editing)
    for _,heading in ipairs(ui.tableHeaders) do heading:SetShown(not ui.editing) end
    ui.mappingPanel:ClearAllPoints()
    ui.mappingPanel:SetPoint("TOPLEFT",ui.editing and 266 or 22,-250)
    local width=ui.editing and 500 or 996
    ui.mappingPanel:SetWidth(width)
    ui.mappingScroll:SetWidth(width-36); ui.mappingChild:SetWidth(width-36)
    ui.mappingScroll:ClearAllPoints(); ui.mappingScroll:SetPoint("TOPLEFT",6,ui.editing and -70 or -84)
    ui.mappingScroll:SetHeight(ui.editing and 318 or 304)
    ui.mappingSearch:SetWidth(width-34); ui.mappingSearch.title:SetWidth(width-24)
    ui.empty:SetWidth(width-44)
    ui.mappingScroll:SetVerticalScroll(0)
    if not ui.editing then
        ui.suspendRefresh=true
        ui.roleFilter=nil; ui.pendingOnly=nil; ui.pending:SetChecked(false)
        ui.sourceSearch:SetText(""); ui.targetSearch:SetText("")
        ui.suspendRefresh=nil
    end
    for index,row in ipairs(ui.rows) do self:LayoutRow(row,index) end
    self:RefreshUI()
end

local function statusFor(match,target)
    if match and match.status then return match.status end
    if target then return "matched" end
    if match and match.blocked then return "excluded" end
    return "not_configured"
end

local function stateText(match,status)
    if status == "matched" then
        if match.warning then return "Manual choice · note: "..match.warning,colors.amber end
        if match.copied then return "Automatic copy · same ability",colors.teal end
        return match.manual and "Your choice" or match.approximate and "Automatic alternative" or "Automatic suggestion",colors.teal
    elseif status == "no_direct_equivalent" then return "No available alternative",colors.muted
    elseif status == "excluded" then return "Excluded by you · the action bar will be preserved",colors.muted
    elseif status == "unavailable" then return "Unavailable · review talents or choose another ability",colors.amber
    end
    return "Not configured · choose a destination ability",colors.amber
end

function MM:ShowPreview(preserveScroll)
    local canApply,reason,preview=self:GetApplyState()
    local ui=self.ui
    if not ui.preview then
        local overlay=panel(ui,760,500)
        overlay:SetPoint("CENTER")
        overlay:SetFrameStrata("DIALOG")
        overlay:SetFrameLevel(ui:GetFrameLevel()+40)
        overlay:EnableMouse(true)
        overlay.title=label(overlay,"Preview changes",20,-18,680,"GameFontNormalLarge")
        overlay.summary=label(overlay,"",20,-49,700,"GameFontHighlight")
        overlay.note=label(overlay,"Mappings are saved as you edit. Apply changes this character’s action bars.",20,-75,700)
        overlay.note:SetTextColor(unpack(colors.muted))
        overlay.scroll,overlay.child=scroll(overlay,20,-110,716,288)
        overlay.rows={}
        overlay.empty=label(overlay,"",26,-135,678,"GameFontHighlight")
        overlay.reason=label(overlay,"",20,-415,700)
        overlay.reason:SetMaxLines(2)
        overlay.apply=button(overlay,"Apply changes",508,-450,228,function()
            if not InCombatLockdown() then self:Apply(); overlay:Hide() end
        end,true)
        button(overlay,"Back to editor",20,-450,182,function() overlay:Hide() end)
        local close=CreateFrame("Button",nil,overlay,"UIPanelCloseButton")
        close:SetPoint("TOPRIGHT",-4,-4)
        ui.preview=overlay
    end
    local overlay=ui.preview
    preview=preview or {}
    local plan=preview.plan or {}
    local reference,targets=self:Context()
    overlay.summary:SetText(#plan.." action bar changes · "..(preview.skipped or 0).." abilities preserved")
    for index,entry in ipairs(plan) do
        local row=overlay.rows[index]
        if not row then
            row=panel(overlay.child,overlay.child:GetWidth(),54)
            row:SetPoint("TOPLEFT",0,-(index-1)*60)
            row.key=label(row,"",10,-9,115,"GameFontNormal")
            row.key:SetTextColor(unpack(colors.teal))
            row.change=label(row,"",135,-9,row:GetWidth()-147,"GameFontHighlight")
            row.change:SetMaxLines(1)
            row.role=label(row,"",135,-31,row:GetWidth()-147)
            row.role:SetTextColor(unpack(colors.muted))
            row:EnableMouse(true)
            row:SetScript("OnEnter",function() hint(row,"Action bar change",row.details) end)
            row:SetScript("OnLeave",function() GameTooltip:Hide() end)
            overlay.rows[index]=row
        end
        local target=entry.clearing and {name="Empty (duplicate or replaced ability)"}
            or targets[entry.id] or self:SpellInfo(entry.id)
        local before=entry.before
        local previous=before and before.kind == "spell" and self:SpellInfo(before.id).name
            or before and before.name
            or before and (before.kind == "empty" and "Empty" or "Current action preserved") or "Empty"
        row.key:SetText(bindings({entry.slot}))
        row.change:SetText((previous or "Current ability").." > "..(target.name or "#"..entry.id))
        row.role:SetText(target.role and roleLabel(target) or "Chosen equivalent")
        row.details="Current keybinding: "..bindings({entry.slot}).."\n"..technicalSlots({entry.slot})
            ..(entry.sourceBinding and "\nKeybinding captured on main: "..entry.sourceBinding or "")
            ..(entry.bindingWarning and "\n"..entry.bindingWarning or "")
        row:Show()
    end
    for index=#plan+1,#overlay.rows do overlay.rows[index]:Hide() end
    overlay.child:SetHeight(math.max(1,#plan*60))
    if not preserveScroll then overlay.scroll:SetVerticalScroll(0) end
    overlay.empty:SetShown(#plan == 0)
    overlay.empty:SetText(reason or "No action bar changes are needed.")
    overlay.reason:SetText(reason or "Review the abilities. Restore bars to undo the last application.")
    overlay.reason:SetTextColor(unpack(canApply and colors.muted or colors.amber))
    enabled(overlay.apply,canApply,reason)
    overlay:Show()
end

function MM:RefreshUI()
    if not self.ui or not self.ui.ready or not self.current then return end
    if not self.ui:IsShown() then self.ui.dirty=true; return end
    local ui,settings=self.ui,self:Settings()
    ui.dirty=nil
    local reference,targets,_,matches,targetLabel=self:Context()
    ui.reference=reference
    ui.isCurrentTarget=settings.targetClass == self.current.class and settings.targetSpec == self.current.spec
    local origin=self.db.references[settings.sourceKey] or self.db.characters[settings.sourceKey]
    local shownReference=self:IsLevelingMode() and origin or reference
    local sourceClass=shownReference and shownReference.class or settings.sourceClass or self.current.class
    ui.sourceClass:SetText(self:Class(sourceClass).name.."  v")
    ui.sourceProfile:SetText(shownReference and (shownReference.name.." / "..shownReference.specName) or "Select your main  v")
    ui.sourceProfile.tip=shownReference and (shownReference.name.." / "..shownReference.specName) or "Capture your main’s bars to create a reference."
    ui.sourceHeading:SetText(self:IsLevelingMode() and "SOURCE · MOUNTS" or "SOURCE · MAIN")
    ui.tableHeaders[1]:SetText(self:IsLevelingMode() and "PLANNED POSITION" or "MAIN ABILITY")
    ui.tableHeaders[3]:SetText(self:IsLevelingMode() and "CHARACTER ABILITY" or "DESTINATION ABILITY")
    ui.targetClass:SetText(self:Class(settings.targetClass).name.."  v")
    ui.targetSpec:SetText(self:SpecName(settings.targetClass,settings.targetSpec).."  v")
    enabled(ui.targetClass,not self:IsLevelingMode(),"In leveling mode, the destination is always the current character.")
    enabled(ui.targetSpec,not self:IsLevelingMode(),"In leveling mode, the specialization follows the current character.")
    ui.auto:SetChecked(settings.auto == true)
    ui.current:SetText(self.current.name.." · "..self.current.specName)
    ui.targetNote:SetText(targetLabel)
    ui.roleFilterButton:SetText(ui.roleFilter or "All purposes  v")
    ui.roleFilterButton.tip=ui.roleFilter or "Filter all three columns by ability purpose."
    local placed,grouped,order={},{},{}
    if reference then
        for slot=1,self.MAX_SLOT do
            local action=reference.actions[slot]
            if self:IsManagedSlot(slot) and action and self:ActionKey(action) then
                local id=self:ActionKey(action)
                if not grouped[id] then grouped[id]={}; order[#order+1]=id end
                grouped[id][#grouped[id]+1]=slot
                placed[id]=reference.spells[id] or {id=id,role="unknown",name=action.name or "Source action"}
            end
        end
    end
    ui.grouped,ui.placed=grouped,placed
    if not InCombatLockdown() then ui.targetSlots={} end
    ui.targetSlots=ui.targetSlots or {}
    if ui.isCurrentTarget and not InCombatLockdown() then
        for slot=1,self.MAX_SLOT do
            if self:IsManagedSlot(slot) then
                local kind,rawID=GetActionInfo(slot)
                local id=kind and self:ActionKey({kind=kind,id=rawID})
                if id and targets[id] then
                    ui.targetSlots[id]=ui.targetSlots[id] or {}
                    ui.targetSlots[id][#ui.targetSlots[id]+1]=slot
                end
                if kind then
                    for key,entry in pairs(targets) do
                        if entry.action and key~=id and self:ActionMatches({kind=kind,id=rawID},entry.action) then
                            ui.targetSlots[key]=ui.targetSlots[key] or {}
                            ui.targetSlots[key][#ui.targetSlots[key]+1]=slot
                        end
                    end
                end
            end
        end
    end
    local paletteSources={}
    local translated,pending,noDirect,manual=0,0,0,0
    local rowIndex=0
    for _,id in ipairs(order) do
        local spell=placed[id]
        local match=matches[id]
        local target=match and match.id and targets[match.id]
        local status=statusFor(match,target)
        local problem=status == "not_configured" or status == "unavailable" or (match and match.warning)
        local unresolved=problem or status == "no_direct_equivalent"
        if target then translated=translated+1 end
        if problem then pending=pending+1 end
        if status == "no_direct_equivalent" then noDirect=noDirect+1 end
        if match and match.manual then manual=manual+1 end
        if not ui.pendingOnly or unresolved then paletteSources[id]=spell end
        if (not ui.pendingOnly or unresolved) and (not ui.roleFilter or ui.roleFilter == roleLabel(spell))
            and searchMatches(spell,ui.sourceSearch:GetText())
            and (searchMatches(spell,ui.mappingSearch:GetText()) or target and searchMatches(target,ui.mappingSearch:GetText())) then
            rowIndex=rowIndex+1
            local row=ui.rows[rowIndex] or self:CreateRow(rowIndex)
            self:LayoutRow(row,rowIndex)
            row.sourceID=id
            row.source.spell=spell
            row.source.texture:SetTexture(spell.icon or self:SpellInfo(id).iconID or QUESTION)
            row.sourceName:SetText(spell.name or "#"..id)
            row.role:SetText(roleLabel(spell))
            local key=bindings(grouped[id],reference)
            row.slots:SetText(key)
            row.target.spell=target
            row.target.texture:SetTexture(target and target.icon or QUESTION)
            local caption=status == "no_direct_equivalent" and "No direct equivalent"
                or status == "excluded" and "Excluded by you"
                or status == "unavailable" and "Unavailable" or "Not configured"
            row.targetName:SetText(target and target.name or caption)
            row.target.emptyTitle=caption
            local statusLabel,color=stateText(match,status)
            row.reason:SetText(statusLabel)
            row.reason:SetTextColor(unpack(color))
            row.targetName:SetTextColor(unpack(target and colors.text or (unresolved and colors.amber or colors.muted)))
            row.details=roleLabel(spell).."\nCaptured keybinding: "..key.."\n"..technicalSlots(grouped[id])
                .."\n"..(match and match.reason or statusLabel)
                ..(match and match.warning and "\n"..match.warning or "")
            if self.FunctionDetails then
                local details=self:FunctionDetails(spell) or {}
                if #details>0 then row.details=row.details.."\n"..table.concat(details,"\n") end
            end
            row.source.note=row.details
            row.target.note=row.details.."\nClick or drag a destination ability. Right-click to restore the automatic suggestion or exclude it."
            row:Show()
        end
    end
    for index=rowIndex+1,#ui.rows do ui.rows[index]:Hide() end
    ui.mappingChild:SetHeight(math.max(1,rowIndex*((ui.editing and ROW_HEIGHT or 72)+6)))
    local sourceCount,targetCount=0,0
    if ui.editing then
        sourceCount=self:FillPalette(ui.sourceChild,paletteSources,"source",ui.sourceSearch:GetText())
        targetCount=self:FillPalette(ui.targetChild,targets,"target",ui.targetSearch:GetText())
    end
    ui.sourceEmpty:SetShown(sourceCount == 0)
    ui.sourceEmpty:SetText(reference and "No abilities match these filters." or "Log in to your main and capture its bars.")
    ui.targetEmpty:SetShown(targetCount == 0)
    ui.targetEmpty:SetText("No abilities match these filters.")
    ui.empty:SetShown(rowIndex == 0)
    ui.empty:SetText(#order == 0 and "Capture your main character’s action bars once.\n\nWhen you log in to an alt, the addon builds suggestions automatically."
        or "No mappings match these filters.\n\nClear the search or select all purposes.")
    ui.summary:SetText(translated.." suggestions ready · "..(pending+noDirect).." unmapped")
    ui.summary.tip=manual.." manual choices take priority over suggestions."
    local canApply,reason=self:GetApplyState()
    local canUndo,undoReason=self:GetUndoState()
    enabled(ui.apply,canApply,reason or "Apply available mappings and save the current bars for restoration.")
    enabled(ui.undo,canUndo,undoReason or "Restore the bars from before the last application.")
    enabled(ui.capture,not InCombatLockdown(),InCombatLockdown() and "Capture your bars out of combat." or "Save abilities, positions, and actual keybindings as the main reference.")
    enabled(ui.suggest,reference and not self:IsLevelingMode() and not InCombatLockdown(),"Replaces manual choices for this character pair with the suggested map. Action bars are unchanged until you apply.")
    local allowAuto=reference and (reference.key ~= self.current.key or self:IsLevelingMode()) and ui.isCurrentTarget and not InCombatLockdown()
    enabled(ui.auto,allowAuto,not allowAuto and (reason or "Select a reference from another character and the current destination.") or "Requests consent. Reorganizes out of combat on login, level-up, or ability/talent changes.")
    ui.autoMode:SetText(self:IsLevelingMode() and "Mode: priority leveling" or "Mode: character mappings")
    enabled(ui.autoMode,not InCombatLockdown(),"Choose character mappings or priority leveling. Changing modes disables automation.")
    ui.editHint:SetText(self:IsLevelingMode() and "Right-click an ability to raise/lower its priority, pin its position, or exclude it from leveling."
        or "Right-click a destination to restore the suggestion or exclude it. Mounts preserve the source selection.")
    ui.applyReason:SetText(reason or "Ready to apply. A copy of the action bars will be saved for restoration.")
    ui.applyReason:SetTextColor(unpack(canApply and colors.muted or colors.amber))
    if ui.preview and ui.preview:IsShown() then self:ShowPreview(true) end
    self:RefreshSelection()
end

function MM:AutoModeMenu(anchor)
    local function select(mode)
        local settings=self:Settings()
        self:DisableAutomatic()
        settings.autoMode=mode
        settings.autoConsentMode=nil
        if mode=="leveling" then settings.targetClass,settings.targetSpec=self.current.class,self.current.spec end
        self:InvalidateContext(); self:RefreshUI()
    end
    self:Menu(anchor,{
        {text="Character mappings",action=function() select("equivalence") end},
        {text="Leveling: organize by priority",action=function() select("leveling") end},
        {text="Restore default priorities",disabled=not self:IsLevelingMode(),action=function()
            self:Settings().levelingPriority={}
            self:InvalidateContext(); self:RefreshUI()
            if self:Settings().auto then self:QueueAuto() end
        end},
    })
end

function MM:LevelingMenu(anchor,spell)
    if not spell or spell.action or spell.role=="mount" or InCombatLockdown() then return end
    local settings=self:Settings()
    local id=spell.baseID or spell.id
    settings.levelingPins=settings.levelingPins or {}
    settings.levelingExcluded=settings.levelingExcluded or {}
    local pins,excluded=settings.levelingPins,settings.levelingExcluded
    local canPrioritize=self:IsCombatLayoutSpell(spell)
    local positions={}
    for slot,action in pairs(self:ReadActions()) do
        if self:ActionMatches(action,{kind="spell",id=spell.id}) then positions[#positions+1]=slot end
    end
    table.sort(positions)
    local function refresh()
        self:InvalidateContext(); self:RefreshUI()
        if settings.auto then self:QueueAuto() end
    end
    self:Menu(anchor,{
        {text="Raise bar priority",disabled=not canPrioritize,reason="Existing utility actions keep their positions.",action=function() self:MoveLevelingPriority(spell.id,-1) end},
        {text="Lower bar priority",disabled=not canPrioritize,reason="Existing utility actions keep their positions.",action=function() self:MoveLevelingPriority(spell.id,1) end},
        {text=pins[id] and "Unpin position" or "Pin current position",disabled=not pins[id] and #positions==0,
            reason="Pinned abilities keep their position while leveling. Place the ability on the bar to pin it.",
            action=function() pins[id]=not pins[id] and positions[1] or nil; refresh() end},
        {text=excluded[id] and "Include in leveling again" or "Exclude from automatic layout",
            action=function() excluded[id]=not excluded[id] or nil; refresh() end},
    })
end

function MM:ShowAutoConsent()
    if InCombatLockdown() then return end
    local ui=self.ui
    local dialog=ui.consent
    if not dialog then
        dialog=panel(ui,640,420)
        dialog:SetPoint("CENTER")
        dialog:SetFrameStrata("DIALOG")
        dialog:SetFrameLevel(ui:GetFrameLevel()+45)
        dialog:EnableMouse(true)
        dialog.title=label(dialog,"Authorize automatic layout",22,-22,596,"GameFontNormalLarge")
        dialog.description=label(dialog,"",22,-60,596,"GameFontHighlight")
        dialog.description:SetSpacing(5)
        dialog.approve=button(dialog,"Authorize and enable",332,-362,286,function()
            if InCombatLockdown() then return self:Print("Leave combat to authorize.") end
            local settings=self:Settings()
            if dialog.key~=self.current.key or dialog.mode~=(settings.autoMode or "equivalence")
                or dialog.sourceKey~=settings.sourceKey or settings.targetClass~=self.current.class or settings.targetSpec~=self.current.spec then
                dialog:Hide(); self:RefreshUI()
                return self:Print("The character or mode changed. Open authorization again.")
            end
            settings.autoConsent=self.AUTO_CONSENT_VERSION
            settings.autoConsentMode=dialog.mode
            settings.auto=true
            if dialog.mode=="leveling" then self.db.levelingAuto[(self:Identity())]=self.AUTO_CONSENT_VERSION end
            -- Start a fresh restoration baseline for this consent session.
            local undo=self.db.undo[self.current.key]
            if undo then undo.automatic=false end
            dialog:Hide(); self:QueueAuto(); self:RefreshUI()
        end,true)
        button(dialog,"Cancel",22,-362,286,function() dialog:Hide(); self:RefreshUI() end)
        dialog:RegisterEvent("PLAYER_REGEN_DISABLED")
        dialog:SetScript("OnEvent",function() dialog:Hide() end)
        ui.consent=dialog
    end
    local settings=self:Settings()
    dialog.key,dialog.mode,dialog.sourceKey=self.current.key,settings.autoMode or "equivalence",settings.sourceKey
    dialog.description:SetText(self:IsLevelingMode()
        and "I authorize MuscleMemory to rearrange this character’s abilities on login, level-up, learning abilities, changing talents, or switching specialization.\n\nAbilities may move to different keybindings based on bar priority. New abilities are placed automatically. Right-click to adjust priority or pin a position. Available mounts follow the exact source selection.\n\nChanges are made out of combat. Macros, items, and existing utility positions are preserved. Restore bars disables automation for every specialization and restores the state from the start of this authorization for the current specialization."
        or "I authorize MuscleMemory to apply mappings from the selected source automatically for this character and specialization on login or ability/talent changes.\n\nButtons may be replaced with abilities available to the destination. Mounts preserve the exact source selection; actions without an available equivalent remain pending.\n\nChanges are made out of combat. Keybindings are not modified. Restore bars disables automation and restores the state from the start of this authorization.")
    dialog:Show()
end

function MM:CreateUI()
    local ui=panel(UIParent,1040,760,"MuscleMemoryFrame")
    ui:SetBackdropColor(unpack(colors.bg))
    ui:SetPoint("CENTER")
    ui:SetFrameStrata("HIGH")
    ui:SetClampedToScreen(true)
    ui:SetMovable(true)
    ui:EnableMouse(true)
    ui:RegisterForDrag("LeftButton")
    ui:SetScript("OnDragStart",function() if not self.drag then ui:StartMoving() end end)
    ui:SetScript("OnDragStop",function() ui:StopMovingOrSizing(); self:StopDrag() end)
    ui:SetScript("OnHide",function()
        if self.menu then self.menu:Hide() end
        if ui.preview then ui.preview:Hide() end
        if ui.consent then ui.consent:Hide() end
        self:StopDrag()
    end)
    ui:SetScript("OnMouseUp",function() self:StopDrag() end)
    ui:SetScale(math.min(1,(UIParent:GetWidth()-40)/1040,(UIParent:GetHeight()-40)/760))
    ui.rows={}
    self.ui=ui
    tinsert(UISpecialFrames,"MuscleMemoryFrame")
    animateOpening(ui)
    label(ui,"MuscleMemory",22,-22,nil,"GameFontNormalLarge"):SetTextColor(unpack(colors.text))
    label(ui,"Same purpose, on the key you already know.",22,-48,840,"GameFontHighlight"):SetTextColor(unpack(colors.muted))
    ui.current=label(ui,"",22,-69,870)
    ui.current:SetTextColor(unpack(colors.muted))
    local close=CreateFrame("Button",nil,ui,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",-5,-5)
    ui.capture=button(ui,"Capture this character’s bars",782,-37,236,function() self:Capture() end)
    ui.sourceHeading=label(ui,"SOURCE · MAIN",22,-94,228,"GameFontNormal")
    ui.sourceHeading:SetTextColor(unpack(colors.teal))
    label(ui,"AUTOMATIC MAPPING",266,-94,500,"GameFontNormal"):SetTextColor(unpack(colors.teal))
    label(ui,"DESTINATION · ALT",782,-94,228,"GameFontNormal"):SetTextColor(unpack(colors.teal))
    ui.sourceClass=button(ui,"",22,-116,228,function(anchor) self:ClassMenu(anchor,"source") end)
    ui.sourceProfile=button(ui,"",22,-152,228,function(anchor) self:ReferenceMenu(anchor) end)
    ui.targetClass=button(ui,"",782,-116,228,function(anchor) self:ClassMenu(anchor,"target") end)
    ui.targetSpec=button(ui,"",782,-152,228,function(anchor) self:TargetSpecMenu(anchor) end)
    ui.summary=label(ui,"",266,-122,500,"GameFontHighlight")
    ui.feedback=label(ui,"",266,-148,500)
    ui.feedback:SetMaxLines(2)
    ui.feedback:SetSpacing(3)
    ui.edit=button(ui,"Edit mappings",22,-192,214,function() self:SetEditing(not ui.editing) end)
    ui.edit.tip="Optional: adjust suggestions by clicking or dragging."
    ui.suggest=button(ui,"Use suggestions",250,-192,224,function() self:UseAutomaticSuggestions() end)
    ui.roleFilterButton=button(ui,"All purposes  v",22,-222,214,function(anchor) self:RoleFilterMenu(anchor) end)
    ui.pending=CreateFrame("CheckButton",nil,ui,"UICheckButtonTemplate")
    ui.pending:SetPoint("TOPLEFT",250,-221)
    ui.pendingLabel=label(ui,"Review pending items",285,-230,178,"GameFontHighlight")
    ui.pending:SetScript("OnClick",function(check) ui.pendingOnly=check:GetChecked() == true; self:RefreshUI() end)
    ui.pending:SetScript("OnEnter",function()
        hint(ui.pending,"Review pending items","Shows abilities without available suggestions and choices that need review. Ready suggestions can still be applied.")
    end)
    ui.pending:SetScript("OnLeave",function() GameTooltip:Hide() end)
    ui.clearFilters=button(ui,"Clear filters",480,-222,155,function()
        ui.suspendRefresh=true
        ui.roleFilter=nil
        ui.pendingOnly=nil
        ui.pending:SetChecked(false)
        ui.sourceSearch:SetText("")
        ui.mappingSearch:SetText("")
        ui.targetSearch:SetText("")
        ui.suspendRefresh=nil
        self:RefreshUI()
    end)
    ui.targetNote=label(ui,"",782,-224,228)
    ui.targetNote:SetTextColor(unpack(colors.muted))
    local sourcePanel=panel(ui,228,400)
    sourcePanel:SetPoint("TOPLEFT",22,-250)
    local mappingPanel=panel(ui,500,400)
    mappingPanel:SetPoint("TOPLEFT",266,-250)
    local targetPanel=panel(ui,228,400)
    targetPanel:SetPoint("TOPLEFT",782,-250)
    ui.sourcePanel,ui.mappingPanel,ui.targetPanel=sourcePanel,mappingPanel,targetPanel
    ui.tableHeaders={label(mappingPanel,"MAIN ABILITY",12,-66,300),
        label(mappingPanel,"PURPOSE / MAPPING",330,-66,300),
        label(mappingPanel,"DESTINATION ABILITY",650,-66,300)}
    for _,heading in ipairs(ui.tableHeaders) do heading:SetTextColor(unpack(colors.teal)) end
    local function search(parent,title,width)
        local titleLabel=label(parent,title,12,-11,width-24)
        titleLabel:SetTextColor(unpack(colors.muted))
        local box=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
        box:SetSize(width-34,24)
        box:SetPoint("TOPLEFT",14,-31)
        box:SetAutoFocus(false)
        box:SetMaxLetters(80)
        box:SetScript("OnEscapePressed",function() box:ClearFocus(); box:SetText("") end)
        box:SetScript("OnEnterPressed",function() box:ClearFocus() end)
        box:SetScript("OnTextChanged",function() if not ui.suspendRefresh then self:RefreshUI() end end)
        box.title=titleLabel
        return box
    end
    ui.sourceSearch=search(sourcePanel,"Search main",228)
    ui.mappingSearch=search(mappingPanel,"Search abilities or purposes",500)
    ui.targetSearch=search(targetPanel,"Search destination",228)
    ui.sourceScroll,ui.sourceChild=scroll(sourcePanel,6,-70,216,318)
    ui.mappingScroll,ui.mappingChild=scroll(mappingPanel,6,-70,488,318)
    ui.targetScroll,ui.targetChild=scroll(targetPanel,6,-70,216,318)
    ui.sourceEmpty=label(sourcePanel,"",16,-88,196,"GameFontHighlight")
    ui.sourceEmpty:SetTextColor(unpack(colors.muted))
    ui.targetEmpty=label(targetPanel,"",16,-88,196,"GameFontHighlight")
    ui.targetEmpty:SetTextColor(unpack(colors.muted))
    ui.empty=label(mappingPanel,"",22,-112,456,"GameFontHighlight")
    ui.empty:SetSpacing(5)
    ui.empty:SetTextColor(unpack(colors.muted))
    ui.auto=CreateFrame("CheckButton",nil,ui,"UICheckButtonTemplate")
    ui.auto:SetPoint("TOPLEFT",22,-662)
    label(ui,"Automatic for this character / specialization",57,-671,540,"GameFontHighlight")
    ui.auto:SetScript("OnClick",function(check)
        if InCombatLockdown() then return end
        local requested=check:GetChecked() == true
        self:DisableAutomatic()
        if requested then self:ShowAutoConsent() end
        self:RefreshUI()
    end)
    if ui.auto.SetMotionScriptsWhileDisabled then ui.auto:SetMotionScriptsWhileDisabled(true) end
    ui.auto:SetScript("OnEnter",function() hint(ui.auto,"Automatic application",ui.auto.tip) end)
    ui.auto:SetScript("OnLeave",function() GameTooltip:Hide() end)
    ui.autoMode=button(ui,"",620,-658,398,function(anchor) self:AutoModeMenu(anchor) end)
    ui.editHint=label(ui,"Right-click a destination to restore the suggestion or exclude it.",22,-698,990)
    ui.editHint:SetTextColor(unpack(colors.muted))
    ui.applyReason=label(ui,"",22,-716,520,"GameFontHighlight")
    ui.applyReason:SetMaxLines(2)
    ui.applyReason:SetSpacing(3)
    ui.previewButton=button(ui,"Preview",564,-714,112,function() self:ShowPreview() end)
    ui.previewButton.tip="Review abilities and keybindings that will change before applying."
    ui.undo=button(ui,"Restore bars",688,-714,154,function() self:Undo() end)
    ui.apply=button(ui,"Apply suggestions",854,-714,164,function() self:Apply() end,true)
    ui:RegisterEvent("PLAYER_REGEN_DISABLED")
    ui:RegisterEvent("PLAYER_REGEN_ENABLED")
    ui:RegisterEvent("SPELL_DATA_LOAD_RESULT")
    ui:RegisterEvent("UPDATE_BINDINGS")
    ui:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
    ui:SetScript("OnEvent",function(_,event,_,success)
        if event == "PLAYER_REGEN_DISABLED" then
            self:StopDrag()
            if self.menu then self.menu:Hide() end
        end
        if ui:IsShown() and (event ~= "SPELL_DATA_LOAD_RESULT" or success) then self:RefreshUI() end
    end)
    ui.ready=true
    self:SetEditing(false)
end

function MM:ToggleUI()
    if not self.current then return self:Print("Wait for the character to finish loading.") end
    if not self.ui then self:CreateUI() else self.ui:SetShown(not self.ui:IsShown()) end
    if self.ui:IsShown() then self:RefreshUI() end
end
