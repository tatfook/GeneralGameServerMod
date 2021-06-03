local Melee = module("Melee")
local Weapon = require("Weapon");
setmetatable(Melee, {__index = Weapon})


function Melee:new(id, config)
    local o = Weapon:new(id, config);
    o.cd = 0;
    setmetatable(o, {__index = Melee});
    return o
end

function Melee:input(e, callback)
    local key = e.keyname;
    local type = e.event_type;
    local button = e.mouse_button;

    if type == "mousePressEvent" and button == "left" then 
        if self.timer then 
            self.timer:stop();
        else
            self:trigger(callback);
        end

        self.timer = Timer(10, function ()
            self:trigger(callback);
        end)
        return true;
    elseif type == "mouseReleaseEvent" and button == "left" then 
        self:stop()
        if self.timer then 
            self.timer:stop();
            self.timer = nil;
        end
        return true;
    end
end

function Melee:trigger(callback)
    if self.isTriggered then return end;
    self.isTriggered =  true;

    Animate("attack");
    Delay(tonumber(self:getProperty("attack_speed")), function ()
        self.isTriggered = false;
    end)

    Delay(tonumber(self:getProperty("attack_time")), function ()
        local player = GetPlayer();
        local bx, by, bz = player:GetBlockPos()
        local facing = player:GetFacing();
    
        facing = math.floor(4 / math.pi  * facing + 0.5) ; 
        facing = facing + 4;
        local dirs = {
            {-1,0,0},
            {-1,0,1},
            {0,0,1},
            {1,0,1},
            {1,0,0},
            {1,0, -1},
            {0,0,-1},
            {-1,0,-1},
        }  
        local range = self:getProperty("range") or 1;
        local min = facing - 1;
        local max = facing + 1;
        for i = min, max do 
    
            local dir = dirs[(i % 8) + 1];
            for j = 1, range do 
                local x, y, z = bx + dir[1] * j, by + dir[2] * j, bz + dir[3] * j
                local list = GetEntitiesInBlock(x,y,z);
                local blockid = GetBlockId(x,y,z)
                if not list  then 
                    callback(self, { blockX = x, blockY = y, blockZ = z, block_id = blockid})
                else
                for k,v in pairs(list or {}) do 
                        callback(self, {entity = k, blockX = x, blockY = y, blockZ = z}); 
                    end
                end
            end
        end
    
    
    end)


    
    
end


function Melee:stop()
    -- self.isTriggered = false;
    Idle()

end