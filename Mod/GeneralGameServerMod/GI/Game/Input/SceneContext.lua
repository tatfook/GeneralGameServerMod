--[[
Title: SceneContext
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local SceneContext = NPL.load("Mod/GeneralGameServerMod/GI/Game/Input/SceneContext.lua");
------------------------------------------------------------
]]
local SceneContext = commonlib.inherit(commonlib.gettable("System.Core.SceneContext"), NPL.export());

SceneContext:Property("MouseEventCallBack");
SceneContext:Property("MousePressEventCallBack");
SceneContext:Property("MouseMoveEventCallBack");
SceneContext:Property("MouseReleaseEventCallBack");
SceneContext:Property("MouseWheelEventCallBack");
SceneContext:Property("KeyEventCallBack");
SceneContext:Property("KeyPressEventCallBack");
SceneContext:Property("KeyReleaseEventCallBack");

function SceneContext:ctor()
	self:setMouseTracking(true)
	self:EnableAutoCamera(true);
end

function SceneContext:handleMouseEvent(event)
    SceneContext._super.handleMouseEvent(self, event);

    local callback = self:GetMouseEventCallBack();
    if (type(callback) == "function") then callback(event) end
end

function SceneContext:mousePressEvent(event)
    SceneContext._super.mousePressEvent(self, event);

    local callback = self:GetMousePressEventCallBack();
    if (type(callback) == "function") then callback(event) end
end

function SceneContext:mouseMoveEvent(event)
    SceneContext._super.mouseMoveEvent(self, event);

    local callback = self:GetMouseMoveEventCallBack();
    if (type(callback) == "function") then callback(event) end
end

function SceneContext:mouseReleaseEvent(event)
    SceneContext._super.mouseReleaseEvent(self, event);

    local callback = self:GetMouseReleaseEventCallBack();
    if (type(callback) == "function") then callback(event) end
end

function SceneContext:mouseWheelEvent(event)
    SceneContext._super.mouseWheelEvent(self, event);

    local callback = self:GetMouseWheelEventCallBack();
    if (type(callback) == "function") then callback(event) end
end

function SceneContext:handleKeyEvent(event)
    SceneContext._super.handleKeyEvent(self, event);

    local callback = self:GetKeyEventCallBack();
    if (type(callback) == "function") then callback(event) end
end

function SceneContext:keyPressEvent(event)
    SceneContext._super.keyPressEvent(self, event);

    local callback = self:GetKeyPressEventCallBack();
    if (type(callback) == "function") then callback(event) end
end

function SceneContext:keyReleaseEvent(event)
    SceneContext._super.keyReleaseEvent(self, event);

    local callback = self:GetKeyReleaseEventCallBack();
    if (type(callback) == "function") then callback(event) end
end

SceneContext:InitSingleton();