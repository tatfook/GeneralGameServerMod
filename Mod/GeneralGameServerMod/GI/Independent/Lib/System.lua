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


local System = module("System");

function sleep(sleep)
	local SleepLoopCallBack = nil;
	local sleepTo = GetTime() + (sleep or 0);
	local isSleeping = true;
	local function SleepLoopCallBack()
		local curtime = GetTime();
		isSleeping = curtime < sleepTo;
	end
	RegisterEventCallBack(EventType.LOOP, SleepLoopCallBack);
	while (isSleeping) do Independent:Yield() end
	RemoveEventCallBack(EventType.LOOP, SleepLoopCallBack);
end
