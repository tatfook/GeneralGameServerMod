--[[
    NPL.load("(gl)script/Truck/Game/Input/ButtonObject.lua");
    local ButtonObject = commonlib.gettable("Mod.Truck.Game.Input.ButtonObject");
]]
NPL.load("(gl)script/Truck/Game/Input/InputObject.lua");

local ButtonObject = commonlib.inherit(commonlib.gettable("Mod.Truck.Game.Input.InputObject"),commonlib.gettable("Mod.Truck.Game.Input.ButtonObject"));

local shortclickLimits = 150;
local longclickLimits = 300;

ButtonObject.Click = 1;
ButtonObject.ButtonUp = 2;
ButtonObject.ButtonDown = 4;
ButtonObject.MouseMove= 8;
ButtonObject.Drop = 16;
ButtonObject.DragMove = 32;

function ButtonObject.create(button,flag,ctrl, shift, alt)
	return ButtonObject:new({button = button, flag = flag,ctrl = ctrl or false, shift = shift or false, alt = alt or false})
end

function ButtonObject:getType()
	return "button object";
end

function ButtonObject:handleEvent(event)
	local button = event.mouse_button;
	local type = event.event_type;
	local ctrl = event.ctrl_pressed;
	local shift = event.shift_pressed;
	local alt = event.alt_pressed;

	if (type == "mousePressEvent" and button == self.button and 
		ctrl == self.ctrl and shift == self.shift and alt == self.alt) then
		self.timer = ParaGlobal.timeGetTime();
		self.x = event.x;
		self.y = event.y;
		return self:notify(ButtonObject.ButtonDown,  {button=button},event);
	elseif (type == "mouseReleaseEvent" and button == self.button and self.timer and self.timer ~= 0) then
		local ret = false;
		local duration = ParaGlobal.timeGetTime() - self.timer;
		if duration < shortclickLimits then
			ret = self:notify(ButtonObject.Click, {button = button,duration = duration}, event) ;
		end

		if math.abs(self.x - event.x) > 10 or math.abs(self.y - event.y) > 10 then
			ret = self:notify(ButtonObject.Drop, {button = button, duration = duration, dx = event.x - self.x, dy = event.y - self.y}, event) or ret;
		end 

		self.timer = 0;
		return self:notify(ButtonObject.ButtonUp, button,event) or ret;
	elseif (type == "mouseMoveEvent" and self.timer and self.timer ~= 0) then
		if button == self.button then
			return self:notify(ButtonObject.DragMove, {button = button},event);
		else
			return self:notify(ButtonObject.MouseMove, {button = button},event);
		end
	end

end
