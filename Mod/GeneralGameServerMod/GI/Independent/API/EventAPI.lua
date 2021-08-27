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

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController");

local EventAPI = NPL.export();

local EventType = {
    MAIN = "main",
    TICK = "tick",
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

    MOUSE_KEY = "mouse_key",    -- 鼠标和按键

    -- -- 资源创建事件
    RESOURCE_WINDOW = "resource_window", 
    RESOURCE_ENTITY = "resource_entity",

    -- CODE_BLOCK_STOP = "code_block_stop", -- 代码方块停止事件
}

local function RegisterEventCallBack(__code_env__, eventType, callback)
    if (type(callback) ~= "function" or type(eventType) ~= "string") then return end 
    __code_env__.__event_callback__[eventType] = __code_env__.__event_callback__[eventType] or {};
    __code_env__.__event_callback__[eventType][tostring(callback)] = callback;
    
    local __data__ = __code_env__.__get_coroutine_data__();
    __data__.__event_callback__[eventType] = __code_env__.__event_callback__[eventType] or {};
    __data__.__event_callback__[eventType][tostring(callback)] = callback;
end

local function RemoveEventCallBack(__code_env__, eventType, callback)
    if (type(callback) ~= "function" or type(eventType) ~= "string") then return end 
    __code_env__.__event_callback__[eventType] = __code_env__.__event_callback__[eventType] or {};
    __code_env__.__event_callback__[eventType][tostring(callback)] = nil;

    local __data__ = __code_env__.__get_coroutine_data__();
    __code_env__.__event_callback__[eventType] = __code_env__.__event_callback__[eventType] or {};
    __code_env__.__event_callback__[eventType][tostring(callback)] = nil;
end

local function TriggerEventCallBack(__code_env__, eventType, ...)
    local callbackMap = __code_env__.__event_callback__[eventType] or {};
    for _, callback in pairs(callbackMap) do 
        __code_env__.__call__(callback, ...);
    end
end

local function IsKeyPressed(...)
    return ParaUI.IsKeyPressed(...)
end 

local function GetUserEventName(eventName)
    return string.format("USER_EVENT_%s", eventName);
end
local function On(__code_env__, eventName, callback)
    RegisterEventCallBack(__code_env__, GetUserEventName(eventName), callback);
end

local function Off(__code_env__, eventName, callback)
    RemoveEventCallBack(__code_env__, GetUserEventName(eventName), callback);
end

local function Emit(__code_env__, eventName, ...)
    TriggerEventCallBack(__code_env__, GetUserEventName(eventName), ...);
end

local function DefaultKeyPressCallBack(__code_env__, event)
    if (IsDevEnv) then
        if (event.ctrl_pressed and event.keyname == "DIK_Q") then
            __code_env__.__stop__();
        elseif (event.ctrl_pressed and event.keyname == "DIK_R") then
            __code_env__.__restart__();
        -- elseif (event.ctrl_pressed and event.keyname == "DIK_T") then
        --     local result = __code_env__.MousePick();
        --     if (not result or not result.blockX) then return end
        --     local blockpos = string.format("%s, %s, %s", result.blockX, result.blockY, result.blockZ);
        --     ParaMisc.CopyTextToClipboard(blockpos);
        --     __code_env__.Tip(blockpos);
        end
    end
end

local function DefaultKeyReleaseCallBack(__code_env__, event)
end

local function DefaultMousePressEventCallBack(__code_env__, event)
    if (__code_env__.__is_share_mouse_keyboard_event__()) then return end 
    local result = __code_env__.MousePick();
    if (not result) then return end
    if (result.entity and result.entity.OnMouseClick) then result.entity:OnMouseClick() end
end


