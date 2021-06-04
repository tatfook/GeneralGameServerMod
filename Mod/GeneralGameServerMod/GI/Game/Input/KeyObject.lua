--[[
    NPL.load("(gl)script/Truck/Game/Input/KeyObject.lua");
    local KeyObject = commonlib.gettable("Mod.Truck.Game.Input.KeyObject");
]]
NPL.load("(gl)script/Truck/Game/Input/InputObject.lua");

local KeyObject = commonlib.inherit(commonlib.gettable("Mod.Truck.Game.Input.InputObject"),commonlib.gettable("Mod.Truck.Game.Input.KeyObject"));

KeyObject.KeyUp = 1;
KeyObject.KeyDown = 2;

function KeyObject.create(key,flag, ctrl, shift, alt)
	return KeyObject:new({key = key, flag = flag, ctrl = ctrl or false, shift = shift or false , alt = alt or false})
end

function KeyObject:getType()
	return "key session";
end

function KeyObject:handleEvent(event)
	local key = event.keyname;
	local type = event.event_type;
	local ctrl = event.ctrl_pressed;
	local shift = event.shift_pressed;
	local alt = event.alt_pressed;
	if (type == "keyPressEvent" and key == self.key and ctrl == self.ctrl and shift == self.shift and alt == self.alt) then
		self:notify(KeyObject.KeyDown, key);
		return true;
	end
end
