--[[
    events:
        EntityWatcher: 
            create, destroy
        Entity:
            destroy, property
]]
-- local PlayerKeeper = require("PlayerKeeper")
local EntityWatcher = module("EntityWatcher");

local entities = {};
local Entity = {};
local callbacks = {}

local function notify(event, ...)
    if callbacks[event] then 
        for k,v in ipairs(callbacks[event]) do
            v(...);
        end
    end
end

function EntityWatcher.destroy(id)
    local p = entities[id];
    if not p then return end;

    p.invalid = true;
    SendTo("host", {module = "EntityWatcher", event = "destroy", id = id});
end

function EntityWatcher.clear()
    EntityWatcher.destroy(GetPlayerId());
    for k, v in pairs(entities) do 
        v:notify("destroy");
    end
end

function EntityWatcher.on(event, callback)
    callbacks[event] = callbacks[event] or {}
    table.insert(callbacks[event], callback);
end

local function createImpl(id,type, o)
    if entities[id] then 

        entities[id]:merge(o or {});
        return entities[id];
    else
        local p = o or {id = id,type = type};
        p.callbacks = {};
        p.properties = p.properties or {};
        p.type = type;
        p.id = id;
        entities[id] = p;
        setmetatable(p, {__index = Entity});
        notify("create", p);
        
        return p;
    end
end

function EntityWatcher.create (id,type, o)
    local p = createImpl(id,type, o);
    local temp = {id = id, properties = {},callbacks = {}};
    Entity.merge(temp, p);
    SendTo("admin", {module = "EntityWatcher", event = "create", entity = temp});
    return p;
end

function EntityWatcher.get(id)
    return entities[id];
end

function EntityWatcher.getAll()
    return entities;
end


local function getvalue(field, path, default)
	local t = field;
	local w,d;
	for w,d in string.gmatch(path,"([%w_]+)(.?)") do
		if (nil == t[w]) then
			return default
		end
		t = t[w]
	end
		t = t or default
	return t;
end

local function setvalue(field, path, value)
	local t = field;
	local w,d;
	for w,d in string.gmatch(path,"([%w_]+)(.?)") do
		if (d == "") then
			t[w] = value
		else
			t[w] = t[w] or {}
			t = t[w]
		end
	end
end

function EntityWatcher.receiveMsg(msg)
    local event = msg.event;
    local from = msg._from;
    if event == "initreq" then 
        SendTo(from, {module = "EntityWatcher", event = "initres",entities = entities})
    elseif event == "initres" then 
        if msg.entities then 
            for k,v in pairs(msg.entities) do 
                entities[k] = createImpl(k,v.type, v);
            end
        end
    elseif event == "create" then 
        if msg.entity then 
            createImpl(msg.entity.id, msg.entity.type , msg.entity);
            SendTo(nil, {module = "EntityWatcher", event = "create", entity =  msg.entity});
        end
    elseif event == "destroy" then 
        local id = msg.id;  
        if id and entities[id] then 
            entities[id].invalid = true;
            notify("destroy", entities[id]);
            entities[id]:notify("destroy");
            entities[id] = nil;
            SendTo(nil, {module = "EntityWatcher", event = "destroy", id = id});
        end
    elseif event == "upprop" then 
        local id = msg.id;
        local ply =  entities[id];
        if id and ply then 
            local pp = msg.prop;
            local key = pp[1]
            local value = pp[2]
            setvalue(ply.properties, key, value);
            ply:notifyProperty(key);
            SendTo(nil, {module = "EntityWatcher", event = "upprop", prop = {key, value}, id = id})
        end
    end
end


function Entity:merge(p)
    self.type = p.type;
    for k,v in pairs(p.properties or {}) do 
        self.properties[k] = v;
        self:notifyProperty(k);
    end
end



function Entity:setProperty(key, value)
    setvalue(self.properties, key, value);
    SendTo("host", {module = "EntityWatcher", event = "upprop", prop = {key, value}, id = self.id})
end

function Entity:getProperty(key, value)
    return getvalue(self.properties, key);
end

function Entity:on(event, cb)
    self.callbacks[event] = self.callbacks[event] or {};
    self.callbacks[event][#self.callbacks[event] + 1] = cb;
end

function Entity:notify(event, ...)
    local cb = self.callbacks[event];
    for k,v in ipairs(cb or {}) do 
        v(...);
    end
end

function Entity:notifyProperty(key)
    local value = self:getProperty(key);
    local cb = self.callbacks["property"];
    if not cb or #cb == 0 then return end;

    for k,v in ipairs(cb) do 
        v(key, value);
    end
    
    key = key:match("(.+)%.[%w_]+$");
    if key then
        self:notifyProperty(key);
    end
    
end

-- PlayerKeeper.listen(function (id, exist)
--     if not exist then 
--         EntityWatcher.destroy(id);
--     end
-- end)



EntityWatcher.create(GetPlayerId(), "player");
SendTo("admin", {module = "EntityWatcher", event = "initreq"}) ;