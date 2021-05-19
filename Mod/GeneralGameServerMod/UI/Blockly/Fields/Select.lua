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
local Options = NPL.load("../Options.lua");
local Field = NPL.load("./Field.lua", IsDevEnv);

local Select = commonlib.inherit(Field, NPL.export());
local select_options = {};

Select:Property("SelectType");

function Select:Init(block, option)
    Select._super.Init(self, block, option);

    local selectType = option.options == nil and self:GetName() or nil;
    if (type(option.options) == "string" and not Options[option.options]) then selectType = option.options end

    self:SetSelectType(selectType);
    self:SetAllowNewSelectOption(selectType and true or false);

    return self;
end

function Select:SetFieldValue(value)
    value = Select._super.SetFieldValue(self, value);
    self:SetLabel(self:GetLabelByValue(self:GetValue()));
end

function Select:GetFieldEditType()
    return "select";
end

function Select:GetOptions(bRefresh)
    local selectType = self:GetSelectType();
    if (not selectType) then return Select._super.GetOptions(self, bRefresh) end
    select_options[selectType] = select_options[selectType] or {};
    return select_options[selectType];
end

function Select:OnEndEdit()
    local selectType = self:GetSelectType();
    if (not self:IsAllowNewSelectOption() or not selectType) then return end

    local options = self:GetOptions();
    local index, size = 1, #options;
    local exist = {};
    self:GetBlockly():ForEachUI(function(blockInputField)
        if (not blockInputField:IsField() or not blockInputField:IsSelectType() or blockInputField:GetSelectType() ~= selectType) then return end
        local varname = blockInputField:GetValue();
        if (varname and varname ~= "" and not exist[varname]) then
            options[index] = {varname, varname};
            index = index + 1;
            exist[varname] = true;
        end
    end);

    for i = index, size do
        options[i] = nil;
    end
    
    table.sort(options, function(item1, item2)
        return item1[1] < item2[1];
    end);
end