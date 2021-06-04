--[[
    NPL.load("(gl)script/Truck/Game/Input/TouchObject.lua");
    local TouchObject = commonlib.gettable("Mod.Truck.Game.Input.TouchObject");
]]
NPL.load("(gl)script/Truck/Game/Input/InputObject.lua");

local TouchObject = commonlib.inherit(commonlib.gettable("Mod.Truck.Game.Input.InputObject"),commonlib.gettable("Mod.Truck.Game.Input.TouchObject"));
NPL.load("(gl)script/Truck/Game/Input/TouchSession.lua");
local TouchSession = commonlib.gettable("Mod.Truck.Game.Input.TouchSession");

local clickLimits = 150;
local doubleclickLimits = 300;

TouchObject.TouchUp = 1;
TouchObject.TouchDown = 2;
TouchObject.Click= 4;
TouchObject.TouchMove = 8;
TouchObject.DoubleClick = 16;
TouchObject.Drag = 32;

local queue = {};
local timer ;
function notify(inst, type, touch, event, timeleft)
	if not inst:hasFlag(type) then
		return 
	end

	queue[#queue + 1] = function ()
		return inst:notify(type, touch, event);
	end;

	if (not timer and timeleft) then
		timer = commonlib.Timer:new({callbackFunc = function()
			for k,v in ipairs(queue) do
				if v() then
					break;
				end
			end
			queue = {};
			timer = nil;
		end})
		timer:Change(timeleft);
	end
end

function clear()
	queue = {};
	timer:Change();
	timer = nil;
end

function TouchObject.create(flag)
	return TouchObject:new({flag = flag, dclicktime = 0})
end

function TouchObject:getType()
	return "touch object";
end

function TouchObject:handleEvent(event)
	local type = event.type;
	local touch = TouchSession.get(event.id);
	if not touch or TouchSession.size() > 1 then
		return false;
	end
	if type == "WM_POINTERDOWN" then
		if event.time - self.dclicktime > doubleclickLimits then
			self.dclicktime = event.time;
		end
		return self:notify(TouchObject.TouchDown, touch, event);
	elseif type == "WM_POINTERUP" then
		if self:hasFlag(TouchObject.DoubleClick) and event.time - self.dclicktime < doubleclickLimits and touch.btime ~= self.dclicktime then
			local ret = self:notify(TouchObject.DoubleClick, touch,event);
			if ret then 
				clear()
			end
			return ret;
		elseif self:hasFlag(TouchObject.Click) and (event.time - touch.btime ) < clickLimits then
			notify(self,TouchObject.Click, touch,event, doubleclickLimits - (event.time - self.dclicktime)) ;
		elseif self:hasFlag(TouchObject.Drag) and touch.isMoving then
			notify(self,TouchObject.Drag, touch,event, doubleclickLimits - (event.time - self.dclicktime)) ;
		end

		notify(self, TouchObject.TouchUp, touch, event, doubleclickLimits - (event.time - self.dclicktime)) ;
		return false;
	elseif type == "WM_POINTERUPDATE" then
		if touch.isMoving then
			return self:notify(TouchObject.TouchMove, touch, event);
		end
		return false;
	end
end
