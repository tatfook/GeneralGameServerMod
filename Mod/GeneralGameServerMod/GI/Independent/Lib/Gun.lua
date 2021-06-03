local Gun = module("Gun")
local Weapon = require("Weapon");
setmetatable(Gun, {__index = Weapon})
local Repsitory = require("Repository")

local sw, sh = GetScreenSize();


function Gun:new(id, config)
    local o = Weapon:new(id, config);
    setmetatable(o, {__index = Gun});
    o:init();
    return o
end

function Gun:init()
    self.cd = 0;
    self.ammoCount = 0 --self.ammoMaxCount;
end


function Gun:input(e, callback)
    local key = e.keyname;
    local type = e.event_type;
    local button = e.mouse_button;

    if type == "mousePressEvent" and button == "left" then 
        if self.reloading == true then 
            return true;
        end

        self:trigger(callback);
        return true;
    elseif type == "mouseReleaseEvent" and button == "left" then 
        if self.isTriggered then
            self:stop()
        end
        return true;
    elseif type == "keyReleaseEvent" and key == "DIK_R" then 
        if self.ammoCount == tonumber(self:getProperty("ammo")) then 
            return true
        end
        if self.isTriggered then
            self:stop();
        end
        self:reload();
        return true;
    end
end

function Gun:trigger(callback)
    if self.ammoCount <= 0 then 
        return ;
    end
    if self.isTriggered then return end;
    self.isTriggered = true;
    
    local sight = 1 / GetFOV();
    if self:getProperty("sight") then 
        sight = 1 / (tonumber(self:getProperty("sight") ) or GetFOV());
    end
    local offset = {0.001 * tonumber(self:getProperty("offset_dy")) * sight, 0.001 * tonumber(self:getProperty("offset_dx")) * sight};
    local target = {0,0}
    local step = {offset[1] *0.05,offset[2] * 0.05};
    local function trigger()

        local curTime =  GetTime();
        local cd = self.cd;
        if cd and curTime - cd < tonumber(self:getProperty("atk_speed")) then return end;


        if not self.shock then
            local abs = math.abs
            self.shock = Timer(1, function ()
                local rot = {GetCameraRotation()};
        
                for i = 1, 2 do 
                    local t = target[i];
                    if t ~= 0 then 
                        local len = abs(target[i])
                        local sign = len / target[i];
                        local stride = math.min(step[i], len) * sign;
                        rot[i] = rot[i] - stride;
                        if target[i] ~= 0 then
                            target[i] = math.max(len - step[i], 0) * sign;
                        end
                    end
                end
                SetCameraRotation(rot[1], rot[2], nil)
            
            end)
        end

        Animate( "attack");
        -- Delay(tonumber(self:getProperty("atk_speed")), function ()
        --     if not self.isTriggered then 
        --         Idle()
        --     end
        -- end)

        if self.ammoCount > 0 then 
            self.ammoCount = self.ammoCount - 1;
        else
            self:stop();
        end
        

        
        self.cd = curTime;

        local r = (math.random(0, 1) * 2 - 1);
        target[1] = -offset[1] * 0.9;
        target[2] =   r * offset[2] * 0.9;

        local rot = {GetCameraRotation()};
        rot[1] = rot[1] - offset[1]
        rot[2] = rot[2] - r * offset[2]
        SetCameraRotation(rot[1], rot[2], nil)


        local ret = Pick();
        if not ret.x then 
            return 
        end

        if GetCameraMode() ~= 1 then
            local fp = GetPlayer():getPosition();
            local dir =  {ret.x - fp[1], ret.y - fp[2] - 1, ret.z - fp[3]};
            if ret.length < 10 then 
                local rx,ry,_ = GetCameraRotation();
                ry = - (ry );
                dir = {math.cos(ry), math.sin(-rx), math.sin(ry)};
            end
            ret = RaySceneQuery({fp[1], fp[2] + 1.25, fp[3]}, dir)
        end



        callback(self, ret);
        
    end

    if self:getProperty("mode") == "auto" then
        self.timer = Timer(tonumber(self:getProperty("atk_speed")) or 100, trigger);
    end

    if self.shock then 
        self.shock:stop();
        self.shock = nil;
    end

    
    trigger();         

end

function Gun:stop()
    if self.timer then 
        self.timer:stop()
        self.timer = nil;
    end
    

    Idle()
    self.isTriggered = false;
end

function Gun:clean()
    self:stop();
    if self.shock then 
        self.shock:stop()
        self.shock = nil;
    end

    if self.timer then 
        self.timer:stop()
        self.timer = nil;
    end
end

function Gun:getAmmoCount()
    return self.ammoCount;
end

function Gun:setAmmoCount(count)
    self.ammoCount = count or tonumber(self:getProperty("ammo")) or 0;
end

function Gun:reload()
    if self.reloading then 
        return 
    end
    local items = Repsitory.getAllItems(GetPlayerId(),"inventory");
        
    for k,v in pairs(items) do 
        if v.id == tonumber(self:getProperty("ammo_id")) and v.count > 0 then 
            local count = math.min(tonumber(self:getProperty("ammo")) - self.ammoCount, v.count);
            Animate("reload")
            self.reloading = true;
            Delay(tonumber(self:getProperty("reload_speed")),function()
                Repository.setItem(GetPlayerId(), "inventory", k, v.id, v.count - count);
                self.ammoCount = self.ammoCount + count;
                Idle()
                self.reloading = false;
            end)
            break;
        end
    end
end