--[[
Title: Label
Author(s): wxa
Date: 2020/6/30
Desc: 输入字段
use the lib:
-------------------------------------------------------
local Variable = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Variable.lua");
-------------------------------------------------------
]]
local Const = NPL.load("../Const.lua");
local Field = NPL.load("./Field.lua", IsDevEnv);

local Variable = commonlib.inherit(Field, NPL.export());
local variable_options = {};

function Variable:Init(block, option)
    Variable._super.Init(self, block, option);

    self:SetAllowNewSelectOption(true);

    return self;
end

function Variable:GetValueAsString()
    return self:GetValue();
end

function Variable:GetFieldEditType()
    return "select";
end

function Variable:OnEndEdit()
    local vartype = self:GetVarType();
    local options = self:GetVarOptions();
    local index, size = 1, #options;
    local exist = {};
    self:GetBlockly():ForEach(function(blockInputField)
        if (not blockInputField:IsField() or blockInputField:GetType() ~= "field_variable" or blockInputField:GetVarType() ~= vartype) then return end
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

function Variable:GetVarOptions()
    local vartype = self:GetVarType();
    variable_options[vartype] = variable_options[vartype] or {};
    return variable_options[vartype];
end

function Variable:GetVarType()
    return self:GetOption().vartype or "any";
end

function Variable:GetOptions()
    return self:GetVarOptions();
end
