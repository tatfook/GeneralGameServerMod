--[[
Title: Label
Author(s): wxa
Date: 2020/6/30
Desc: 输入字段
use the lib:
-------------------------------------------------------
local Label = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Label.lua");
-------------------------------------------------------
]]
local InputElement = NPL.load("../../Window/Elements/Input.lua", IsDevEnv);

local Const = NPL.load("../Const.lua", IsDevEnv);
local Shape = NPL.load("../Shape.lua", IsDevEnv);
local Field = NPL.load("./Field.lua", IsDevEnv);
local Input = commonlib.inherit(Field, NPL.export());

local UnitSize = Const.UnitSize;

function Input:GetFieldEditElement(parentElement)
    local inputEditElement = self:GetInputEditElement();
    if (not inputEditElement) then
        inputEditElement = self:GetFieldInputEditElement(parentElement);
        self:SetInputEditElement(inputEditElement);
    end
    return inputEditElement;
end

function Input:GetFieldEditType()
    return "input";
end

function Input:OnBeginEdit()
    local inputEditElement = self:GetInputEditElement();
    if (inputEditElement) then inputEditElement:FocusIn() end
end

function Input:OnEndEdit()
    local inputEditElement = self:GetInputEditElement();
    if (inputEditElement) then inputEditElement:FocusOut() end
end

function Input:GetValueAsString()
    if (self:GetType() == "field_number") then 
        return string.format('%s', self:GetValue());
    else 
        return string.format('"%s"', self:GetValue());
    end
end