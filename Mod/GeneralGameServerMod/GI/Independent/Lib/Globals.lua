local Globals = module("Globals")
local EntityWatcher = require("EntityWatcher")

local globals ;

local function init()
    globals = EntityWatcher.create("__globals", "globals");
end

function Globals.set(key, value) 
    globals:setProperty(key, value);
end

function Globals.get(key)
    return globals:getProperty(key);
end

function Globals.on(key, callback)
    globals:on("property", function (k, v)
        if k == key then 
            callback(v);
        end
    end)
end


init();