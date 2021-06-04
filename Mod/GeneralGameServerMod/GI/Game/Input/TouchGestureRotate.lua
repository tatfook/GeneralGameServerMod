--[[
    NPL.load("(gl)script/Truck/Game/Input/TouchGestureRotate.lua");
    local TouchGestureRotate = commonlib.gettable("Mod.Truck.Game.Input.TouchGestureRotate");
]]
NPL.load("(gl)script/Truck/Game/Input/InputObject.lua");
NPL.load("(gl)script/Truck/Game/Input/TouchSession.lua");
local TouchSession = commonlib.gettable("Mod.Truck.Game.Input.TouchSession");
NPL.load("(gl)script/Truck/Game/Input/GestureHelper.lua");
local GestureHelper = commonlib.gettable("Mod.Truck.Game.Input.GestureHelper");
NPL.load("(gl)script/ide/math/vector.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");


local TouchGestureRotate = commonlib.inherit(commonlib.gettable("Mod.Truck.Game.Input.InputObject"),commonlib.gettable("Mod.Truck.Game.Input.TouchGestureRotate"));

TouchGestureRotate.Left = 1;
TouchGestureRotate.Right = 2;

function TouchGestureRotate.create(flag, step)
	return TouchGestureRotate:new({flag = flag, step = step or 0.3, curstep = 0,lastdist = 0})
end

function TouchGestureRotate:getType()
	return "touch gesture pinch";
end


local getdist = GestureHelper.distance;
local getdir = GestureHelper.direction;
local getlen = GestureHelper.length;
local abs = math.abs;
local max = math.max;
function TouchGestureRotate:handleEvent(event)
	local type = event.type;
    local t1, t2 = TouchSession.getInRow();
	if type == "WM_POINTERDOWN" then
        if TouchSession.size() == 2 then    
            local x,y = getdir(t1.x, t1.y, t2.x, t2.y)
            self.lastdir = vector3d:new(x,y,0);
            self.lastdist = getdist(t1.x, t1.y, t2.x, t2.y)
        end
	elseif type == "WM_POINTERUP" then
        if TouchSession.size() == 2 then    
            local x,y = getdir(t1.x, t1.y, t2.x, t2.y)
            self.lastdir = vector3d:new(x,y,0);
        end
	elseif type == "WM_POINTERUPDATE" then
        if TouchSession.size() ~= 2 then    
            return false;
        end

        local x,y = getdir(t1.x, t1.y, t2.x, t2.y)
        local dir = vector3d:new(x,y,0);
        local dist = getdist(t1.x, t1.y, t2.x, t2.y)
        local lastdir = self.lastdir;
        local lastdist = self.lastdist;
        self.lastdir = dir;
        self.lastdist = dist;     

        if event.accepted or (not t1.isMoving and not t2.isMoving)   then
			return false;
		end
        
        if dir[1] == lastdir[1] and dir[2] == lastdir[2] then
            return false;
        end
        if abs(dist - lastdist) > 5 then
            return false
        end

        local cos = dir:dot(lastdir[1], lastdir[2], 0) / (dir:length() * lastdir:length());
        local theta = math.acos(cos);

        local left = vector3d.__mul(lastdir, dir)[3] > 0; 
        if left then
            self.curstep = self.curstep - theta;
        else
            self.curstep = self.curstep + theta;
        end
        if abs(self.curstep) < self.step then
            return false;
        end

        self.curstep = 0


		if(left) then
            return self:notify(TouchGestureRotate.Left, theta, event);
		else
            return self:notify(TouchGestureRotate.Right, theta, event);
		end
	end
end
