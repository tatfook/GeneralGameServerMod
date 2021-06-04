--[[
    NPL.load("(gl)script/Truck/Game/Input/TouchGesturePinch.lua");
    local TouchGesturePinch = commonlib.gettable("Mod.Truck.Game.Input.TouchGesturePinch");
]]
NPL.load("(gl)script/Truck/Game/Input/InputObject.lua");
NPL.load("(gl)script/Truck/Game/Input/TouchSession.lua");
local TouchSession = commonlib.gettable("Mod.Truck.Game.Input.TouchSession");
NPL.load("(gl)script/Truck/Game/Input/GestureHelper.lua");
local GestureHelper = commonlib.gettable("Mod.Truck.Game.Input.GestureHelper");

local TouchGesturePinch = commonlib.inherit(commonlib.gettable("Mod.Truck.Game.Input.InputObject"),commonlib.gettable("Mod.Truck.Game.Input.TouchGesturePinch"));

TouchGesturePinch.Open = 1;
TouchGesturePinch.Close = 2;

function TouchGesturePinch.create(flag, step)
	return TouchGesturePinch:new({flag = flag, step = step or 20,curstep = 0, lastdist = 0})
end

function TouchGesturePinch:getType()
	return "touch gesture pinch";
end


local getdist = GestureHelper.distance;
local getdir = GestureHelper.direction;
local abs = math.abs;
local max = math.max;
local isMoving = GestureHelper.isMoving
function TouchGesturePinch:handleEvent(event)
	local type = event.type;
    local t1, t2 = TouchSession.getInRow();
	if type == "WM_POINTERDOWN" then
        if TouchSession.size() == 2 then    
            self.lastdist = getdist(t1.x, t1.y, t2.x, t2.y);
            self.lastdir = {getdir(t1.x, t1.y, t2.x, t2.y)};
            self.curstep = 0;
        end
	elseif type == "WM_POINTERUP" then
        if TouchSession.size() == 2 then    
            self.lastdist = getdist(t1.x, t1.y, t2.x, t2.y);
        end
	elseif type == "WM_POINTERUPDATE" then
        if TouchSession.size() ~= 2 then    
            return false;
        end

        local dir = {getdir(t1.x, t1.y, t2.x, t2.y)}
        local dist = getdist(t1.x, t1.y, t2.x, t2.y);
        local lastdir = self.lastdir;
        local lastdist = self.lastdist;
        self.lastdir = dir;
        self.lastdist = dist;

		-- decide pinch mode
		local deltaDistance = dist - lastdist;
        self.curstep = self.curstep + deltaDistance
        if (abs(self.curstep) < self.step) then
            return false;
        end

        self.curstep = 0;

		if event.accepted or (not t1.isMoving and not t2.isMoving)  then
			return false;
		end

        local cos = (dir[1] * lastdir[1] + dir[2] * lastdir[2]) / (dist * lastdist);
        local theta = math.acos(cos);
        if theta >  0.01 then
            return false;
        end

		if(deltaDistance > 0) then
            return self:notify(TouchGesturePinch.Open, deltaDistance, event);
		else
            return self:notify(TouchGesturePinch.Close, deltaDistance, event);
		end

	end
end
