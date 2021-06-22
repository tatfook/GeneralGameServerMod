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

    MOUSE_KEY = "mouse_key", -- 鼠标和按键
}

local function RegisterEventCallBack(eventType, callback)
    if (type(callback) ~= "function" or type(eventType) ~= "string") then return end 
    __code_env__.__event_callback__[eventType] = __code_env__.__event_callback__[eventType] or {};
    __code_env__.__event_callback__[eventType][tostring(callback)] = callback;
end

local function RemoveEventCallBack(eventType, callback)
    if (type(callback) ~= "function" or type(eventType) ~= "string") then return end 
    __code_env__.__event_callback__[eventType] = __code_env__.__event_callback__[eventType] or {};
    __code_env__.__event_callback__[eventType][tostring(callback)] = nil;
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

local function TriggerEventCallBack(eventType, ...)
    local Independent = __code_env__.Independent;
    local callbackMap = __code_env__.__event_callback__[eventType] or {};
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

local function DefaultKeyPressCallBack(event)
    if (event:accept()) then return end 

    if (event.ctrl_pressed and event.keyname == "DIK_Q") then
        __code_env__.Independent:Stop();
    elseif (event.ctrl_pressed and event.keyname == "DIK_R") then
        __code_env__.Independent:Restart();
    end
end

local function DefaultKeyReleaseCallBack(event)
    if (event:accept()) then return end 
end

setmetatable(EventAPI, {
    __call = function(_, CodeEnv)
        __code_env__ = CodeEnv;

        CodeEnv.EventType = EventType;
        CodeEnv.RegisterTimerCallBack = function(callback) RegisterEventCallBack(EventType.LOOP, callback) end
        CodeEnv.RemoveTimerCallBack = function(callback) RemoveEventCallBack(EventType.LOOP, callback) end 
        CodeEnv.RegisterEventCallBack = RegisterEventCallBack;
        CodeEnv.RemoveEventCallBack = RemoveEventCallBack;
        CodeEnv.TriggerEventCallBack = TriggerEventCallBack;
        
        -- 用户事件机制
        CodeEnv.On = On;
        CodeEnv.Off = Off;
        CodeEnv.Emit = Emit;

        CodeEnv.IsKeyDown = IsKeyDown;

        -- 事件注册快捷方式
        CodeEnv.OnMouseKey = function(callback) RegisterEventCallBack(EventType.MOUSE_KEY, callback) end
        CodeEnv.OnMouse = function(callback) RegisterEventCallBack(EventType.MOUSE, callback) end
        CodeEnv.OnKey = function(callback) RegisterEventCallBack(EventType.KEY, callback) end

        local SceneContext = CodeEnv.SceneContext;
        -- SceneContext:SetMouseEventCallBack(function(...) 
        --     TriggerEventCallBack(EventType.MOUSE, ...) 
        --     TriggerEventCallBack(EventType.MOUSE_KEY, ...) 
        -- end);
        SceneContext:SetMousePressEventCallBack(function(...) 
            TriggerEventCallBack(EventType.MOUSE_DOWN, ...) 
            TriggerEventCallBack(EventType.MOUSE, ...) 
            TriggerEventCallBack(EventType.MOUSE_KEY, ...) 
        end);
        SceneContext:SetMouseMoveEventCallBack(function(...) 
            TriggerEventCallBack(EventType.MOUSE_MOVE, ...) 
            TriggerEventCallBack(EventType.MOUSE, ...) 
            TriggerEventCallBack(EventType.MOUSE_KEY, ...) 
        end);
        SceneContext:SetMouseReleaseEventCallBack(function(...) 
            TriggerEventCallBack(EventType.MOUSE_UP, ...) 
            TriggerEventCallBack(EventType.MOUSE, ...) 
            TriggerEventCallBack(EventType.MOUSE_KEY, ...) 
        end);
        SceneContext:SetMouseWheelEventCallBack(function(...) 
            TriggerEventCallBack(EventType.MOUSE_WHEEL, ...) 
            TriggerEventCallBack(EventType.MOUSE, ...) 
            TriggerEventCallBack(EventType.MOUSE_KEY, ...) 
        end);
        -- SceneContext:SetKeyEventCallBack(function(...) 
        --     TriggerEventCallBack(EventType.KEY, ...) 
        --     TriggerEventCallBack(EventType.MOUSE_KEY, ...) 
        -- end);
        SceneContext:SetKeyPressEventCallBack(function(...) 
            TriggerEventCallBack(EventType.KEY_DOWN, ...) 
            TriggerEventCallBack(EventType.KEY, ...) 
            TriggerEventCallBack(EventType.MOUSE_KEY, ...) 
            DefaultKeyPressCallBack(...);
        end);
        SceneContext:SetKeyReleaseEventCallBack(function(...) 
            TriggerEventCallBack(EventType.KEY_UP, ...) 
            TriggerEventCallBack(EventType.KEY, ...) 
            TriggerEventCallBack(EventType.MOUSE_KEY, ...) 
            DefaultKeyReleaseCallBack(...);
        end);
    end
});