setmetatable(EventAPI, {
    __call = function(_, CodeEnv)
        CodeEnv.DIK_SCANCODE = DIK_SCANCODE; -- DIK_SCANCODE.DIK_W
        
        CodeEnv.EventType = EventType;
        CodeEnv.RegisterTickCallBack = function(callback) RegisterEventCallBack(CodeEnv, EventType.TICK, callback) end
        CodeEnv.RemoveTickCallBack = function(callback) RemoveEventCallBack(CodeEnv, EventType.TICK, callback) end 
        CodeEnv.TriggerTickCallBack = function(...) TriggerEventCallBack(CodeEnv, EventType.TICK, ...) end

        CodeEnv.RegisterTimerCallBack = function(callback) RegisterEventCallBack(CodeEnv, EventType.LOOP, callback) end
        CodeEnv.RemoveTimerCallBack = function(callback) RemoveEventCallBack(CodeEnv, EventType.LOOP, callback) end 
        CodeEnv.RegisterEventCallBack = function(...) RegisterEventCallBack(CodeEnv, ...) end
        CodeEnv.RemoveEventCallBack = function(...) RemoveEventCallBack(CodeEnv, ...) end
        CodeEnv.TriggerEventCallBack = function(...) TriggerEventCallBack(CodeEnv, ...) end
        
        -- 用户事件机制
        CodeEnv.On = function(...) On(CodeEnv, ...) end
        CodeEnv.Off = function(...) Off(CodeEnv, ...) end
        CodeEnv.Emit = function(...) Emit(CodeEnv, ...) end 

        CodeEnv.IsKeyPressed = IsKeyPressed;

        -- 事件注册快捷方式
        CodeEnv.OnMouseKey = function(callback) RegisterEventCallBack(CodeEnv, EventType.MOUSE_KEY, callback) end
        CodeEnv.OnMouse = function(callback) RegisterEventCallBack(CodeEnv, EventType.MOUSE, callback) end
        CodeEnv.OnKey = function(callback) RegisterEventCallBack(CodeEnv, EventType.KEY, callback) end

        local SceneContext = CodeEnv.SceneContext;
       
        local function MousePressEventCallBack(...)
            TriggerEventCallBack(CodeEnv, EventType.MOUSE_DOWN, ...) 
            TriggerEventCallBack(CodeEnv, EventType.MOUSE, ...) 
            TriggerEventCallBack(CodeEnv, EventType.MOUSE_KEY, ...) 
            DefaultMousePressEventCallBack(CodeEnv, ...);
        end

        local function MouseMoveEventCallBack(...)
            TriggerEventCallBack(CodeEnv, EventType.MOUSE_MOVE, ...) 
            TriggerEventCallBack(CodeEnv, EventType.MOUSE, ...) 
            TriggerEventCallBack(CodeEnv, EventType.MOUSE_KEY, ...) 
        end
      
        local function MouseReleaseEventCallBack(...)
            TriggerEventCallBack(CodeEnv, EventType.MOUSE_UP, ...) 
            TriggerEventCallBack(CodeEnv, EventType.MOUSE, ...) 
            TriggerEventCallBack(CodeEnv, EventType.MOUSE_KEY, ...) 
        end

        local function MouseWheelEventCallBack(...)
            TriggerEventCallBack(CodeEnv, EventType.MOUSE_WHEEL, ...) 
            TriggerEventCallBack(CodeEnv, EventType.MOUSE, ...) 
            TriggerEventCallBack(CodeEnv, EventType.MOUSE_KEY, ...) 
        end

        local function KeyPressEventCallBack(...)
            TriggerEventCallBack(CodeEnv, EventType.KEY_DOWN, ...) 
            TriggerEventCallBack(CodeEnv, EventType.KEY, ...) 
            TriggerEventCallBack(CodeEnv, EventType.MOUSE_KEY, ...) 
            DefaultKeyPressCallBack(CodeEnv, ...)
        end

        local function KeyReleaseEventCallBack(...)
            TriggerEventCallBack(CodeEnv, EventType.KEY_UP, ...) 
            TriggerEventCallBack(CodeEnv, EventType.KEY, ...) 
            TriggerEventCallBack(CodeEnv, EventType.MOUSE_KEY, ...) 
            DefaultKeyReleaseCallBack(CodeEnv, ...);
        end
        
        -- 世界加载
        local function OnWorldLoaded() 
        end

        -- 世界卸载 默认停止
        local function OnWorldUnloaded()
            CodeEnv.__stop__();
        end

        -- 主动触发事件
        CodeEnv.TriggerMousePressEvent = MousePressEventCallBack;
        CodeEnv.TriggerMouseMoveEvent = MouseMoveEventCallBack;
        CodeEnv.TriggerMouseReleaseEvent = MouseReleaseEventCallBack;
        CodeEnv.TriggerMouseWheelEvent = MouseWheelEventCallBack;
        CodeEnv.TriggerKeyPressEvent = KeyPressEventCallBack;
        CodeEnv.TriggerKeyReleaseEvent = KeyReleaseEventCallBack;


        -- 注册上下回调
        SceneContext:RegisterEventCallBack(SceneContext.EventType.MOUSE_PRESS_EVENT, MousePressEventCallBack, CodeEnv);
        SceneContext:RegisterEventCallBack(SceneContext.EventType.MOUSE_MOVE_EVENT, MouseMoveEventCallBack, CodeEnv);
        SceneContext:RegisterEventCallBack(SceneContext.EventType.MOUSE_RELEASE_EVENT, MouseReleaseEventCallBack, CodeEnv);
        SceneContext:RegisterEventCallBack(SceneContext.EventType.MOUSE_WHEEL_EVENT, MouseWheelEventCallBack, CodeEnv);
        SceneContext:RegisterEventCallBack(SceneContext.EventType.KEY_PRESS_EVENT, KeyPressEventCallBack, CodeEnv);
        SceneContext:RegisterEventCallBack(SceneContext.EventType.KEY_RELEASE_EVENT, KeyReleaseEventCallBack, CodeEnv);

        SceneContext:RegisterEventCallBack(SceneContext.EventType.WORLD_LOADED, OnWorldLoaded, CodeEnv);
        SceneContext:RegisterEventCallBack(SceneContext.EventType.WORLD_UNLOADED, OnWorldUnloaded, CodeEnv);

        CodeEnv.RegisterEventCallBack(CodeEnv.EventType.CLEAR, function()
            SceneContext:RemoveEventCallBack(SceneContext.EventType.MOUSE_PRESS_EVENT, MousePressEventCallBack, CodeEnv);
            SceneContext:RemoveEventCallBack(SceneContext.EventType.MOUSE_MOVE_EVENT, MouseMoveEventCallBack, CodeEnv);
            SceneContext:RemoveEventCallBack(SceneContext.EventType.MOUSE_RELEASE_EVENT, MouseReleaseEventCallBack, CodeEnv);
            SceneContext:RemoveEventCallBack(SceneContext.EventType.MOUSE_WHEEL_EVENT, MouseWheelEventCallBack, CodeEnv);
            SceneContext:RemoveEventCallBack(SceneContext.EventType.KEY_PRESS_EVENT, KeyPressEventCallBack, CodeEnv);
            SceneContext:RemoveEventCallBack(SceneContext.EventType.KEY_RELEASE_EVENT, KeyReleaseEventCallBack, CodeEnv);

            SceneContext:RemoveEventCallBack(SceneContext.EventType.WORLD_LOADED, OnWorldLoaded, CodeEnv);
            SceneContext:RemoveEventCallBack(SceneContext.EventType.WORLD_UNLOADED, OnWorldUnloaded, CodeEnv);
        end);
    end
});
