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
    local index, size = 1, #variable_options;

    self:GetBlockly():ForEach(function(blockInputField)
        if (not blockInputField:IsField() or blockInputField:GetType() ~= "field_variable") then return end
        local varname = blockInputField:GetValue();
        if (varname and varname ~= "") then
            variable_options[index] = {varname, varname};
            index = index + 1;
        end
    end);

    for i = index, size do
        variable_options[i] = nil;
    end
    
    table.sort(variable_options, function(item1, item2)
        return item1[1] < item2[1];
    end);
end


function Variable:GetOptions()
    return variable_options;
end
