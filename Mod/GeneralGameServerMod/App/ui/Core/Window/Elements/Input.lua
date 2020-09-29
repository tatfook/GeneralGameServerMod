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

local InputDebug = GGS.Debug.GetModuleDebug("InputDebug");
local CursorShowHideMaxTickCount = 30;

Input:Property("Name", "Input");
Input:Property("Value");                                -- 按钮文本值

Input:Property("BaseStyle", {
    NormalStyle = {
        ["border-width"] = 1,
        ["border-color"] = "#cccccc",
        ["color"] = "#000000",
        ["height"] = 20,
        ["width"] = 100,
        ["padding-left"] = 4, 
        ["padding-right"] = 4, 
        ["padding-top"] = 2, 
        ["padding-bottom"] = 2, 
    }
});

function Input:ctor()
    self.cursorShowHideTickCount = 0;
    self.isShowCursor = false;
    self.cursorX, self.cursorY, self.cursorWidth, self.cursorHeight = 0, 0, nil, nil;
    self.cursorLine = 1;  -- 光标行
    self.cursorAt = 1;    -- 光标位置 占据下一个输入位置
    self.scrollX = 0;     -- 横向滚动的位置 
    self.commands = {};   -- 命令
    self.text = UniString:new();
    -- select
    self.selectStartAt = 0;
    self.selectEndAt = 0;
end

-- 是否选择
function Input:IsSelected()
    return self.selectStartAt > 0 and self.selectEndAt > 0;
end

function Input:IsCanFocus()
    return true;
end

function Input:IsReadOnly()
    return self:GetAttrBoolValue("readonly");
end

function Input:handleReturn()
end

function Input:handleEscape()
end

function Input:handleBackspace()
    self:DeleteTextCmd(self.cursorAt - 1, 1);
end

function Input:handleDelete()
    self:DeleteTextCmd(self.cursorAt, 1);
end

function Input:handleUndo()
end

function Input:handleRedo()
end

function Input:handleSelectAll()
end

function Input:handleCopy()
end
function Input:handleCut()
end
function Input:handlePaste()
end

function Input:handleHome()
end
function Input:handleEnd()
end

function Input:handleMoveToNextChar()
    self:AdjustCursorAt(1, "move");
end
function Input:handleSelectNextChar()
end
function Input:handleMoveToPrevChar()
    self:AdjustCursorAt(-1, "move");
end
function Input:handleSelectPrevChar()
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
    
    self:InsertTextCmd(commitString, self.cursorAt);
end

function Input:InsertTextCmd(text, startAt)
    if (not startAt or not text or text == "") then return end
    text = UniString:new(text);
    local textLength = text:length();
    local endAt = startAt + textLength - 1;
    table.insert(self.commands, {startAt = startAt, endAt = endAt, action = "add", text = text});
    InputDebug.Format("InsertTextCmd before cursorAt = %s, startAt = %s, endAt = %s, text = %s", self.cursorAt, startAt, endAt, self:GetValue());
    self.text:insert(startAt - 1, text);
    if (startAt <= self.cursorAt) then self:AdjustCursorAt(textLength) end
    self:UpdateValue();
    InputDebug.Format("InsertTextCmd after cursorAt = %s, startAt = %s, endAt = %s, text = %s", self.cursorAt, startAt, endAt, self:GetValue());
end

function Input:DeleteTextCmd(startAt, count)
    if (not startAt or not count or count == 0) then return end
    local endAt = startAt + count - 1;
    if (endAt < startAt) then startAt, endAt = endAt, startAt end
    InputDebug.Format("DeleteTextCmd before cursorAt = %s, startAt = %s, endAt = %s, text = %s", self.cursorAt, startAt, endAt, self:GetValue());
    if (startAt < 1) then return end
    table.insert(self.commands, {startAt = startAt, endAt = endAt, action = "remove", text = self.text:sub(startAt, endAt)});
    if (self.cursorAt <= startAt) then
    elseif (self.cursorAt >= endAt) then self:AdjustCursorAt(-math.abs(count))
    else self:AdjustCursorAt(startAt - self.cursorAt) end 
    self.text:remove(startAt, count);
    self:UpdateValue();
    InputDebug.Format("DeleteTextCmd after cursorAt = %s, startAt = %s, endAt = %s, text = %s", self.cursorAt, startAt, endAt, self:GetValue());
end

function Input:UpdateValue()
    local value = self.text:GetText();
    if (self:GetValue() == value) then return end
    self:SetValue(value);
    -- self:OnChange(value);
end

