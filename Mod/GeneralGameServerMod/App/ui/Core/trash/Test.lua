
local function Inherit(baseClass, inheritClass)
	if (type(baseClass) ~= "table") then baseClass = nil end
	
    local inheritClass = inheritClass or {};
    local inheritClassMetaTable = { __index = inheritClass };

    function inheritClass:___new___(o)
        local o = o or {}
        
        -- 递归基类构造函数
        if(baseClass and baseClass.___new___ ~= nil) then baseClass:___new___(o) end

        -- 设置实例元表
        setmetatable(o, rawget(inheritClass, "__metatable") or inheritClassMetaTable);
        
        -- 调用构造函数
        local __ctor__ = rawget(inheritClass, "__ctor__");
		if(__ctor__) then __ctor__(o) end
		
        return o;
    end

    inheritClass._super = baseClass;
    if (baseClass ~= nil) then
        setmetatable(inheritClass, { __index = baseClass } )
    end

    return inheritClass
end

local Scope = Inherit();
Scope.__inherit__ = Inherit;

function Scope:__new__()
    local metatable = self:___new___();
    -- 获取值
    metatable.__index = function(scope, key)
        return metatable[key] or metatable:__get__(scope, key);
    end

    -- 设置值
    metatable.__newindex = function(scope, key, val)
        metatable:__set__(scope, key, val);
    end

    -- 遍历
    metatable.__pairs = function(scope)
        return pairs(metatable.__data__);
    end

    -- 遍历
    metatable.__ipairs = function(scope)
        return ipairs(metatable.__data__);
    end

    -- 长度
    metatable.__len = function(scope)
        return #(metatable.__data__);
    end

    return setmetatable({}, metatable);
end

function Scope:__ctor__()
    self.__data__ = {};
end

function Scope:__set__(scope, key, val)
    print("__set__", scope, key, val);
    self.__data__[key] = val;
end

function Scope:__get__(scope, key)
    print("__get__", scope, key);
    return self.__data__[key]
end

function Scope:Print()
    print(self)
end
-- local scope = Scope:__new__();
-- scope[1] = 2;
-- scope[2] = 5;
-- print(#scope, scope[1], scope[2])
-- local ScopeA = Scope.__inherit__(Scope);
-- function ScopeA:PrintA()
--     print(self, self.key);
-- end
-- local scope = ScopeA:__new__():__new__();
-- print(scope)
-- scope.key = 1;
-- print(scope.key);
-- scope:Print();
-- scope:PrintA();


-- local obj = setmetatable({}, {
--     __insert = function()
--         print("--------------")
--     end,
--     __len = function()
--         print("__len")
--         return 0;
--     end
-- })

-- table.insert(obj, 1, 1);
-- print(#obj)


local A = setmetatable({}, {
    __index = function(self)
        print("A meta function self = ", self);
    end
});

function A:Self()
    print("A funcion self = ", self);
end

local B = setmetatable({}, {
    __index = A
});

print("A = ", A);
print("B = ", B);
print(B.key, B:Self());

-- A = 	table: 0x1693890
-- B = 	table: 0x16972d0
-- A meta function self = 	table: 0x1693890
-- A funcion self = 	table: 0x16972d0
