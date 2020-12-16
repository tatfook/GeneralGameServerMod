--[[
Title: Scope
Author(s): wxa
Date: 2020/6/30
Desc: 插槽组件
use the lib:
-------------------------------------------------------
local Scope = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Scope.lua");
-------------------------------------------------------
]]

local __global_index_callback__ = nil;
local __global_newindex_callback__ = nil;

local function Inherit(baseClass, inheritClass)
	if (type(baseClass) ~= "table") then baseClass = nil end
	-- 初始化派生类
    local inheritClass = inheritClass or {};
    local inheritClassMetaTable = { __index = inheritClass };

    -- 新建实例函数
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

    -- 获取基类
    function inheritClass:__super_class__()
        return baseClass;
    end

    -- 设置基类
    if (baseClass ~= nil) then
        setmetatable(inheritClass, { __index = baseClass } )
    end

    return inheritClass
end

local Scope = Inherit(nil, NPL.export());
-- 基础函数
Scope.__inherit__ = Inherit;

-- 获取值
local function __get_val__(val)
    if (type(val) ~= "table" or Scope:__is_scope__(val)) then return val end
    return Scope:__new__(val);
end

-- 设置全局读取回调
function Scope.__set_global_index__(__index__)
    __global_index_callback__ = __index__;
end

-- 设置全局写入回调
function Scope.__set_global_newindex__(__newindex__)
    __global_newindex_callback__ = __newindex__;
end

function Scope:__new__(obj)
    if (self:__is_scope__(obj)) then return obj end

    local metatable = self:___new___();
    -- 获取值
    metatable.__index = function(scope, key)
        return metatable:__get__(scope, key);
    end

    -- 设置值
    metatable.__newindex = function(scope, key, val)
        metatable:__set__(scope, key, val);
    end

    -- 遍历
    metatable.__pairs = function(scope)
        return pairs(metatable.__data__);
    end

    -- 长度
    metatable.__len = function(scope)
        metatable:__call_index_callback__(scope, nil);
        local index = 1;
        while (scope[index] ~= nil) do index = index + 1 end
        return index - 1;
    end

    -- 遍历
    -- metatable.__ipairs = function(scope)
    --     return ipairs(metatable.__data__);
    -- end

    -- 构建scope对象
    local scope = setmetatable({}, metatable);
    
    -- 设置scope
    metatable.__scope__ = scope;
    metatable.__metatable__ = metatable;

    -- 拷贝原始数据
    if (type(obj) == "table") then 
        for key, val in pairs(obj) do
            scope[key] = val;
        end
    end

    return scope;
end

local scopeId = 0;
-- 构造函数
function Scope:__ctor__()
    scopeId = scopeId + 1;
    self.__id__ = scopeId ;
    self.__data__ = {};                                 -- 数据表      
    self.__scope__ = true;                              -- 是否为Scope
    self.__index_callback__ = nil;                      -- 读取回调
    self.__newindex_callback__ = nil;                   -- 写入回调   
    self.__watch__ = {};
    -- print("--------------------------scope:__ctor__-------------------------------");
    -- 内置可读写属性
    self.__inner_can_set_attrs__ = {
        __newindex_callback__ = true,
        __index_callback__ = true,
        __metatable_index__ = true,
    }
end

-- 初始化
function Scope:__init__()
    return self;
end

-- 是否是Scope
function Scope:__is_scope__(scope)
    return type(scope) == "table" and scope.__scope__ ~= nil;
end

-- 获取scope元表
function Scope:__get_scope_metatable__()
    return self.__metatable__;
end

-- 是否可以设置
function Scope:__is_inner_attr__(key)
    return (self.__data__[key] == nil and self.__metatable__[key] ~= nil) or self.__inner_can_set_attrs__[key];
end

function Scope:__set_metatable_index__(__metatable_index__)
    self.__metatable_index__ = __metatable_index__;
end

function Scope:__get_metatable_index__()
    return self.__metatable_index__;
end

