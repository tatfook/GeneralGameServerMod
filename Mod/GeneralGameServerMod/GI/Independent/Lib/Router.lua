local Router = module("Router")

local receivers = {};
local senders = {};
local idx = 0;
local Response = {};

function Response:new(o)
    o = o or {};
    setmetatable(o, {__index = Response});
    return o;
end

function Response:send(msg)
    SendTo(self.id, {module = "Router", msg = msg, idx = self.idx});
end

function Router.receiveMsg(msg)
    local from = msg._from;
    local type = msg.type;
    local i = msg.idx;

    if type then 
        if type == "_redirect" then 
            local target = msg.target;
            local msg = msg.msg;
            SendTo(target, {module = "Router", type = msg.type, msg = msg.msg});
        elseif type == "_broadcast" then 
            local msg = msg.msg;
            SendTo(nil, {module = "Router", type = msg.type, msg = msg.msg})
            SendTo("host", {module = "Router", type = msg.type, msg = msg.msg})
        else
            local rec = receivers[type];
            if not rec then return end

            local res;
            if i then 
                res = Response:new({id = from, idx = i})
            end
            rec(msg.msg, res);
        end
    elseif i then 
        local snd = senders[i];
        if not snd then return end
        senders[i] = nil;
        snd(msg.msg);
    end
end

function Router.send(type,  msg, callback)
    senders[idx] = callback;
    SendTo("host", {module = "Router", type = type, msg = msg, idx = idx});
    idx = idx + 1;
end

function Router.sendto(target ,type, msg)
    if target then 
        SendTo("host", {module = "Router",target = target, type = "_redirect", msg = {type = type, msg = msg}});
    end
end

function Router.broadcast(type, msg)
    SendTo("host", {module = "Router", type = "_broadcast", msg = {type = type, msg = msg}})
end

function Router.receive(type, callback)
    receivers[type] = callback;
end
