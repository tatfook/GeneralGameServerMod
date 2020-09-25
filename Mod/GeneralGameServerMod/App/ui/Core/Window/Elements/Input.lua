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

Input:Property("Name", "Input");
Input:Property("Value");                                -- 按钮文本值

Input:Property("BaseStyle", {
    NormalStyle = {
        ["border-width"] = 1,
        ["border-color"] = "#cccccc",
        ["color"] = "#000000",
        ["height"] = 20,
        ["width"] = 100,
    }
});

function Input:ctor()
end

function Input:IsReadOnly()
    return self:GetAttrBoolValue("readonly");
end

function Input:handleCharInput()
end

function Input:handleReturn()
end

function Input:handleEscape()
end

function Input:handleBackspace()
end

function Input:handleDelete()
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
end
function Input:handleSelectNextChar()
end
function Input:handleMoveToPrevChar()
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
	-- echo({keyname, event.key_sequence});
	local unknown = false;
	if(keyname == "DIK_RETURN") then self:handleReturn(event) 
	elseif(keyname == "DIK_ESCAPE") then self:handleEscape(event)
	elseif(keyname == "DIK_BACKSPACE") then self:handleBackspace(event)
	elseif(event:IsKeySequence("Undo")) then self:handleUndo(event)
	elseif(event:IsKeySequence("Redo")) then self:handleRedo(event)
	elseif(event:IsKeySequence("SelectAll")) then self:handleSelectAll(event)
	elseif(event:IsKeySequence("Copy")) then self:handleCopy(event)
	elseif(event:IsKeySequence("Paste")) then self:handlePaste(event, "Clipboard");
	elseif(event:IsKeySequence("Cut")) then self:handleCut(event)
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
    else
        -- 处理普通输入
        self:handleCharInput(event);
	end
end
