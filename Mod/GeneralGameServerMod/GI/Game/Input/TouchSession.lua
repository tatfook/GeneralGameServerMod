--[[
    NPL.load("(gl)script/Truck/Game/Input/TouchSession.lua");
    local TouchSession = commonlib.gettable("Mod.Truck.Game.Input.TouchSession");
]]
local TouchSession = commonlib.gettable("Mod.Truck.Game.Input.TouchSession");

local touches = {};
local size = 0;


function TouchSession.getInRow()
    local i = nil;
    function getNext()
        local key = next(touches, i);
        if (not key) then
            return
        end
        i = key;
        if (touches[key].discard) then
            return getNext();
        else
            return touches[key], getNext();
        end
    end
    return getNext();
end

function TouchSession.getAll()
    return touches;
end

function TouchSession.get(id)
    return touches[id]
end

function TouchSession.size()
    return size;
end

function TouchSession.handle(event)
	local type = event.type;
	if type == "WM_POINTERDOWN" then
		local touch = 
        {
            bx = event.x,
            by = event.y, 
            id = event.id, 
            btime = event.time, 
            time = event.time,
            x = event.x, 
            y = event.y, 
            isMoving=false,
            discard = false,
            -- offset from last pos
            dx = 0, 
            dy = 0,
            -- offset from start pos 
            ox = 0, 
            oy = 0,
        };
		touches[event.id] = touch
        size = size + 1;
	elseif type == "WM_POINTERUP" then
		local touch = touches[event.id];
		if not touch then
			return 
		end

		touch.x = event.x;
		touch.y = event.y;
		touch.time = event.time;
		local ret = false;

        --using for other logic;
		--touches[event.id] = nil;
        touch.discard = true;
        size = size - 1;
	elseif type == "WM_POINTERUPDATE" then
		local touch = touches[event.id];
		if not touch then
			return 
		end

        if (touch.x ~= event.x or touch.y ~= event.y) then
            touch.ox = event.x - touch.bx;
            touch.oy = event.y - touch.by;
            touch.dx = event.x - touch.x;
            touch.dy = event.y - touch.y;
            touch.x = event.x;
            touch.y = event.y;
            touch.isMoving = true;
        else
            touch.dx = 0;
            touch.dy = 0;
            touch.isMoving = false;
        end
        touch.time = event.time;
        
	end
    return touches[event.id];
end

local timer = commonlib.Timer:new({callbackFunc = 
function ()
    for k,t in pairs(touches) do
        if (t.discard) then
            touches[k] = nil;
        elseif (ParaGlobal.timeGetTime() - t.time) > 10000 then
            size = size - 1;
            touches[k] = nil;
        end
    end
end})

timer:Change(1000,1000);
