--[[
Title: GGSPlayer
Author(s):  wxa
Date: 2021-06-01
Desc: GGS 玩家
use the lib:
------------------------------------------------------------
local GGSPlayer = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/GGSPlayer.lua");
------------------------------------------------------------
]]

local GGS = require("GGS");
local GGSPlayer = inherit(ToolBase, module("GGSPlayer"));

local __username__ = GetUserName();
local __players__ = GGS:Get("__players__", {});


function GGSPlayer:ctor()
end

GGSPlayer:InitSingleton();
