local Particle = module("Particle")
local Emitter = {};
local Affector = {} 

local function serialize(value)
    if type(value) == "string" then 
        return string.format('"%s"',value);
    elseif type(value) == "table" then 
        if value.serialize then 
            return value:serialize();
        else
            local str = "";
            for k,v in pairs(value) do 
                str = string.format("%s[%s]=%s,",str, serialize(k), serialize(v));
            end
            str = string.format("{%s}", str);
            return str;
        end
    else
        return tostring(value);
    end
end

local particleDefaults = {
    dimensions = {1,1},
    emitter = {type = "Point"},
    texture = "gameassets/textures/particle/smoke.png",
    quota = 64,
    emitter_quota = 64
}

local emitterDefaults = {
    direction = {0,1,0},
    velocity = {10,10},
    time_to_live = {10, 10},
    emission_rate = 1,
    position = {0, 0, 0}   
}

local function inherit(inst, base,obj, data)
    local function setvalue(inst, key, value)
        data[key] = value;
        return base.setValue(inst, key, value)
    end

    local function getvalue(inst, key)
        return obj[key] or base.getValue(inst, key)
    end
    inst.serialize = base.serialize; 
    setmetatable(inst, {__index = getvalue, __newindex = setvalue})
end

function Particle:new(x,y,z,tbl)
    local pobj = CreateParticle(x,y,z);
    local data = {};
    local proxy = {_data = data, _obj = pobj}
    local obj = {}
    inherit(proxy, Particle, pobj, data)
    setmetatable(obj, {__index = proxy, __newindex = proxy})

    for k,v in pairs(particleDefaults) do 
        obj[k] = v;
    end
    for k,v in pairs(tbl or {}) do 
        obj[k] = v;
    end
    return obj
end

function Particle:setValue(key, value)
    local data = self._data;
    local obj = self._obj
    if key == "width" then 
        obj:setDefaultDimensions(value, data.height);
        data.dimensions = data.dimensions or {};
        data.dimensions[1] = value;
    elseif key == "height" then 
        obj:setDefaultDimensions(data.width, value);        
        data.dimensions = data.dimensions or {}
        data.dimensions[2] = value;
    elseif key == "dimensions" then 
        local dim = value or {}
        data.width = dim[1] or dim.x
        data.height = dim[2] or dim.y
        obj:setDefaultDimensions(data.width, data.height);
    elseif key == "emitter" then 
        obj:removeAllEmitters()
        data.emitter = nil;
        if type (value) == "table"then 
            if #value ~= 0 then 
                local list = {}
                for _, cfg in ipairs(value) do 
                    local e = Emitter:new(obj, cfg)
                    table.insert(list, e);
                end
                data.emitter = list;
            elseif next(value) then
                local e = Emitter:new(obj, value);
                data.emitter = e;
            end
            
        end
    elseif key == "affector" then 
        obj:removeAllAffectors();
        data.affector = nil;
        if type (value) == "table" then 
            if #value ~= 0 then
                local list = {}
                for _, cfg in ipairs(value) do 
                    local a = Affector:new(obj, cfg)
                    table.insert(list, a);
                end
                data.affector = list;
            elseif next(value) then
                data.affector = Affector:new(obj, value);
            end
        end
    elseif key == "life" then 
        obj.mLife = value;
    elseif key == "quota" then 
        obj:setParticleQuota(value)
        if data.emitter_quota > value then 
            data.emitter_quota = value;
            obj:setEmittedEmitterQuota(value);
        end
    elseif key == "emitter_quota" then 
        value = math.min(value, data.quota or particleDefaults.quota);
        obj:setEmittedEmitterQuota(value);
    elseif key == "texture" then 
        if type(value) == "table" then 
            GetResourceImage(value, function (path)
                obj:setTexture(path);
            end)
        else
            obj:setTexture(value);
        end
    elseif key == "bound_radius" then 
        obj:setBoundRadius(value);
    end
end

function Particle:getValue(key)
    return self._data[key]
end

function Particle:serialize()
    return serialize(self._data);
end

