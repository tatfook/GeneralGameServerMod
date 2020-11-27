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

    SelectFieldEditElement:SetAttrValue("value", self:GetValue());
    SelectFieldEditElement:SetAttrValue("options", {"选项1", "选项2", "选项3"});
    SelectFieldEditElement:SetAttrValue("onselect", function(value, label)
        self:SetValue(value);
        self:SetText(label);
        self:FocusOut();
    end)

    return SelectFieldEditElement;
end