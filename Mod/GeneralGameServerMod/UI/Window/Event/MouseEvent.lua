--[[
Title: MouseEvent
Author(s): wxa
Date: 2020/6/30
Desc: Event
use the lib:
-------------------------------------------------------
local MouseEvent = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Event/MouseEvent.lua");
-------------------------------------------------------
]]

local BaseEvent = NPL.load("./BaseEvent.lua");

local MouseEvent = commonlib.inherit(BaseEvent, NPL.export());

function MouseEvent:Init(event_type, window, params)
    MouseEvent._super.Init(self, event_type, window);


    self.x, self.y = ParaUI.GetMousePosition();
    self.shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
	self.ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
	self.alt_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LMENU) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RMENU);
    self.mouse_button = mouse_button;
	self.mouse_wheel = mouse_wheel;

	self.buttons_state = 0;
	if(ParaUI.IsMousePressed(0)) then self.buttons_state = self.buttons_state + 1 end
	if(ParaUI.IsMousePressed(1)) then self.buttons_state = self.buttons_state + 2 end
    
    if (type(params) == "table") then
        self.x, self.y, self.mouse_button, self.buttons_state, self.mouse_wheel = params.mouse_x or self.x, params.mouse_y or self.mouse_y, params.mouse_button or self.mouse_button, params.buttons_state or self.buttons_state, params.mouse_wheel or self.mouse_wheel;
        self.shift_pressed, self.ctrl_pressed, self.alt_pressed = params.shift_pressed or self.shift_pressed, params.ctrl_pressed or self.ctrl_pressed, params.alt_pressed or self.alt_pressed;
    end

    if (event_type == "onmousedown") then self.down_mouse_screen_x, self.down_mouse_screen_y = self.x, self.y end
    if (event_type == "onmouseup") then self.up_mouse_screen_x, self.up_mouse_screen_y = self.x, self.y end
    
	return self;
end

function MouseEvent:GetScreenXY()
    return self.x, self.y;
end

function MouseEvent:GetWindowXY()
    return self:GetWindow():ScreenPointToWindowPoint(self.x, self.y);
end

function MouseEvent:IsMove()
    return math.abs(self.x - (self.down_mouse_screen_x or 0)) >= 4 or math.abs(self.y - (self.down_mouse_screen_y or 0)) >= 4;
end

-- 鼠标滚动距离
function MouseEvent:GetDelta()
	return self.mouse_wheel or 0;
end

-- 是否鼠标左键按下
function MouseEvent:IsLeftButton()
	return self.buttons_state == 1;
end

-- 是否鼠标右键按下
function MouseEvent:IsRightButton()
	return self.buttons_state == 2;
end

-- 是否是鼠标中键按下 
function MouseEvent:IsMiddleButton()
    return self.mouse_button == "middle";
end

function MouseEvent:IsMouseEvent()
    return true;
end


---------------------------------------------以下代码均为兼容代码, 后续废弃-------------------------------------------------

-- 此函数冬令营再用, 后续废弃, 勿用
function MouseEvent:GetWindowPos()
    return self:GetWindowXY();
end
