--[[
Title: Slot
Author(s): wxa
Date: 2020/6/30
Desc: 插槽组件
use the lib:
-------------------------------------------------------
local Scope = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Scope.lua");
-------------------------------------------------------
]]

local Scope = (NPL and NPL.export) and NPL.export() or {};
local nid = 0;

local function NewScope(deep)
    nid = nid + 1;

    local o = {};
    local meta = {};            -- 元表
    local data = {};            -- 数据  任意存取
    local scope = Scope:new();  -- 类
    local __nid = nid;          -- ID
    local __metatable = nil;    -- 元表
    local __deep = deep;        -- 字表是否扩展成scope
    
    -- 设置元表
    scope.SetMetaTable = function(self, metatable)
        __metatable = metatable;
    end

    -- 获取元表
    scope.GetMetaTable = function()
        return __metatable;
    end

    -- 获取原生表 用于调试
    scope.GetRawData = function()
        return data; 
    end

    -- 获取NId
    scope.GetID = function() 
        return __nid;
    end

    -- 更新数据
    meta.__newindex = function(obj, key, val)
        -- print("set", __nid, key, val);

        -- __scope 类标识
        if (key == "__scope") then 
            echo("Error: scope object disable set key: " .. key);
            return 
        end

        -- 相同则直接返回
        if (data[key] == val) then return  end

        -- 如果为表则构建新的scope
        if (type(val) == "table" and not val.__scope and __deep) then
            val = Scope.New(val);
        end

        -- 更新数据值
        data[key] = val;

        -- newvalue
        if (type(data.__newvalue) == "function") then
            data.__newvalue(obj, key, val);
        end
    end

    -- 读取数据
    meta.__index = function(obj, key)
        -- 识别是否Scope 对象
        if (key == "__scope") then return true end

        -- 取更新表
        if (data[key]) then 
            -- print("get", __nid, key);
            return data[key];
         end
        
        -- 获取只读ID
        if (key == "__nid") then return __nid end

        -- 取类数据
        if (scope[key]) then return scope[key] end

        -- 取元表
        return __metatable and __metatable[key];
    end
    
    -- 遍历
    meta.__pairs = function(obj)
        return pairs(data);
    end

    -- 遍历
    meta.__ipairs = function(obj)
        return ipairs(data);
    end

    -- 长度
    meta.__len = function()
        return #data;
    end

    setmetatable(o, meta);
    return o;
end

-- 新建一个scope  deep 为真则字表scope化
function Scope.New(obj, deep)
    obj = type(obj) == "table" and obj or {};
    -- 如果已经是Scope对象直接返回
    if (obj.__scope) then return obj end

    -- 新建Scope
    local scope = NewScope(deep);

    -- 拷贝数据
    local lookup_table = {[obj] = scope};   -- 防止互相嵌套造成死循环
    local function _copy(dst, src, deep)
        for key, val in pairs(src) do
            if (lookup_table[val]) then
                dst[key] = lookup_table[val];
            elseif (type(val) == "table" and not val.__scope and deep) then   -- 已经是scope则无需新增
                local _scope = NewScope();
                lookup_table[val] = _scope;
                _copy(_scope, val);
                dst[key] = _scope;
            else
                dst[key] = val;
            end
        end
    end

    _copy(scope, obj, deep);

    return scope;
end

function Scope:new(o)
    o = o or {};
    -- 设置元素
    setmetatable(o, {__index = Scope});
    -- 调用构造函数
    o:ctor();
    -- 返回对象
    return o;
end

function Scope:ctor()
end

-- 是否是Scope
function Scope:IsScope()
    return self.__scope;
end

-- 设置值
function Scope:Set(key, val)
    self[key] = val;
end

-- 获取值
function Scope:Get(key)
    return self[key];
end

-- 获取ID
-- local s = Scope.New({1,2,3});
-- for key, val in ipairs(s) do
--     print(key, val);
-- end
-- print(#s, rawlen(s));
-- print(s[1]);
-- s.self = s;
-- s.self.key = 1;
-- print(s.key)
-- s.key = 1;
-- s.__newindex = 1;
-- print(s.__newindex);
-- s.__index = nil;
-- s.obj.key = 2;
-- s.object = {val = 2};
-- print(s.key, s.val, s.obj.key);

-- 元表测试
-- local s1 = Scope.New();
-- local s2 = Scope.New();
-- s1.s1 = 1;
-- s2.s2 = 2;

-- s2:SetMetaTable(s1);
-- print(s2.s1, s2.s2);
-- s2.s1 = 3;
-- print(s2.s1, s2.s2);
-- print(s2:GetMetaTable() == s1)
