local StateMachine = require("SimpleStateMachine")

local State = {};

function State:new(o)
    o = o or {}
    setmetatable(o, {__index = State});
    return o;
end

function State:getName()
    return self.name;
end

function State:enter()
end
function State:inDo()
end
function State:leave()
end

function State:process(...)
end

function StateMachine:new(o)
    o = o or {}
    o.states = {};
    setmetatable(o, {__index = StateMachine});
    return o;
end

function StateMachine:process(...)
    local current = self.current;
    if not current then return end;
    
    local next = current:process(...);
    if not next then return end;
    
    local state = self.states[next];
    if not state then return next end;

    current:leave(...);
    state:enter(...);
    self.current = state;
    state:inDo(...);
    return next, true;
end

function StateMachine:transitionTo(statename, ...)
    if not self.current then 
        local state = self.states[statename];
        if not state then return end;

        state:enter(statename,...);
        self.current = state;
        state:inDo(...);
    else
        self:process(statename, ...);
    end
end

function StateMachine:createState(name , istate)
    if self.states[name] then 
        error(string.format("state named %s is existed.", name))
    end
    local state = State:new(istate);
    state.name = name;
    self.states[name] = state;
    
    return state;
end

function StateMachine:destroyState(name)
    self.states[name] = nil;
end

function StateMachine:destroyAll()
    self.states = {};
    self.current = nil;
end

function StateMachine:getCurrentState()
    return self.current;
end