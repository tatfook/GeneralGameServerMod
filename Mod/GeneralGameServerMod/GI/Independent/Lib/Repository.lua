local Repositories = module("Repository")
local EntityWatcher = require("EntityWatcher")
local Events = require("Events")
local inventory_size = 9;

local reps = {}
local repository = {};
local inventory = {__index = repository};
local events = Events:new(Events.Type.Expansion);

local function setRep(rep)
    reps[rep.id] = reps[rep.id] or {};
    reps[rep.id][rep.name] = rep;
end

local function getRep(id, name)
    if not reps[id] then
        reps[id] = {};
    end
    
    if not reps[id][name] then 
        local rep = nil
        if name == "inventory" then 
            rep = inventory:new(name, id)
        else
            rep = repository:new(name, id);
        end
    end
    return reps[id][name]
end

local function getIndex(repname, index)
    return string.format("Repository.%s.%s", repname, index);
end

function repository:new(name, entityid)
    local o = {name = name, id = entityid}
    setmetatable(o, {__index = repository});
    setRep(o);
    return o;
end

function repository:setItem(index, itemid, count, serverdata)
    local props = EntityWatcher.get(self.id);
    if not props then 
        return 
    end
    local item = props:getProperty(getIndex(self.name, index));
    count = math.max(0, math.min(0xffffffff, count));
    if item and item.id == itemid then 
        if count ~= item.count then 
            props:setProperty(getIndex(self.name, index) .. "." .. "count",  count);
        else
            return;
        end
    elseif count ==  0 then 
        props:setProperty(getIndex(self.name, index) ,  nil);
    else
        props:setProperty(getIndex(self.name, index), {id = itemid, count = count, serverdata = serverdata, index = index});
    end
end

function repository:getItem(index)
    local props = EntityWatcher.get(self.id);
    if not props then 
        return 
    end
    return props:getProperty(getIndex(self.name, index));
end

function repository:getAll()
    local props = EntityWatcher.get(self.id);
    if not props then 
        return 
    end

    local list = {};
    for k,v in pairs(props:getProperty("Repository." .. self.name) or {}) do 
        list[v.index] = v;
    end
    return list;
end

function repository:removeAll()
    local all = self:getAll();
    for k, v in pairs(all) do 
        self:removeItem(v.index, v.count);
    end
end

function repository:addItem(index, count)
    local item = self:getItem(index);
    if not item then return end;
    self:setItem(item.count + count);
end

function repository:removeItem(index, count)
    local item = self:getItem(index);
    if not item then return end;
    self:setItem(item.count - count);
end

function inventory:new(name, entityid)
    local o = {name = name, id = entityid}
    setmetatable(o, {__index = inventory});
    setRep(o);
    return o;
end

function inventory:setItem(index, itemid, count, serverdata)
    count = math.max(0, math.min(0xffffffff, count));
    local item = CreateItemStack(itemid, count, serverdata);
    local p = GetEntityById(self.id);
    if not p then return end;
    p.inventory:SetItemByBagPos(index, itemid, count, item);
    SendTo("host", {module = "Repository", event = "setItemToInventory", index = index, itemid = itemid, count = count, serverdata = serverdata, id = self.id });
    if GetHandToolIndex() == index then 
        SetHandToolIndex(index); -- refresh to other clients
    end
end

function inventory:getItem(index)
    local p = GetEntityById(self.id);
    if not p then return end;
    return p.inventory:GetItem(index);
end

function inventory:removeItem(index, count)
    local p = GetEntityById(self.id)
    if not p then return end;
    p.inventory:RemoveItem(index, count);
end

function inventory:getAll()
    local list = {};
    for i = 1, inventory_size do 
        list[i] = self:getItem(i);
    end
    return list;
end

function inventory:removeAll()
    for i = 1, inventory_size do 
        self:removeItem(i);
    end
end

function Repositories.setItem(entityid, repname, index, itemid, count)
    local rep = getRep(entityid, repname);

    rep:setItem(index, itemid, count);
end 

function Repositories.removeItem(entityid, repname, index, count)
    local rep = getRep(entityid, repname);

    rep:removeItem(index, itemid, count);
end

function Repositories.removeAllItems(entityid, repname)
    local rep = getRep(entityid, repname);
    rep:removeAll();
end

function Repositories.getItem(entityid, repname, index)
    local rep = getRep(entityid, repname);

    return rep:getItem(index);
end

function Repositories.getAllItems(entityid, repname)
    local rep = getRep(entityid, repname);

    return rep:getAll();
end

function Repositories.notify(event, ...)
    local callback = callbacks[event];
    for k,v in ipairs(callback or {}) do 
        v(...);
    end
end

function Repositories.on(callback)
    events:on("itemChanged", callback);
end

function Repositories.del( callback)
    events:del("itemChanged", callback)
end

local function init()
    -- local entityid = GetPlayerId();
    -- local player = EntityWatcher.get(entityid);

    local function register(entity)
        entity:on("property", function (key, value)
            local repname, index, prop = key:match("Repository%.(%w+)%.(%d+)%.?(.*)");
            if not repname or not index then 
                return 
            end
            local item = entity:getProperty(getIndex( repname, index));

            events:notify("itemChanged", entity, repname, id, index, item);
        end)


        GetEntityById(entity.id).inventory:SetOnChangedCallback(function ()
            events:notify("itemChanged",entity, "inventory");
        end)
    end

    local list = EntityWatcher.getAll()
    for id, entity in pairs(list) do
        if entity.type == "player" then
            register(entity);
        end
    end

    -- EntityWatcher.on("create", function (entity)
    --     register(entity);
    -- end)

end

function Repositories.clear()
end
echotable(Repositories.clear)

function receiveMsg(msg)
    local event = msg.event;
    local from = msg._from;
    if event == "setItemToInventory" then 
        local p = GetEntityById(msg.id);
        if not p then return end;
        local item = CreateItemStack(msg.itemid, msg.count, msg.serverdata);
        p.inventory:SetItemByBagPos(msg.index, msg.itemid, msg.count, item);
        p.inventory:NotifySlotChanged(msg.index, nil, msg.itemid);
    end
end

init();