--[[
Title: Textarea
Author(s): wxa
Date: 2020/6/30
Desc: 标签字段
use the lib:
-------------------------------------------------------
local Textarea = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Textarea.lua");
-------------------------------------------------------
]]

local Const = NPL.load("../Const.lua");
local Shape = NPL.load("../Shape.lua");
local Field = NPL.load("./Field.lua", IsDevEnv);

local Textarea = commonlib.inherit(Field, NPL.export());

function Textarea:GetFieldEditType()
    return "textarea";
end

function Textarea:IsEditRender()
    return true;
end