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
-- local SceneContext = commonlib.inherit(commonlib.gettable("System.Core.SceneContext"), NPL.export());
local SceneContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditContext"), NPL.export());

function SceneContext:ctor()
	self:setMouseTracking(true)
	self:EnableAutoCamera(true);
end

function SceneContext:handleMouseEvent(event)
    return SceneContext._super.handleMouseEvent(self, event);
end

function SceneContext:mousePressEvent(mouse_event)
end

function SceneContext:mouseMoveEvent(mouse_event)
end

function SceneContext:mouseReleaseEvent(mouse_event)
end

function SceneContext:mouseWheelEvent(mouse_event)
end

function SceneContext:handleKeyEvent(event)
    return SceneContext._super.handleKeyEvent(self, event);
end

function SceneContext:keyPressEvent(key_event)
end

function SceneContext:keyReleaseEvent(key_event)
end

SceneContext:InitSingleton();