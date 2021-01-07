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
local SelectElement = NPL.load("../../Window/Elements/Select.lua", IsDevEnv);

local Const = NPL.load("../Const.lua", IsDevEnv);
local Select = NPL.load("./Select.lua", IsDevEnv);

local Variable = commonlib.inherit(Select, NPL.export());

function Variable:GetOptions()
    local options = {};
    self:GetBlockly():ForEach(function(blockInputField)
        if (not blockInputField:IsField() or blockInputField:GetType() ~= "field_variable") then return end
        local varname = blockInputField:GetFieldValue();
        if (varname and varname ~= "") then
            table.insert(options, 1, varname);
        end
    end)
    table.sort(options)
    for i, varname in ipairs(options) do
        options[i] = {varname, varname};
    end
    if (#options == 0) then
        options[1] = {"var", "var"};
        options[2] = {"key", "key"};
    end
    return options;
end

