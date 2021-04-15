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
local DivElement = NPL.load("../../Window/Elements/Div.lua", IsDevEnv);
local InputElement = NPL.load("../../Window/Elements/Input.lua", IsDevEnv);
local SelectElement = NPL.load("../../Window/Elements/Select.lua", IsDevEnv);

local Const = NPL.load("../Const.lua");
local Field = NPL.load("./Field.lua", IsDevEnv);

local Select = commonlib.inherit(Field, NPL.export());

Select:Property("AllowNewOption", false, "IsAllowNewOption");  -- 是否允许新增选项

function Select:Init(block, opt)
    Select._super.Init(self, block, opt);

    self:SetLabel(self:GetLabelByValue(self:GetValue()));
    self:SetValue(self:GetValueByLablel(self:GetLabel()));

    self:SetAllowNewOption(opt.allowNewOption == true and true or false);
    
    return self;
end

function Select:UpdateWidthHeightUnitCount()
    local widthUnitCount, heightUnitCount = Select._super.UpdateWidthHeightUnitCount(self);
    if (not self:IsEdit()) then return widthUnitCount, heightUnitCount end

    local options = self:GetOptions();
    for _, option in ipairs(options) do 
        widthUnitCount = math.max(widthUnitCount, self:GetTextWidthUnitCount(option[1] or option.label));
    end

    return math.max(widthUnitCount, Const.MinEditFieldWidthUnitCount), heightUnitCount;
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
    return options[1] and (options[1][2] or options[1].value);
end

function Select:GetLabelByValue(value)
    local options = self:GetOptions();
    for _, option in ipairs(options) do
        if (option[2] == value or option.value == value) then return option[1] or option.label end
    end
    return options[1] and (options[1][1] or options[1].label);
end

function Select:SetFieldValue(value)
    value = Select._super.SetFieldValue(self, value);
    self:SetLabel(self:GetLabelByValue(self:GetValue()));
end

function Select:GetFieldEditType()
    return "select";
end

