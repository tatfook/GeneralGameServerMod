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

function Select:Init(block, opt)
    Select._super.Init(self, block, opt);

    local value = "";
    if (type(opt.text) == "function") then value = opt.text() 
    elseif (type(opt.text) == "string") then value = opt.text 
    else  end

    self:SetValue(value);
    self:SetLabel(self:GetLabelByValue(value));

    return self;
end

function Select:GetOptions()
    local option = self:GetOption();
    local options = type(option.options) == "table" and option.options or {};
    if (type(option.options) == "function") then options = option.options() end
    return options;
end

function Select:GetValueByLablel(label)
    local options = self:GetOptions();
    for _, option in ipairs(options) do
        if (option[1] == label or option.label == label) then return option[2] or option.value end
    end
    return "";
end

function Select:GetLabelByValue(value)
    local options = self:GetOptions();
    for _, option in ipairs(options) do
        if (option[2] == value or option.value == value) then return option[1] or option.label end
    end
    return "";
end

function Select:GetFieldEditElement(parentElement)
    local SelectFieldEditElement = SelectElement:new():Init({
        name = "select",
        attr = {
            style = "width: 100%; height: 100%; font-size: 14px;",
            autofocus = true,
        },
    }, parentElement:GetWindow(), parentElement);

    SelectFieldEditElement:SetAttrValue("value", self:GetValue());
    SelectFieldEditElement:SetAttrValue("options", self:GetOptions());
    SelectFieldEditElement:SetAttrValue("onselect", function(value, label)
        self:SetValue(value);
        self:SetLabel(label);
        self:FocusOut();
    end)

    return SelectFieldEditElement;
end