-- 是否是scope更新
function Scope:__is_list_index__(key)
    return type(key) == "number" and key >= 1 and key <= (#self.__data__ + 1);
end

-- 全局读取回调
function Scope:__call_global_index_callback__(scope, key)
    if (type(__global_index_callback__) == "function") then __global_index_callback__(scope, key) end
end

-- Scope自身读取设置回调
function Scope:__call_index_and_newindex_callback__(scope, key)
    if (not key) then return end
    local val = self.__data__[key];
    if (self:__is_scope__(val)) then 
        self:__call_global_index_callback__(val, nil);
        self:__call_global_newindex_callback__(val, nil, val);
    end
end

-- 读取回调
function Scope:__call_index_callback__(scope, key)
    self:__call_global_index_callback__(scope, key);
    if (type(self.__index_callback__) == "function") then self.__index_callback__(scope, key) end
end

-- 设置读取回调
function Scope:__set_index_callback__(__index__)
    self.__index_callback__ = __index__;
end

-- 获取键值
function Scope:__get__(scope, key)
    if (type(key) == "number") then return rawget(scope, key) end

    -- 内置属性直接返回
    if (self:__is_inner_attr__(key)) then return self[key] end

    -- print("__index", scope, key);

    -- 无法正确识别数组更新(rawset, table.insert) 故当对scope类型值操作时, 统一出发当前scope的读取, 设置回调
    -- self:__call_index_and_newindex_callback__(scope, key);
    -- 触发回调
    self:__call_index_callback__(scope, key);

    -- 返回数据值
    if (self.__data__[key]) then return self.__data__[key] end

    -- 返回用户自定的读取
    if (type(self.__metatable_index__) == "table") then return self.__metatable_index__[key] end
    if (type(self.__metatable_index__) == "function") then return self.__metatable_index__(scope, key) end
end

-- 写入回调   
function Scope:__call_global_newindex_callback__(scope, key, newval, oldval)
    if (type(__global_newindex_callback__) == "function") then __global_newindex_callback__(scope, key, newval, oldval) end
end

-- 写入回调   
function Scope:__call_newindex_callback__(scope, key, newval, oldval)
    self:__call_global_newindex_callback__(scope, key, newval, oldval);
    if (type(self.__newindex_callback__) == "function") then self.__newindex_callback__(scope, key, newval, oldval) end

    local watch = self.__watch__[key];
    if (watch) then
        for _, func in pairs(watch) do
            func(newval, oldval);
        end
    end
end

-- 设置写入回调   
function Scope:__set_newindex_callback__(__newindex__)
    self.__newindex_callback__ = __newindex__;
end

-- 设置键值
function Scope:__set__(scope, key, val)
    if (type(key) == "number") then return rawset(scope, key, val) end
    
    if (self:__is_inner_attr__(key)) then
        if (self.__inner_can_set_attrs__[key]) then self[key] = val end
        return;
    end
    -- print("__newindex", scope, key, val);
    -- 触发旧值回调, 旧值的表地址可能为监听key 需要先触发一次
    self:__call_index_and_newindex_callback__(scope, key);

    -- 更新值
    local oldval = self.__data__[key];
    self.__data__[key] = __get_val__(val);

    -- 无法正确识别数组更新(rawset, table.insert) 故当对scope类型值操作时, 统一出发当前scope的读取, 设置回调
    self:__call_index_and_newindex_callback__(scope, key);

    -- 相同直接退出
    if (oldval == val and type(val) ~= "table") then return end

    -- 触发更新回调
    self:__call_newindex_callback__(scope, key, val, oldval);
end

-- 获取原生数据
function Scope:__get_raw_data__()
    local data = {};
    for i, val in ipairs(self) do
        if (self:__is_scope__(val)) then
            data[i] = val:__get_raw_data__();
        else
            data[i] = val;
        end
    end

    for key, val in pairs(self) do
        if (self:__is_scope__(val)) then
            data[key] = val:__get_raw_data__();
        else
            data[key] = val;
        end
    end

    return data;
end

-- 设置数据
function Scope:Set(key, val)
    self:__set__(self.__scope__, key, val);
end

-- 获取数据
function Scope:Get(key)
    return self:__get__(self.__scope__, key);
end

-- 监控
function Scope:Watch(key, func)
    local watch = self.__watch__[key] or {};
    self.__watch__[key] = watch;
    watch[func] = func;
end

-- 转化为普通对象
function Scope:ToPlainObject()
    return self:__get_raw_data__();
end