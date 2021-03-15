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

function MouseEvent:init(event_type, window, params)
    MouseEvent._super.init(self, event_type);
    self:SetWindow(window);

    self.shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
	self.ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
	self.alt_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LMENU) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RMENU);

	self.buttons_state = 0;
	if(ParaUI.IsMousePressed(0)) then self.buttons_state = self.buttons_state + 1 end
	if(ParaUI.IsMousePressed(1)) then self.buttons_state = self.buttons_state + 2 end
    
    if (type(params) == "table") then
        self.x, self.y, self.mouse_button, self.buttons_state = params.mouse_x or self.x, params.mouse_y or self.mouse_y, params.mouse_button or self.mouse_button, params.buttons_state or self.buttons_state;
        self.shift_pressed, self.ctrl_pressed, self.alt_pressed = params.shift_pressed or self.shift_pressed, params.ctrl_pressed or self.ctrl_pressed, params.alt_pressed or self.alt_pressed;
    end

    if (event_type == "mousePressEvent") then self.mouse_down_x, self.mouse_down_y = self.x, self.y end
    if (event_type == "mouseReleaseEvent") then self.mouse_up_x, self.mouse_up_y = self.x, self.y end
    
    self.isMouseEvent = true;
    self.accepted = false;
	return self;
end

function MouseEvent:GetScreenXY()
    return self.x, self.y;
end

function MouseEvent:GetWindowXY()
    return self:GetWindow():ScreenPointToWindowPoint(self.x, self.y);
end

function MouseEvent:IsMove()
    return math.abs(self.x - self.mouse_down_x) >= 4 or math.abs(self.y - self.mouse_down_y) >= 4;
end

function MouseEvent:SetWindow(window)
    self.window = window;
end

function MouseEvent:GetWindow()
    return self.window;
end

function MouseEvent:SetElement(element)
    self.element = element;
    if (not element) then return end
end

function MouseEvent:GetElement()
    return self.element;
end

-- 此函数冬令营再用, 后续废弃, 勿用
function MouseEvent:GetWindowPos()
    return self:GetWindowXY();
end

Event.MouseEvent = MouseEvent;