-- 调整光标的位置, 调整前文本需完整, 因此添加需先添加后调整光标, 移除需先调整光标后移除
function Input:AdjustCursorAt(offset, action)
    if (not offset or offset == 0 or not self.cursorX or not self.cursorWidth) then return end
    InputDebug.Format("AdjustCursorAt Before cursorAt = %s, offset = %s, cursorX = %s", self.cursorAt, offset, self.cursorX);
    local cursorAt, maxAt = self.cursorAt + offset, self.text:length() + 1;
    -- 保存光标位置的正确性
    if (cursorAt > maxAt) then offset = maxAt - self.cursorAt end
    if (cursorAt < 1) then offset = 1 - self.cursorAt end
    if (offset == 0) then return end

    local x, y, w, h = self:GetContentGeometry();
    local startAt, endAt = self.cursorAt, self.cursorAt + offset;
    if (startAt > endAt) then startAt, endAt = endAt, startAt end
    local text = self.text:sub(startAt, endAt - 1);
    local textWidth = text:GetWidth();
    local maxX = w - self.cursorWidth;
    self.cursorAt = self.cursorAt + offset;

    -- 方向键移动光标
    if (action == "move") then
        self.cursorX = self.cursorX + (offset > 0 and textWidth or -textWidth);
        self.cursorX = math.max(self.cursorX, 0);
        self.cursorX = math.min(self.cursorX, maxX);
        return ;
    end

    -- 添加, 移除字符调整光标需要处理scrollX
    if (offset > 0) then   -- 添加字符
        self.cursorX = self.cursorX + textWidth;
        if (self.cursorX > maxX) then
            self.scrollX = self.scrollX + self.cursorX - maxX;
            self.cursorX = maxX;
        end
    else                   -- 左移除字符
        if (self.scrollX > textWidth) then
            self.scrollX = self.scrollX - textWidth;
        else
            self.cursorX = self.cursorX + self.scrollX - textWidth;
            self.cursorX = math.max(self.cursorX, 0);
            self.scrollX = 0;
        end
    end

    InputDebug.Format("AdjustCursorAt After cursorAt = %s, offset = %s, cursorX = %s", self.cursorAt, offset, self.cursorX);

end

function Input:RenderCursor(painter)
    local x, y, w, h = self:GetContentGeometry();
    local cursorWidth = self.cursorWidth or 1;
    local cursorHeight = self.cursorHeight or self:GetStyle():GetLineHeight(); 
    local cursorX = self.cursorX or 0;
    local cursorY = self.cursorY or 0;
    self.cursorX, self.cursorY, self.cursorWidth, self.cursorHeight = cursorX, cursorY, cursorWidth, cursorHeight;
    
    if (not self:IsFocus()) then return end

    self.cursorShowHideTickCount = self.cursorShowHideTickCount + 1;
    if (self.cursorShowHideTickCount > CursorShowHideMaxTickCount) then 
        self.cursorShowHideTickCount = 0;
        self.isShowCursor = not self.isShowCursor;
    end

    if (self.isShowCursor) then
        painter:SetPen(self:GetColor());
    else
        painter:SetPen("#00000000");
    end

    painter:DrawRectTexture(x + cursorX, y + cursorY, cursorWidth, cursorHeight);
end

-- 绘制内容
function Input:RenderContent(painter)
    self:RenderCursor(painter);
    local x, y, w, h = self:GetContentGeometry();
    local scrollX, text = self.scrollX, self:GetValue();

    painter:Save();
    painter:SetClipRegion(x, y, w, h);
    painter:Translate(-scrollX, 0);
    painter:SetPen(self:GetColor());
    painter:DrawText(x, y, text);
    painter:Translate(scrollX, 0);
    painter:Restore();
end

function Input:OnMouseDown(event)
    if (not self:IsFocus()) then self:FocusIn() end
    local cursorX = self.scrollX + event:pos():x();
    local text = _guihelper.AutoTrimTextByWidth(self:GetValue(), cursorX, self:GetFont());
    local textlen = string.len(text);
    local textWidth = _guihelper.GetTextWidth(text, self:GetFont());
    if (textWidth > cursorX and textlen > 0) then
        textlen = textlen - 1;
        text = string.sub(text, 1, textlen);
        textWidth = _guihelper.GetTextWidth(text, self:GetFont());
    end

    self.cursorX = textWidth - self.scrollX;
    self.cursorAt = textlen + 1;

    InputDebug.Format("OnMouseDown, x = %s, text = %s, textWidth = %s, scrollX = %s, cursorAt = %s, cursorX = %s", event:pos():x(), text, textWidth, self.scrollX, self.cursorAt, self.cursorX);

    event:accept();
end
