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

NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/SelectionManager.lua");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController");

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
local function MousePick()
    local result = SelectionManager:MousePickBlock();
	CameraController.OnMousePick(result, SelectionManager:GetPickingDist());

    if(result.length and result.length<SelectionManager:GetPickingDist()) then
        -- self:HighlightPickBlock(result);
		-- self:HighlightPickEntity(result);
		return result;
	else
        return nil;
	end
end

local EventType = {
    MAIN = "main",
    LOOP = "loop",
    CLEAR = "clear",

    -- TIMER = "timer",

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
        CodeEnv.RegisterTimerCallBack = function(...) return RegisterEventCallBack(CodeEnv, EventType.LOOP, ...) end
        CodeEnv.RemoveTimerCallBack = function(...) return RemoveEventCallBack(CodeEnv, EventType.LOOP, ...) end
        CodeEnv.RegisterEventCallBack = function(...) return RegisterEventCallBack(CodeEnv, ...) end
        CodeEnv.RemoveEventCallBack = function(...) return RemoveEventCallBack(CodeEnv, ...) end

        CodeEnv.MousePick = MousePick;
        CodeEnv.GetPickingDist = function() return SelectionManager:GetPickingDist() end

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
