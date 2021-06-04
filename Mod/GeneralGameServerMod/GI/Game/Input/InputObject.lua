--[[
    NPL.load("(gl)script/Truck/Game/Input/InputObject.lua");
    local InputObject = commonlib.gettable("Mod.Truck.Game.Input.InputObject");
]]

local InputObject = commonlib.inherit(nil,commonlib.gettable("Mod.Truck.Game.Input.InputObject"));

NPL.load("(gl)script/ide/math/bit.lua");
local band = mathlib.bit.band;
local bnot = mathlib.bit.bnot;
local bor = mathlib.bit.bor;

function InputObject:ctor()
	self.callbacks = {};
end

function InputObject:handleEvent(event)
	-- pure virtual
end

function InputObject:getType()
	-- pure virtual
end

function InputObject:hasFlag(flag)
	return band(flag, self.flag) ~= 0
end

function InputObject:notify(type, ...)
	if self:hasFlag(type) then
		return self.callback(type, ...)
	end
	return false;
end

function InputObject:setCallback(cb)
	self.callback = cb;
end
