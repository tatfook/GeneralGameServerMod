--[[
Title: Net
Author(s):  wxa
Date: 2021-06-30
Desc: Net
use the lib:
------------------------------------------------------------
local Net = NPL.load("Mod/GeneralGameServerMod/Server/SandBox/Lib/Net.lua");
------------------------------------------------------------
]]

local Net = module("Net");

__cmd__("__net__", function(msg)
    local __action__ = msg.__action__;

    if (__action__ == "__connect__") then
    end

end)