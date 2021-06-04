--[[
    NPL.load("(gl)script/Truck/Game/Input/GestureHelper.lua");
    local GestureHelper = commonlib.gettable("Mod.Truck.Game.Input.GestureHelper");
]]

local GestureHelper = commonlib.gettable("Mod.Truck.Game.Input.GestureHelper");

local max = math.max;
local abs = math.abs;
function GestureHelper.distance(x1, y1, x2, y2)
    return GestureHelper.length(x1 - x2, y1 - y2);
end

function GestureHelper.direction(x1, y1, x2, y2)
    return x2 - x1, y2 - y1;
end

function GestureHelper.length(x,y)
    local distsq = (x^2 + y^2);
    local dist = 0;
    if distsq > 0.001 then
        dist = math.sqrt(distsq);
    end;
    return dist;
end

function GestureHelper.isMoving(dx,dy)
    return max(abs(dx), abs(dy)) >= 1;
end
