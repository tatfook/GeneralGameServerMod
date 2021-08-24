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

    local delay_tick_count = delay and (math.floor(delay * __get_loop_tick_count__() / 1000));
    local interval_tick_count = interval and (math.floor(interval * __get_loop_tick_count__() / 1000));
    local last_tick_count = __get_tick_count__();

    local co_callback = __coroutine_wrap__(function()
        while(not self:IsStop()) do 
            callback(self);
            __coroutine_yield__();
        end
    end);

    self.TimerCallBack = function()
        local cur_tick_count = __get_tick_count__();
        local tick_count = cur_tick_count - last_tick_count;

        -- timeout
        if (delay_tick_count and tick_count >= delay_tick_count) then
            last_tick_count = cur_tick_count;
            delay_tick_count = nil; -- 清掉, 防止再次执行
            co_callback(self);
            return ;
        end

        -- interval
        if (interval_tick_count and tick_count >= interval_tick_count) then
            last_tick_count = cur_tick_count;
            co_callback(self);
            return;
        end

        if (not delay_tick_count and not interval_tick_count) then
            self:Stop();
        end
    end

    RegisterTickCallBack(self.TimerCallBack);

    return self;
end

function Timer:IsStop()
    return self.TimerCallBack == nil;
end

function Timer:Stop()
    if (not self.TimerCallBack) then return end
    RemoveTickCallBack(self.TimerCallBack);
    self.TimerCallBack = nil;
end

function Timer.Timeout(delay, callback)
    return Timer:new():Start(delay, nil, callback);
end

function Timer.Interval(interval, callback)
    return Timer:new():Start(nil, interval, callback);
end

function SetTimeout(timeout, callback)
    return Timer.Timeout(timeout, callback);
end

function ClearTimeout(timer)
    timer:Stop();
end

function SetInterval(interval, callback)
    return Timer.Interval(interval, callback);
end

function ClearInterval(timer)
    timer:Stop();
end

-- -- 兼容
-- function Delay(delay, callback)
--     return SetTimeout(delay, callback);
-- end


