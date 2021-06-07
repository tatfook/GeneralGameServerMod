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
local EventAPI = NPL.export()


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
    KEY = "key",
    KEY_DOWN = "key_down",
    KEY_UP = "key_up",
}

local function RegisterEventCallBack(CodeEnv, eventType, callback)
    if (type(callback) ~= "function" or type(eventType) ~= "string") then return end 
    CodeEnv.__event_callback__[eventType] = CodeEnv.__event_callback__[eventType] or {};
    CodeEnv.__event_callback__[eventType][tostring(callback)] = callback;
end

local function RemoveEventCallBack(CodeEnv, callback)
    if (type(callback) ~= "function" or type(eventType) ~= "string") then return end 
    CodeEnv.__event_callback__[eventType] = CodeEnv.__event_callback__[eventType] or {};
    CodeEnv.__event_callback__[eventType][tostring(callback)] = nil;
end

-- local function MouseEventCallBack(event)
-- end

-- local function MousePressEventCallBack(event)
-- end

-- local function MouseMoveEventCallBack(event)
-- end

-- local function MouseReleaseEventCallBack(event)
-- end

-- local function MouseWheelEventCallBack(event)
-- end

-- local function KeyEventCallBack(event)
-- end

-- local function KeyPressEventCallBack(event)
-- end

-- local function KeyReleaseEventCallBack(event)
-- end

local function EventCallBack(CodeEnv, eventType, event)
    local Independent = CodeEnv.Independent;
    local callbackMap = CodeEnv.__event_callback__[eventType] or {};
    for _, callback in pairs(callbackMap) do 
        Independent:Call(callback, event);
    end
end

setmetatable(EventAPI, {
    __call = function(_, CodeEnv)
        CodeEnv.EventType = EventType;
        CodeEnv.RegisterTimerCallBack = function(...) return RegisterTimerCallBack(CodeEnv, ...) end
        CodeEnv.RemoveTimerCallBack = function(...) return RemoveTimerCallBack(CodeEnv, ...) end
        CodeEnv.RegisterEventCallBack = function(...) return RegisterEventCallBack(CodeEnv, ...) end
        CodeEnv.RemoveEventCallBack = function(...) return RemoveEventCallBack(CodeEnv, ...) end

        local SceneContext = CodeEnv.SceneContext;
        SceneContext:SetMouseEventCallBack(function(...) EventCallBack(CodeEnv, EventType.MOUSE, ...) end);
        SceneContext:SetMousePressEventCallBack(function(...) EventCallBack(CodeEnv, EventType.MOUSE_DOWN, ...) end);
        SceneContext:SetMouseMoveEventCallBack(function(...) EventCallBack(CodeEnv, EventType.MOUSE_MOVE, ...) end);
        SceneContext:SetMouseReleaseEventCallBack(function(...) EventCallBack(CodeEnv, EventType.MOUSE_UP, ...) end);
        SceneContext:SetMouseWheelEventCallBack(function(...) EventCallBack(CodeEnv, EventType.MOUSE_WHEEL, ...) end);
        SceneContext:SetKeyEventCallBack(function(...) EventCallBack(CodeEnv, EventType.KEY, ...) end);
        SceneContext:SetKeyPressEventCallBack(function(...) EventCallBack(CodeEnv, EventType.KEY_DOWN, ...) end);
        SceneContext:SetKeyReleaseEventCallBack(function(...) EventCallBack(CodeEnv, EventType.KEY_UP, ...) end);
    end
});
