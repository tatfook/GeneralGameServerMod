local PlayerKeeper = module("PlayerKeeper")
local players = {};
local callbacks = {};
local stated = false;

local function notify(id, isExisted)
    for k,v in ipairs(callbacks or {}) do 
        v(id, isExisted);
    end
end

local function keepalive ()
    Delay(1000, function ()
        local removelist = {}
        for k,v in pairs(players) do 
            if v and GetEntityById(k) == nil then 
                removelist[#removelist + 1] = k
            end
        end
        for k,v in ipairs(removelist) do 
            players[v] = nil;
            notify(v, false);
        end
        keepalive();
    end)
end

function PlayerKeeper.listen(callback)
    callbacks[#callbacks + 1] = callback;
end

function PlayerKeeper.receiveMsg(msg)
    local from = msg._from
    local exist = msg.exist;

    if msg.all then 
        for k,v in pairs(msg.all or {}) do 
            if players[k] ~= v then 
                notify(k, v);
                players[k] = v;
            end
        end
    elseif players[from] ~= exist then 
        players[from] = exist or nil;
        notify(from, exist);

        if started then return end
        started = true;
        keepalive();
        -- SendTo(from, {module="PlayerKeeper", all = players})
    end
end

function PlayerKeeper.getAll()
    return players;
end

SendTo("host", {module= "PlayerKeeper", exist = true})
-- keepalive();