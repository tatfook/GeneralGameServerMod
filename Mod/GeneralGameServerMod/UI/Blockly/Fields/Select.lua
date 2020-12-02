--[[
Title: Label
Author(s): wxa
Date: 2020/6/30
Desc: 输入字段
use the lib:
-------------------------------------------------------
local Select = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Select.lua");
-------------------------------------------------------
]]
local SelectElement = NPL.load("../../Window/Elements/Select.lua", IsDevEnv);

local Const = NPL.load("../Const.lua", IsDevEnv);
local Input = NPL.load("./Input.lua", IsDevEnv);

local Select = commonlib.inherit(Input, NPL.export());


function Input:GetFieldEditElement(parentElement)
    local SelectFieldEditElement = SelectElement:new():Init({
        name = "select",
        attr = {
            style = "width: 100%; height: 100%; font-size: 14px;",
            autofocus = true,
        },
    }, parentElement:GetWindow(), parentElement);

    local option = self:GetOption();
    local options = type(option.options) == "table" and option.options or {};
    if (type(option.options) == "function") then options = option.options() end
    SelectFieldEditElement:SetAttrValue("value", self:GetValue());
    SelectFieldEditElement:SetAttrValue("options", options);
    SelectFieldEditElement:SetAttrValue("onselect", function(value, label)
        self:SetValue(value);
        self:SetText(label);
        self:FocusOut();
    end)

    return SelectFieldEditElement;
end