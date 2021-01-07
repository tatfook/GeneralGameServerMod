--[[
Title: Global
Author(s): wxa
Date: 2020/6/30
Desc: 沙盒环境全局表
use the lib:
-------------------------------------------------------
local Global = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/Sandbox/Global.lua");
-------------------------------------------------------
]]

local Global = NPL.export();

local out = "";
setmetatable(Global, {__index = _G});

function Global.Print(obj)
    out = out .. tostring(obj) .. "\n";
end

function Global.GetOut()
    return out;
end

function Global.ClearOut()
    out = "";
end
