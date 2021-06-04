--[[
Title: Timer
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local Timer = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/Timer.lua");
------------------------------------------------------------
]]

local Timer = inherit(nil, module("Timer"));

function Timer:ctor()
end

function Timer:Start(delay, interval, callback)
    if (type(callback) ~= "function" or self.TimerCallBack) then return self end
    if (type(delay) ~= "number" and type(interval) ~= "number") then return self end

    local lastTime = GetTime();
    self.TimerCallBack = function()
        local curTime = GetTime();
        local time = curTime - lastTime;

        -- timeout
        if (delay and time >= delay) then
            lastTime = curTime;
            delay = nil; -- 清掉, 防止再次执行
            callback(self);
            return ;
        end

        -- interval
        if (interval and time >= interval) then
            lastTime = curTime;
            callback(self);
            return;
        end

        if (not delay and not interval) then
            self:Stop();
        end
    end

    RegisterTimerCallBack(self.TimerCallBack);

    return self;
end

function Timer:Stop()
    if (not self.TimerCallBack) then return end
    RemoveTimerCallBack(self.TimerCallBack);
    self.TimerCallBack = nil;
end

function Timer.Timeout(delay, callback)
    return Timer:new():Start(delay, nil, callback);
end

function Timer.Interval(interval, callback)
    return Timer:new():Start(nil, interval, callback);
end