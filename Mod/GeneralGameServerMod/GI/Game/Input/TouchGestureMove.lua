--[[
    NPL.load("(gl)script/Truck/Game/Input/TouchGestureMove.lua");
    local TouchGestureMove = commonlib.gettable("Mod.Truck.Game.Input.TouchGestureMove");
]]

NPL.load("(gl)script/Truck/Game/Input/InputObject.lua");
NPL.load("(gl)script/Truck/Game/Input/TouchSession.lua");
local TouchSession = commonlib.gettable("Mod.Truck.Game.Input.TouchSession");
NPL.load("(gl)script/Truck/Game/Input/GestureHelper.lua");
local GestureHelper = commonlib.gettable("Mod.Truck.Game.Input.GestureHelper");


local TouchGestureMove = commonlib.inherit(commonlib.gettable("Mod.Truck.Game.Input.InputObject"),commonlib.gettable("Mod.Truck.Game.Input.TouchGestureMove"));

TouchGestureMove.MoveLeft = 1
TouchGestureMove.MoveRight = 2
TouchGestureMove.MoveUp = 4
TouchGestureMove.MoveDown = 8
TouchGestureMove.Move = TouchGestureMove.MoveLeft + TouchGestureMove.MoveRight + TouchGestureMove.MoveUp + TouchGestureMove.MoveDown;

function TouchGestureMove.create(flag, step, count)
    return TouchGestureMove:new({flag = flag, step = step or 20})
end

function TouchGestureMove:getType()
	return "touch gesture move";
end


local len = GestureHelper.length;
local gdir = GestureHelper.direction;
local getdist = GestureHelper.distance;
local abs = math.abs;
function TouchGestureMove:handleEvent(event)
    local type = event.type;
    if TouchSession.size() ~= 2 then
        return
    end

    local t1, t2 = TouchSession.getInRow();


    if type == "WM_POINTERDOWN" then
        self.lastpos = {t1.x, t1.y,t2.x, t2.y};
        self.lastdist = getdist(t1.x, t1.y, t2.x, t2.y);
	elseif type == "WM_POINTERUP" then
	elseif type == "WM_POINTERUPDATE" then
        if not t1.isMoving and not t2.isMoving then
            return false;
        end 
        
        local lx1, ly1, lx2, ly2 = self.lastpos[1], self.lastpos[2], self.lastpos[3], self.lastpos[4];
        local ldx, ldy = gdir(lx1, ly1, lx2, ly2);
        local dx, dy = gdir(t1.x, t1.y, t2.x, t2.y);
        local cos = (ldx * dx + ldy * dy) / (len(ldx, ldy) * len(dx, dy));
        if (cos < 0.999) then 
            return false;
        end

        local mx, my = t1.x - lx1, t1.y - ly1;
        if ( math.max(abs(mx), abs(my)) < self.step) then
            return false
        end


        local dist = getdist(t1.x, t1.y, t2.x, t2.y)
        if abs(dist - self.lastdist) > 5 then
            self.lastdist = dist;
            self.lastpos = {t1.x, t1.y, t2.x, t2.y};
            return false
        end


        self.lastpos = {t1.x, t1.y, t2.x, t2.y};

        if (abs(mx) >= abs(my)) then
            if mx >= 0 then
                return self:notify(TouchGestureMove.MoveRight, mx, event);
            else
                return self:notify(TouchGestureMove.MoveLeft, mx, event);
            end
        else
            if my <= 0 then
                return self:notify(TouchGestureMove.MoveUp, my, event);
            else
                return self:notify(TouchGestureMove.MoveDown, my, event);
            end
        end

    end
end
