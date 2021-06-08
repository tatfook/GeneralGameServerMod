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

local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController");

local EventAPI = NPL.export();

local __code_env__ = nil;

local EventType = {
    MAIN = "main",
    LOOP = "loop",
    CLEAR = "clear",

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

local function TriggerEventCallBack(CodeEnv, eventType, ...)
    local Independent = CodeEnv.Independent;
    local callbackMap = CodeEnv.__event_callback__[eventType] or {};
    for _, callback in pairs(callbackMap) do 
        Independent:Call(callback, ...);
    end
end

local function IsKeyDown(...)
    return ParaUI.IsKeyPressed(...)
end 

local function GetUserEventName(eventName)
    return string.format("USER_EVENT_%s", eventName);
end
local function On(eventName, callback)
    RegisterEventCallBack(__code_env__, GetUserEventName(eventName), callback);
end

local function Off(eventName, callback)
    RemoveEventCallBack(__code_env__, GetUserEventName(eventName), callback);
end

local function Emit(eventName, ...)
    TriggerEventCallBack(__code_env__, GetUserEventName(eventName), ...);
end

setmetatable(EventAPI, {
    __call = function(_, CodeEnv)
        __code_env__ = CodeEnv;

        CodeEnv.EventType = EventType;
        CodeEnv.RegisterTimerCallBack = function(...) return RegisterEventCallBack(CodeEnv, EventType.LOOP, ...) end
        CodeEnv.RemoveTimerCallBack = function(...) return RemoveEventCallBack(CodeEnv, EventType.LOOP, ...) end
        CodeEnv.RegisterEventCallBack = function(...) return RegisterEventCallBack(CodeEnv, ...) end
        CodeEnv.RemoveEventCallBack = function(...) return RemoveEventCallBack(CodeEnv, ...) end
        CodeEnv.TriggerEventCallBack = function(...) return TriggerEventCallBack(CodeEnv, ...) end 
        
        -- 用户事件机制
        CodeEnv.On = On;
        CodeEnv.Off = Off;
        CodeEnv.Emit = Emit;

        CodeEnv.IsKeyDown = IsKeyDown;

        local SceneContext = CodeEnv.SceneContext;
        SceneContext:SetMouseEventCallBack(function(...) TriggerEventCallBack(CodeEnv, EventType.MOUSE, ...) end);
        SceneContext:SetMousePressEventCallBack(function(...) TriggerEventCallBack(CodeEnv, EventType.MOUSE_DOWN, ...) end);
        SceneContext:SetMouseMoveEventCallBack(function(...) TriggerEventCallBack(CodeEnv, EventType.MOUSE_MOVE, ...) end);
        SceneContext:SetMouseReleaseEventCallBack(function(...) TriggerEventCallBack(CodeEnv, EventType.MOUSE_UP, ...) end);
        SceneContext:SetMouseWheelEventCallBack(function(...) TriggerEventCallBack(CodeEnv, EventType.MOUSE_WHEEL, ...) end);
        SceneContext:SetKeyEventCallBack(function(...) TriggerEventCallBack(CodeEnv, EventType.KEY, ...) end);
        SceneContext:SetKeyPressEventCallBack(function(...) TriggerEventCallBack(CodeEnv, EventType.KEY_DOWN, ...) end);
        SceneContext:SetKeyReleaseEventCallBack(function(...) TriggerEventCallBack(CodeEnv, EventType.KEY_UP, ...) end);
    end
});
