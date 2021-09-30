--[[
Title: Sandbox
Author(s):  wxa
Date: 2021-06-30
Desc: Sandbox
use the lib:
------------------------------------------------------------
local Sandbox = NPL.load("Mod/GeneralGameServerMod/Server/Sandbox/Sandbox.lua");
------------------------------------------------------------
]]

local Sandbox = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
