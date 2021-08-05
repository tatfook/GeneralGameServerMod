--[[
Title: Scene
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local Scene = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/Scene.lua");
------------------------------------------------------------
]]
local Timer = require("Timer");
local Scene = module("Scene");

local MousePickTimer = nil;
function EnableMousePick(bEnable)
    if (not bEnable and MousePickTimer) then
        return MousePickTimer:Stop();
    end

    if (not MousePickTimer) then
        MousePickTimer = Timer.Interval(50, MousePickTimerCallBack);
    end
end

EnableMousePick(IsDevEnv);