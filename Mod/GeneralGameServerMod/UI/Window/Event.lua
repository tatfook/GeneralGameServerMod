--[[
Title: Event
Author(s): wxa
Date: 2020/6/30
Desc: Event
use the lib:
-------------------------------------------------------
local Event = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Event.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/MouseEvent.lua");
local Event = NPL.export();

local MouseDownElement = nil;
local MouseEvent = commonlib.inherit(commonlib.gettable("System.Windows.MouseEvent"), {});

function MouseEvent:init(event_type, window)
	MouseEvent._super.init(self, event_type);

    local screenX, screenY = window:GetScreenPosition();

    self.global_pos:set(self.x, self.y);
    self.local_pos:set(self.x - screenX, self.y - screenY);
    self.windowX, self.windowY = self.x - screenX, self.y - screenY;
    self.screenX, self.screenY = self.x, self.y;
    self.accepted = false;
    
    if (event_type == "mousePressEvent") then self.mouse_down_x, self.mouse_down_y = self.x, self.y end
    if (event_type == "mouseReleaseEvent") then self.mouse_up_x, self.mouse_up_y = self.x, self.y end
	return self;
end

function MouseEvent:IsMove()
    return not (math.abs(self.x - self.mouse_down_x) < 4 and math.abs(self.y - self.mouse_down_y) < 4);
end

function MouseEvent:SetElement(element)
    self.element = element;
    if (not element) then return end
end

function MouseEvent:GetWindowPos()
    return self.windowX, self.windowY;
end

function MouseEvent:GetElement()
    return self.element;
end

Event.MouseEvent = MouseEvent;