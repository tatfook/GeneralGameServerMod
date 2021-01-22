--[[
Title: Const
Author(s): wxa
Date: 2020/6/30
Desc: Const
use the lib:
-------------------------------------------------------
local Validator = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/Validator.lua");
-------------------------------------------------------
]]

local Validator = NPL.export();

function Validator.VarName(str)
    return string.match(str, "[a-zA-Z][a-zA-Z0-9_]*");
end

function Validator.FuncName(str)
    return string.match(str, "[a-zA-Z][a-zA-Z_]*");
end