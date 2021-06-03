local Inputs = module("Inputs")
local callbacks = {}

function Inputs.process(e)
    local key = e.keyname;
    local type = e.event_type
    local button = e.mouse_button;

    local cb;
    if key and callbacks[key] then 
        cb = callbacks[key];
    elseif button and callbacks[button] then 
        cb = callbacks[button]
    else 
        return false;
    end 

    if (type == "mousePressEvent" or type == "keyPressEvent") and cb.press then 
        return cb.press();
    elseif (type == "mouseReleaseEvent" or type == "keyReleaseEvent") and cb.release then 
        return cb.release();
    end 
end

function Inputs.clear()

end

setmetatable(Inputs, {
__newindex = function (tbl, key, value)

end, 
__index = function (tbl, key)
    if callbacks[key] then
        return callbacks[key];
    else
        local obj = {};
        callbacks[key] = obj
        return obj
    end
end})

