
--[[
Title: System
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local System = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/System.lua");
------------------------------------------------------------
]]

local Test = module("Test");

function Test.Print()
    print(GetTime, __running__, _G);
end
