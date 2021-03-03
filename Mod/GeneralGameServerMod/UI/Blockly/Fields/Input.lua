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
    local InputFieldEditElement = InputElement:new():Init({
        name = "input",
        attr = {
            style = "width: 100%; height: 100%; font-size: 14px;",
            value = self:GetValue(),
        },
    }, parentElement:GetWindow(), parentElement);

    InputFieldEditElement:SetAttrValue("type", self:GetType() == "field_number" and "number" or "text");
   
    local function InputFinish()
        local value = InputFieldEditElement:GetValue();
        self:SetFieldValue(value);
        self:SetLabel(tostring(self:GetValue()));
        self:FocusOut();
    end 

    InputFieldEditElement:SetAttrValue("onkeydown.enter", InputFinish);
    InputFieldEditElement:SetAttrValue("onblur", InputFinish);

    self.inputEl = InputFieldEditElement;

    return InputFieldEditElement;
end

function Input:OnBeginEdit()
    if (self.inputEl) then self.inputEl:FocusIn() end
end

function Input:OnEndEdit()
    if (self.inputEl) then self.inputEl:FocusOut() end
end

function Input:GetValueAsString()
    if (self:GetType() == "field_number") then 
        return string.format('%s', self:GetValue());
    else 
        return string.format('"%s"', self:GetValue());
    end
end