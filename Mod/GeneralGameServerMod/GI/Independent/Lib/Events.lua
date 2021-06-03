local Events = module("Events")

Events.Type = 
{
    Replaceable = 1,
    Expansion = 2,
}

function Events:new(type)
    local o = {callbacks = {}, type = type or Events.Type.Replaceable}
    setmetatable(o, {__index = Events, __newindex = function (...)
        echotable("error")
    end});

    return o;
end

function Events:on(event, callback)
    if self.type == 1 then
        self.callbacks[event] = callback;
    else
        self.callbacks[event] = self.callbacks[event] or {}
        self.callbacks[event][#self.callbacks + 1] = callback; 
    end
    return self;
end

function Events:del(event, callback)
    if self.type == 1 then 
        self.callbacks[event] = nil;
    elseif self.callbacks[event] then
        for k,v in ipairs(self.callbacks[event]) do 
            if v == callback then 
                self.callbacks[k] = nil;
                return ;
            end
        end
    end
end

function Events:notify(event, ...)
    if self.type == 1 then 
        if self.callbacks[event] then 
            self.callbacks[event](...)
        end
    else
        for k,v in ipairs(self.callbacks[event] or {}) do 
            v(...);
        end
    end
    return self;
end
