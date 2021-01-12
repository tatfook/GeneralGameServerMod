--[[
Title: Input
Author(s): wxa
Date: 2020/8/14
Desc: 输入框
-------------------------------------------------------
local Input = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/Input.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/UniString.lua");
NPL.load("(gl)script/ide/math/Rect.lua");
local Rect = commonlib.gettable("mathlib.Rect");
local UniString = commonlib.gettable("System.Core.UniString");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local FocusPolicy = commonlib.gettable("System.Core.Namespace.FocusPolicy");
local Point = commonlib.gettable("mathlib.Point");

local Element = NPL.load("../Element.lua", IsDevEnv);
local Input = commonlib.inherit(Element, NPL.export());
local InputDebug = GGS.Debug.GetModuleDebug("InputDebug").Disable(); --Enable  Disable
local CursorShowHideMaxTickCount = 30;

Input:Property("Name", "Input");
Input:Property("Value", "");                                -- 按钮文本值
Input:Property("ShowCursor", false, "IsShowCursor");
Input:Property("BaseStyle", {
    NormalStyle = {
        ["display"] = "inline-size",
        ["border-width"] = "1px",
        ["border-color"] = "#cccccc",
        ["color"] = "#000000",
        ["height"] = "30px",
        ["width"] = "120px",
        ["padding"] = "2px 4px",
        ["background-color"] = "#ffffff",
        ["font-size"] = "14px",
    }
});

function Input:ctor()
    self:Reset();

    self:SetCanFocus(true);
end

function Input:Init(xmlNode, window, parent)
    self:InitElement(xmlNode, window, parent);
    self.text = UniString:new(xmlNode.attr and xmlNode.attr.value or "");

    -- if (self:GetAttrBoolValue("autofocus")) then self:FocusIn() end
    return self;
end

function Input:Reset()
    self.cursorShowHideTickCount = 0;
    self.cursorX, self.cursorY, self.cursorWidth, self.cursorHeight = 0, 0, nil, nil;
    self.cursorAt = 1;    -- 光标位置 占据下一个输入位置
    self.scrollX = 0;     -- 横向滚动的位置 
    self.undoCmds = {};   -- 撤销命令
    self.redoCmds = {};   -- 重做命令
    self.selectStartAt, self.selectEndAt = nil, nil;  -- 文本选择
end

function Input:OnAttrValueChange(attrName, attrValue, oldAttrValue)
    if (attrName ~= "value" or tostring(attrValue) == self:GetValue()) then return end
    self:Reset();
    self.text = UniString:new(tostring(attrValue));
    self:UpdateValue();
end

-- 是否选择
function Input:IsSelected()
    return self.selectStartAt and self.selectEndAt and self.selectStartAt > 0 and self.selectEndAt > 0;  -- [selectStartAt, selectEndAt]
end

-- 获取选择
function Input:GetSelected()
    if (not self:IsSelected()) then return end
    if (self.selectStartAt < self.selectEndAt) then return self.selectStartAt, self.selectEndAt end
    return self.selectEndAt, self.selectStartAt;
end

-- 获取选择的文本
function Input:GetSelectedText()
    if (not self:IsSelected()) then return "" end
    return self.text:sub(self:GetSelected()):GetText();
end

-- 清除选择
function Input:ClearSelected()
    self.selectStartAt, self.selectEndAt = nil, nil;
end

function Input:IsCanFocus()
    return true;
end

function Input:IsReadOnly()
    return self:GetAttrBoolValue("readonly");
end

function Input:handleReturn()
    return self:CallAttrFunction("onkeydown.enter")
end

function Input:handleEscape()
end

function Input:handleBackspace()
    if (self:IsSelected()) then
        self:DeleteSelected();
    else
        self:DeleteTextCmd(self.cursorAt - 1, 1);
    end
end

function Input:handleDelete()
    self:DeleteTextCmd(self.cursorAt, 1);
end

function Input:handleUndo()
    if (#self.undoCmds == 0) then return end
    local len = #self.undoCmds;
    local cmd = self.undoCmds[len];
    table.remove(self.undoCmds, len);
    table.insert(self.redoCmds, cmd);
    if (cmd.action == "insert") then
        self:DeleteText(cmd.startAt, cmd.endAt);
    elseif (cmd.action == "delete") then
        self:InsertText(cmd.startAt, cmd.endAt, cmd.text);
    end
end

function Input:handleRedo()
    if (#self.redoCmds == 0) then return end
    local len = #self.redoCmds;
    local cmd = self.redoCmds[len];
    table.remove(self.redoCmds, len);
    table.insert(self.undoCmds, cmd);
    if (cmd.action == "insert") then
        self:InsertText(cmd.startAt, cmd.endAt, cmd.text);
    elseif (cmd.action == "delete") then
        self:DeleteText(cmd.startAt, cmd.endAt);
    end
end

function Input:handleSelectAll()
    self.selectStartAt, self.selectEndAt = 1, self.text:length();
    InputDebug.Format("handleSelectAll selectStartAt = %s, selectEndAt = %s", self.selectStartAt, self.selectEndAt);
end

function Input:handleCopy()
    if (not self:IsSelected()) then return end
    local selectedText = self:GetSelectedText();
    ParaMisc.CopyTextToClipboard(selectedText);
end

function Input:handleCut()
    self:handleCopy();
    self:DeleteSelected();
end

function Input:handlePaste()
    local clip = ParaMisc.GetTextFromClipboard();
    self:InsertTextCmd(clip)
end

function Input:handleHome()
end
function Input:handleEnd()
end

function Input:handleMoveToNextChar()
    InputDebug("handleMoveToNextChar");
    self:ClearSelected();
    self:SetShowCursor(true);
    self:AdjustCursorAt(1, "move");
end
function Input:handleSelectNextChar()
    InputDebug.Format("handleSelectNextChar Before selectStartAt = %s, selectEndAt = %s", self.selectStartAt, self.selectEndAt);
    self.selectEndAt = self.selectEndAt or self.cursorAt - 1;
    self.selectEndAt = self.selectEndAt + 1;
    self.selectEndAt = math.max(math.min(self.selectEndAt, self.text:length()), 1);
    self.selectStartAt = self.selectEndAt >= self.cursorAt and self.cursorAt or self.cursorAt -1;
    InputDebug.Format("handleSelectNextChar After selectStartAt = %s, selectEndAt = %s", self.selectStartAt, self.selectEndAt);
end
function Input:handleMoveToPrevChar()
    InputDebug("handleMoveToPrevChar");
    self:ClearSelected();
    self:SetShowCursor(true);
    self:AdjustCursorAt(-1, "move");
end
function Input:handleSelectPrevChar()
    InputDebug("handleSelectPrevChar");
    self.selectEndAt = self.selectEndAt or self.cursorAt;
    self.selectEndAt = self.selectEndAt - 1;
    self.selectEndAt = math.max(math.min(self.selectEndAt, self.text:length()), 1);
    self.selectStartAt = self.selectEndAt >= self.cursorAt and self.cursorAt or self.cursorAt -1;
end
function Input:handleMoveToNextWord()
end
function Input:handleMoveToPrevWord()
end
function Input:handleSelectNextWord()
end
function Input:handleSelectPrevWord()
end
function Input:OnKeyDown(event)
    if (not self:IsFocus()) then return end
    if (self:IsReadOnly()) then return end
    event:accept();

	local keyname = event.keyname;
	if (keyname == "DIK_RETURN") then self:handleReturn(event) 
	elseif (keyname == "DIK_ESCAPE") then self:handleEscape(event)
	elseif (keyname == "DIK_BACKSPACE") then self:handleBackspace(event)
	elseif (event:IsKeySequence("Undo")) then self:handleUndo(event)
	elseif (event:IsKeySequence("Redo")) then self:handleRedo(event)
	elseif (event:IsKeySequence("SelectAll")) then self:handleSelectAll(event)
	elseif (event:IsKeySequence("Copy")) then self:handleCopy(event)
	elseif (event:IsKeySequence("Paste")) then self:handlePaste(event, "Clipboard");
	elseif (event:IsKeySequence("Cut")) then self:handleCut(event)
	elseif (event:IsKeySequence("MoveToStartOfLine") or event:IsKeySequence("MoveToStartOfBlock")) then self:handleHome(event, false)
    elseif (event:IsKeySequence("MoveToEndOfLine") or event:IsKeySequence("MoveToEndOfBlock")) then self:handleEnd(event, false)
    elseif (event:IsKeySequence("SelectStartOfLine") or event:IsKeySequence("SelectStartOfBlock")) then self:handleHome(event, true)
    elseif (event:IsKeySequence("SelectEndOfLine") or event:IsKeySequence("SelectEndOfBlock")) then self:handleEnd(event, true)
	elseif (event:IsKeySequence("MoveToNextChar")) then self:handleMoveToNextChar(event)
	elseif (event:IsKeySequence("SelectNextChar")) then self:handleSelectNextChar(event)
	elseif (event:IsKeySequence("MoveToPreviousChar")) then self:handleMoveToPrevChar(event)
	elseif (event:IsKeySequence("SelectPreviousChar")) then self:handleSelectPrevChar(event)
	elseif (event:IsKeySequence("MoveToNextWord")) then self:handleMoveToNextWord(event)
    elseif (event:IsKeySequence("MoveToPreviousWord")) then self:handleMoveToPrevWord(event)
    elseif (event:IsKeySequence("SelectNextWord")) then self:handleSelectNextWord(event)
    elseif (event:IsKeySequence("SelectPreviousWord")) then self:handleSelectPrevWord(event)
    elseif (event:IsKeySequence("Delete")) then self:handleDelete(event)
    elseif (event:IsFunctionKey() or event.ctrl_pressed) then 
    else -- 处理普通输入
	end
end

function Input:OnKey(event)
    if (not self:IsFocus()) then return end
    if (self:IsReadOnly()) then return end
    event:accept();

    local commitString = event:commitString();

    -- 忽略控制字符
    local char1 = string.byte(commitString, 1);
	if(char1 <= 31) then return end
    
    -- 添加新文本
    self:InsertTextCmd(commitString, self.cursorAt);
end

-- 检测输入是否合法
function Input:CheckInputText(text)
    local inputType = self:GetAttrStringValue("type", "text");
    if (inputType == "number") then
        return string.match(text, "^[%d%.]*$");
    end
    return true;
end

function Input:InsertTextCmd(text, startAt)
    if (not self:CheckInputText(text)) then return end
    
    -- 先删除已选择的文本
    if (self:IsSelected()) then self:DeleteSelected() end

    if (not text or text == "") then return end
    startAt = startAt or self.cursorAt;
    local textLength = UniString:new(text):length();
    local endAt = startAt + textLength - 1;
    table.insert(self.undoCmds, {startAt = startAt, endAt = endAt, action = "insert", text = text});
    InputDebug.Format("InsertTextCmd before cursorAt = %s, startAt = %s, endAt = %s, text = %s", self.cursorAt, startAt, endAt, self:GetValue());
    self:InsertText(startAt, endAt, text);
    InputDebug.Format("InsertTextCmd after cursorAt = %s, startAt = %s, endAt = %s, text = %s", self.cursorAt, startAt, endAt, self:GetValue());
end

function Input:InsertText(startAt, endAt, text)
    self.text:insert(startAt - 1, text);
    self:UpdateValue();
    if (startAt <= self.cursorAt) then self:AdjustCursorAt(endAt - startAt + 1) end
end

function Input:DeleteSelected()
    if (not self:IsSelected()) then return end
    local selectStartAt, selectEndAt = self:GetSelected();
    self:DeleteTextCmd(selectStartAt, selectEndAt - selectStartAt + 1);
    self:ClearSelected();
end

function Input:DeleteTextCmd(startAt, count)
    if (not startAt or not count or count == 0) then return end
    local endAt = startAt + count - 1;
    if (endAt < startAt) then startAt, endAt = endAt, startAt end
    if (endAt < 1) then return end
    startAt = math.max(startAt, 1);
    table.insert(self.undoCmds, {startAt = startAt, endAt = endAt, action = "delete", text = self.text:sub(startAt, endAt)});
    InputDebug.Format("DeleteTextCmd before cursorAt = %s, startAt = %s, endAt = %s, text = %s", self.cursorAt, startAt, endAt, self:GetValue());
    self:DeleteText(startAt, endAt);
    InputDebug.Format("DeleteTextCmd after cursorAt = %s, startAt = %s, endAt = %s, text = %s", self.cursorAt, startAt, endAt, self:GetValue());
end

function Input:DeleteText(startAt, endAt)
    local count = endAt - startAt + 1;
    if (self.cursorAt <= startAt) then
    elseif (self.cursorAt >= endAt) then self:AdjustCursorAt(-count)
    else self:AdjustCursorAt(startAt - self.cursorAt) end 
    self.text:remove(startAt, count);
    self:UpdateValue();
end

function Input:GetText()
    if (self:GetAttrStringValue("type") == "password") then
        return UniString:new(string.rep("*", self.text:length()));
    end
    return self.text;
end

function Input:UpdateValue()
    local value = self.text:GetText();
    if (self:GetValue() == value) then return end
    self:SetValue(value);
    self:OnChange(value);
end

-- 调整光标的位置, 调整前文本需完整, 因此添加需先添加后调整光标, 移除需先调整光标后移除
function Input:AdjustCursorAt(offset, action)
    if (not offset or offset == 0 or not self.cursorX or not self.cursorWidth) then return end
    InputDebug.Format("AdjustCursorAt Before cursorAt = %s, offset = %s, cursorX = %s", self.cursorAt, offset, self.cursorX);
    local text = self:GetText();
    local cursorAt, maxAt = self.cursorAt + offset, text:length() + 1;
    -- 保存光标位置的正确性
    if (cursorAt > maxAt) then offset = maxAt - self.cursorAt end
    if (cursorAt < 1) then offset = 1 - self.cursorAt end
    if (offset == 0) then return end

    local x, y, w, h = self:GetContentGeometry();
    local startAt, endAt = self.cursorAt, self.cursorAt + offset;
    if (startAt > endAt) then startAt, endAt = endAt, startAt end
    local text = text:sub(startAt, endAt - 1);
    local textWidth = text:GetWidth(self:GetFont());
    local maxX = w - self.cursorWidth;
    self.cursorAt = self.cursorAt + offset;

    -- 添加, 移除字符调整光标需要处理scrollX
    if (offset > 0) then   -- 添加字符
        self.cursorX = self.cursorX + textWidth;
        if (self.cursorX > maxX) then
            self.scrollX = self.scrollX + self.cursorX - maxX;
            self.cursorX = maxX;
        end
    else                   -- 左移除字符
        if (action == "move") then
            if (self.cursorX >= textWidth) then
                self.cursorX = self.cursorX - textWidth;
            else
                self.scrollX = self.scrollX + self.cursorX - textWidth;
                self.cursorX = 0;
                self.scrollX = math.max(self.scrollX, 0);
            end
        else 
            if (self.scrollX > textWidth) then
                self.scrollX = self.scrollX - textWidth;
            else
                self.cursorX = self.cursorX + self.scrollX - textWidth;
                self.cursorX = math.max(self.cursorX, 0);
                self.scrollX = 0;
            end
        end
    end
    InputDebug.Format("AdjustCursorAt After cursorAt = %s, offset = %s, cursorX = %s", self.cursorAt, offset, self.cursorX);
end

function Input:RenderCursor(painter)
    if (self:IsReadOnly()) then return end
    
    local x, y, w, h = self:GetContentGeometry();
    local cursorWidth = self.cursorWidth or 1;
    local cursorHeight = h; -- self.cursorHeight or self:GetStyle():GetLineHeight(); 
    local cursorX = self.cursorX or 0;
    local cursorY = self.cursorY or 0;
    self.cursorX, self.cursorY, self.cursorWidth, self.cursorHeight = cursorX, cursorY, cursorWidth, cursorHeight;
    
    self.cursorShowHideTickCount = self.cursorShowHideTickCount + 1;
    if (self.cursorShowHideTickCount > CursorShowHideMaxTickCount) then 
        self.cursorShowHideTickCount = 0;
        self:SetShowCursor(not self:IsShowCursor());
    end

    if (self:IsShowCursor() and self:IsFocus()) then
        painter:SetPen(self:GetColor());
    else
        painter:SetPen("#00000000");
    end
    painter:DrawRectTexture(x + cursorX, y + cursorY, cursorWidth, cursorHeight);
    -- painter:DrawRectTexture(cursorX, cursorY, cursorWidth, cursorHeight);
end

-- 绘制内容
function Input:RenderContent(painter)
    local scrollX, text = self.scrollX, self:GetText();
    local x, y, w, h = self:GetContentGeometry();
    local fontSize = self:GetFontSize();

    -- painter:Translate(x, y);
    self:RenderCursor(painter);

    painter:Save();
    painter:SetClipRegion(x, y, w, h);
    painter:Translate(-scrollX, 0);
    
    -- 渲染选择背景
    if (self:IsSelected()) then
        painter:SetPen("#3390ff");
        local selectStartAt, selectEndAt = self:GetSelected();
        local selectStartX = text:sub(1, selectStartAt - 1):GetWidth(self:GetFont());
        local selectEndX = text:sub(1, selectEndAt):GetWidth(self:GetFont());
        painter:DrawRectTexture(x + selectStartX, y + 0, selectEndX - selectStartX, h);
    end
    
    painter:SetFont(self:GetFont());
    painter:SetPen(self:GetColor());
    local value = tostring(text);
    if (self:IsFocus() or value ~= "") then
        painter:DrawText(x, y + (h - fontSize) / 2, tostring(value));
    else 
        painter:SetPen("#A8A8A8"); -- placeholder color;
        painter:DrawText(x, y + (h - fontSize) / 2, self:GetAttrStringValue("placeholder", ""));
    end
    painter:Translate(scrollX, 0);
    painter:Restore();
    -- painter:Translate(-x, -y);
end

function Input:GetAtByPos(x, y)
    local cursorX = self.scrollX + x;
    local text = _guihelper.AutoTrimTextByWidth(tostring(self:GetText()), cursorX, self:GetFont());
    local textlen = ParaMisc.GetUnicodeCharNum(text);
    local textWidth = _guihelper.GetTextWidth(text, self:GetFont());
    while (textWidth > cursorX and textlen > 0) do
        textlen = textlen - 1;
        text = ParaMisc.UniSubString(text, 1, textlen);
        textWidth = _guihelper.GetTextWidth(text, self:GetFont());
    end

    InputDebug.Format("GetAtByPos, x = %s, textWidth = %s textlen = %s, scrollX = %s, cursorAt = %s, cursorX = %s", x, textWidth, textlen, self.scrollX, self.cursorAt, self.cursorX);

    return textlen + 1, textWidth - self.scrollX;
end

function Input:GloablToContentGeometryPos(x, y)
    local parentScreenX, parentScreenY = self:GetParentElement():GetScreenPos();
    local contentX, contentY = self:GetContentGeometry();
    return x - parentScreenX - contentX, y - parentScreenY - contentY;
end

function Input:OnClick(event)
    if (not self:IsFocus()) then self:FocusIn() end
end

function Input:OnMouseDown(event)
    if (not self:IsFocus()) then self:FocusIn() end
    local x, y = self:GloablToContentGeometryPos(event.x, event.y);
    self:ClearSelected();
    self.cursorAt, self.cursorX = self:GetAtByPos(x, y);
    self.mouseDown = true;
    self:CaptureMouse();
    self.mouseStartScreenX, self.mouseStartScreenY = ParaUI.GetMousePosition(); 
    self.mouseLastScreenX, self.mouseLastScreenY = self.mouseStartScreenX, self.mouseStartScreenY;

    InputDebug.Format("OnMouseDown, x = %s, scrollX = %s, cursorAt = %s, cursorX = %s", x, self.scrollX, self.cursorAt, self.cursorX);

    event:accept();
end

function Input:OnMouseMove(event)
    if (not self.mouseDown) then return end
    local sx, sy = self:GetScreenPos();
    local x, y = ParaUI.GetMousePosition();
    if (not self:IsContainPoint(x, y)) then return self:OnMouseUp() end
    local cursorAt = self:GetAtByPos(self:GloablToContentGeometryPos(x, y));
    self.selectStartAt = cursorAt < self.cursorAt and self.cursorAt - 1 or self.cursorAt;
    self.selectEndAt = cursorAt;
end

function Input:OnMouseUp(event)
    self:ReleaseMouseCapture();
    self.mouseDown = false;
    if (not self:IsSelected()) then
        self:ClearSelected();
    end 
end