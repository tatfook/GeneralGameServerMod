local Weapon = module("Weapon")

function Weapon:new(id, config)
    local o = {
        id = id,
        weapon = config, 
        properties = {},
    };
    setmetatable(o,{__index = Weapon});
    return o
end

function Weapon:clean()

end

function Weapon:setProperty(prop, value)
    self.properties[prop] = value;
end

function Weapon:getProperty(prop)
    return self.properties[prop] or self.weapon[prop];
end

function Weapon:input(e)
end