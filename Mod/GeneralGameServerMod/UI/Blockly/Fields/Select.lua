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

function Select:SetFieldValue(value)
    value = Select._super.SetFieldValue(self, value);
    self:SetLabel(self:GetLabelByValue(self:GetValue()));
end

function Select:GetFieldEditType()
    return "select";
end

