--[[
Title: SceneContext
Author(s):  wxa
Date: 2021-06-01
Desc: 鼠标键盘输入事件
use the lib:
------------------------------------------------------------
local SceneContext = NPL.load("Mod/GeneralGameServerMod/GI/Game/Input/SceneContext.lua");
------------------------------------------------------------
]]
local SceneContext = commonlib.inherit(commonlib.gettable("System.Core.SceneContext"), NPL.export());

local EventEmitter = NPL.load("./EventEmitter.lua");

SceneContext:Property("Activate", false, "IsActivate");

local EventType = {
    MOUSE_PRESS_EVENT = "MOUSE_PRESS_EVENT",
    MOUSE_MOVE_EVENT = "MOUSE_MOVE_EVENT",
    MOUSE_RELEASE_EVENT = "MOUSE_RELEASE_EVENT",
    MOUSE_WHEEL_EVENT = "MOUSE_WHEEL_EVENT",
    KEY_PRESS_EVENT = "KEY_PRESS_EVENT",
    KEY_RELEASE_EVENT = "KEY_RELEASE_EVENT",
}

SceneContext.EventType = EventType;


function SceneContext:ctor()
	self:setMouseTracking(true)
	self:EnableAutoCamera(true);

    self.__event_emitter__ = EventEmitter:new();
end

function SceneContext:RegisterEventCallBack(...)
    self.__event_emitter__:RegisterEventCallBack(...);
end

function SceneContext:RemoveEventCallBack(...)
    self.__event_emitter__:RemoveEventCallBack(...)
end

function SceneContext:TriggerEventCallBack(...)
    self.__event_emitter__:TriggerEventCallBack(...);
end

function SceneContext:Activate()
    self:activate();
    self:SetActivate(true);
end

function SceneContext:Inactivate()
    if (not self:IsActivate()) then return end 
    self:SetActivate(false);
    GameLogic.ActivateDefaultContext();
end

-- function SceneContext:handleMouseEvent(event)
--     SceneContext._super.handleMouseEvent(self, event);
--     local callback = self:GetMouseEventCallBack();
--     if (type(callback) == "function") then callback(event) end
-- end

function SceneContext:mousePressEvent(event)
    SceneContext._super.mousePressEvent(self, event);

    self:TriggerEventCallBack(EventType.MOUSE_PRESS_EVENT, event);

    -- 通知代码方块
    GameLogic.GetCodeGlobal():BroadcastKeyPressedEvent("mouse_buttons", event);
end

function SceneContext:mouseMoveEvent(event)
    SceneContext._super.mouseMoveEvent(self, event);

    self:TriggerEventCallBack(EventType.MOUSE_MOVE_EVENT, event);
end

function SceneContext:mouseReleaseEvent(event)
    SceneContext._super.mouseReleaseEvent(self, event);

    self:TriggerEventCallBack(EventType.MOUSE_RELEASE_EVENT, event);

    -- 通知代码方块
    if (event:button() == "left" and event:GetDragDist() < 10) then
        GameLogic.GetCodeGlobal():BroadcastBlockClickEvent("BroadcastBlockClickEvent", event);
    end
end

function SceneContext:mouseWheelEvent(event)
    SceneContext._super.mouseWheelEvent(self, event);

    self:TriggerEventCallBack(EventType.MOUSE_WHEEL_EVENT, event);

    -- 通知代码方块
    GameLogic.GetCodeGlobal():BroadcastKeyPressedEvent("mouse_wheel", mouse_wheel);
end

-- function SceneContext:handleKeyEvent(event)
--     SceneContext._super.handleKeyEvent(self, event);
--     -- local callback = self:GetKeyEventCallBack();
--     -- if (type(callback) == "function") then callback(event) end
-- end

function SceneContext:keyPressEvent(event)
    SceneContext._super.keyPressEvent(self, event);

    self:TriggerEventCallBack(EventType.KEY_PRESS_EVENT, event);

    -- 通知代码方块
    GameLogic.GetCodeGlobal():BroadcastKeyPressedEvent(event.keyname);
end

function SceneContext:keyReleaseEvent(event)
    SceneContext._super.keyReleaseEvent(self, event);

    self:TriggerEventCallBack(EventType.KEY_RELEASE_EVENT, event);
end

SceneContext:InitSingleton();