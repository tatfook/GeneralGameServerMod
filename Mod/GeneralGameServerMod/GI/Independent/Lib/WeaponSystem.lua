local WeaponSystem = module("WeaponSystem")
local Repository = require("Repository")
local Gun = require("Gun")
local Melee = require("Melee")
local Events = require("Events")
local events = Events:new();
local weapons = {};
local lastWeapon = nil
local cameraMode = {0, 3};

local function createWeapon(id)
    local weapon = GetWeaponFromId(id);
    if not weapon then return end;
    
    if weapon.type == "gun" then
        return Gun:new(id, weapon); 
    elseif weapon.type == "melee" then
        return Melee:new(id, weapon)
    end
end

local function sync()
    for i = 1, 9 do 
        local item = GetItemStackFromInventory(i)
        if item then 
            if weapons[i] and weapons[i].id == item.id then 
            else 
                if weapons[i] then 
                    -- weapons[i]:stop();
                end
                weapons[i] = createWeapon(item.id);
            end 
        elseif   weapons[i] then 
            weapons[i]:stop();
            weapons[i] = nil;
        end
    end

end

function WeaponSystem.init()
    Repository.on(function (ent, rep)
        if rep ~= "inventory" then return end;

        sync();
    end)

    sync();
end

WeaponSystem.sync = sync

function WeaponSystem.input(e)
    local key = e.keyname;
    local type = e.event_type;
    local button = e.mouse_button;
    if (type == "mouseWheelEvent" ) or (key and key:match("^DIK_(%d)") )then
        if lastWeapon then
            lastWeapon:clean();
        end
    end
    lastWeapon = WeaponSystem.getCurrent()
    if not lastWeapon then return end
    return lastWeapon:input(e, function (...)
        events:notify("hit", ...);
    end);

end

function WeaponSystem.onHit(callback)
    events:on("hit", callback);
end


function WeaponSystem.get(index)
    return weapons[index];
end

function WeaponSystem.getCurrent()
    local index = GetHandToolIndex();
    return weapons[index];
end

function WeaponSystem.getAll()
    return weapons
end

function WeaponSystem.stop()
    if lastWeapon then 
        lastWeapon:stop();
        lastWeapon = nil;
    end
end

function WeaponSystem.SetViewMode(m1, m2)
    cameraMode = {m1,m2}
end

WeaponSystem.init()