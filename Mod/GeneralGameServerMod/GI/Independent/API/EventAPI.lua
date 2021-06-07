--[[
Title: API
Author(s):  wxa
Date: 2021-06-01
Desc: API 模板文件
use the lib:
------------------------------------------------------------
local API = NPL.load("Mod/GeneralGameServerMod/GI/Independent/API/API.lua");
------------------------------------------------------------
]]
local UIAPI = NPL.export()


-- local function SetTimeout(CodeEnv, timeout, callback)
--     local timer;
--     timer = commonlib.Timer:new({callbackFunc = function ()
--         CodeEnv.__timers__[tostring(timer)] = nil;
--         CodeEnv.Independent.Call(callback);
--     end})
--     CodeEnv.__timers__[tostring(timer)] = timer; 
--     timer:Change(timeout);
-- end

-- local function Timer(interval,callback)
--     local wrapper;
--     local timer;
--     timer = commonlib.Timer:new({callbackFunc = function ()
--         wrapper();
--     end})
--     environment.__timer[tostring(timer)] = timer; 
--     timer:Change(interval,interval);
--     local t = {stop = function ()
--         timer:Change();
--     end}
--     wrapper = function () Independent.call(callback, t) end;
--     return t;
-- end)

local function RegisterTimerCallBack(CodeEnv, callback)
    if (type(callback) ~= "function") then return end 
    CodeEnv.__timer_callback__[tostring(callback)] = callback;
end

local function RemoveTimerCallBack(CodeEnv, callback)
    if (type(callback) ~= "function") then return end 
    CodeEnv.__timer_callback__[tostring(callback)] = nil;
end

local EventType = {
    TIMER = "timer",
    MOUSE = "mouse",
    MOUSE_DOWN = "mouse_down",
    MOUSE_MOVE = "mouse_move",
    MOUSE_UP = "mouse_up",
    MOUSE_WHEEL = "mouse_wheel",
    KEY_DOWN = "key_down",
    KEY_UP = "key_up",
}

local function RegisterEventCallBack(CodeEnv, eventType, callback)
    if (type(callback) ~= "function" or type(eventType) ~= "string") then return end 
    CodeEnv.__event_callback__ = CodeEnv.__event_callback__[eventType] or {};
    CodeEnv.__timer_callback__[eventType][tostring(callback)] = callback;
end

local function RemoveEventCallBack(CodeEnv, callback)
    if (type(callback) ~= "function" or type(eventType) ~= "string") then return end 
    CodeEnv.__event_callback__ = CodeEnv.__event_callback__[eventType] or {};
    CodeEnv.__event_callback__[eventType][tostring(callback)] = nil;
end

setmetatable(API, {
    __call = function(_, CodeEnv)
        CodeEnv.EventType = EventType;
        CodeEnv.RegisterTimerCallBack = function(...) return RegisterTimerCallBack(CodeEnv, ...) end
        CodeEnv.RemoveTimerCallBack = function(...) return RemoveTimerCallBack(CodeEnv, ...) end
        CodeEnv.RegisterEventCallBack = function(...) return RegisterEventCallBack(CodeEnv, ...) end
        CodeEnv.RemoveEventCallBack = function(...) return RemoveEventCallBack(CodeEnv, ...) end
    end
});
