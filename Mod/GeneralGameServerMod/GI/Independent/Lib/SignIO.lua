--[[
    local sign = SignIO:new(19200, 1, 19200);
    local content = sign:read();
    sign:write("hello")
]]

local SignIO = module("SignIO")

function SignIO:new( x,y,z)
    local o = {x = x, y = y, z = z}
    setmetatable(o, {__index = SignIO});
    local id, data, entity = GetBlockFull(x,y,z);
    return o;
end

function SignIO:isValid()
    local id, data, entity = GetBlockFull(self.x,self.y,self.z);
    if entity then 
        self.content = {name = "cmd", [1] = {name = "![CDATA["}}
        if entity[1] then 
            if type(entity[1]) == "string" then 
                self.content[1][1] = entity[1];
            else
                self.content = entity;
            end
        else
            entity[1] = self.content;
        end
    end
    self.id = id;
    self.data = data;
    self.entity = entity;
    return self.entity ~= nil and self.entity.attr ~= nil and self.entity.attr.class == "EntitySign"; 
end

function SignIO:read()
    if not self:isValid() then return end;
    return self.content[1][1];
end

function SignIO:write(str)
    if not self:isValid() then return end;
    self.content[1][1] = tostring(str);
    SetBlock(self.x, self.y , self.z, self.id, self.data, nil, self.entity);
end