function Emitter:new(scene, config)
    local eobj = scene:addEmitter(config.type or "Point");
    local data = {} 
    local obj = {_obj = eobj,_data = data, _scene = scene};
    inherit(obj, Emitter, eobj, data)

    for k,v in pairs(emitterDefaults) do 
        obj[k] = v;
    end
    for k,v in pairs(config or {}) do 
        obj[k] = v;
    end
    return obj
end

local emitter_idx = 0;
function Emitter:setValue(key, value)
    local obj = self._obj;
    local data = self._data;
    if key == "direction" then 
        local dir = value or {};
        obj:setParticleDirection(dir[1] or dir.x , dir[2] or dir.y, dir[3] or dir.z);
    elseif key == "velocity" then 
        if type(value) == "number" then
            obj:setParticleVelocity(value, value);
        elseif type(value) == "table" then 
            obj:setParticleVelocity(value[1], value[2]);
        end
    elseif key == "time_to_live" then 
        if type(value) == "number" then
            obj:setParticleTimeToLive(value, value);
        elseif type(value) == "table" then 
            obj:setParticleTimeToLive(value[1], value[2]);
        end
    elseif key == "emitted_emitter" then 
        if data.emitted_emitter then
            self._scene:removeEmitter(data.emitted_emitter)
        end
        local e = Emitter:new(self._scene, value )
        emitter_idx = emitter_idx + 1;
        e.name = string.format("%s",emitter_idx)  
        obj:setEmittedEmitter(e.name);
    elseif key == "emission_rate" then 
        obj:setEmissionRate(value)
    elseif key == "name" then 
        obj:setName(value)
    elseif key == "position" then 
        local pos = value or {}
        obj:setPosition(pos[1] or pos.x, pos[2] or pos.y, pos[3] or pos.z);
    elseif key == "size" then 
        if obj.setSize then
            local size = value or  {}
            obj:setSizeInAxisAlignedParentCoord(size[1], size[2], size[3])
        end
    elseif key == "enabled" then 
        obj:setEnabled(value)
    elseif key == "color" then 
        local c1, c2;
        if type(value[1]) == "table" then 
            
            c1= value[1] or {}
            c2 = value[2] or {}
        else
            c1 = value or {}
            c2 = c1;
        end
        obj:setParticleColour(c1[1], c1[2], c1[3], c1[4],c2[1], c2[2], c2[3], c2[4]);
    elseif key == "init_particle" then 
        local old = obj._initParticle
        obj._initParticle = function (...)
            old(...);
            value(obj,...);
        end
    elseif key == "duration" then 
        if type(value) == "number" then
            obj:setDuration(value, value);
        elseif type(value) == "table" then 
            obj:setDuration(value[1], value[2]);
        end
    end
end

function Emitter:getValue(key)
    return self._data[key]
end

function Emitter:serialize()
    return serialize(self._data);
end

function Affector:new(scene, config)
    config = config or {}
    local aobj = scene:addAffector(config.type or "LinearForce");
    local data = {}
    local obj = {_obj = aobj, _data = data};
    inherit(obj, Affector, aobj, data)
    
    for k,v in pairs(config or {}) do 
        obj[k] = v;
    end
    return obj
end

function Affector:setValue(key, value)
    local obj = self._obj;
    local data = self._data;

    if key == "force" and obj.setForceVector then
        local dir = value or {};
        obj:setForceVector(value.x or value[1], value.y or value[2], value.z or value[3])
    elseif key == "rotation_speed_range" and obj.setRotationSpeedRange then 
        local range = value or {}
        obj:setRotationSpeedRange(range[1], range[2]);
    elseif key == "rotation_range" and obj.setRotationRange then 
        local range = value or {}
        obj:setRotationRange(range[1], range[2]);        
    elseif key == "image" and obj.setImageAdjust then 
        obj:setImageAdjust(value);
    elseif key == "init_particle" and obj.setMethod then 
        obj:setMethod(function (...) dcall(value, ...) end, data.update_particle);
    elseif key == "update_particle" and obj.setMethod then 
        obj:setMethod(data.init_particle, function (...) dcall(value, ...)end);
    end
end

function Affector:getValue(key)
    return self._data[key]
end

function Affector:serialize()
    return serialize(self._data);
end