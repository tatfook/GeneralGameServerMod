--[[
Title: Scope
Author(s): wxa
Date: 2020/6/30
Desc: 插槽组件
use the lib:
-------------------------------------------------------
local Scope = NPL.load("Mod/GeneralGameServerMod/UI/Vue/Scope.lua");
-------------------------------------------------------
]]

local __global_index_callback__ = nil;
local __global_newindex_callback__ = nil;

local __len_meta_method_test_table__ = setmetatable({}, {__len = function() return 1 end });
local __is_support_len_meta_method__ = #__len_meta_method_test_table__ == 1;

local __is_support_pairs_meta_method__ = false;
local __is_support_ipairs_meta_method__ = false;
pairs(setmetatable({}, {__pairs = function() __is_support_pairs_meta_method__ = true end}));
ipairs(setmetatable({}, {__ipairs = function() __is_support_ipairs_meta_method__ = true end}));


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
-- 是否支持__len
Scope.__is_support_len_meta_method__= __is_support_len_meta_method__;
Scope.__is_support_pairs_meta_method__ = __is_support_pairs_meta_method__;
Scope.__is_support_ipairs_meta_method__ = __is_support_ipairs_meta_method__;

-- 获取值
local function __get_val__(val)
    -- 非普通表不做响应式
    if (type(val) ~= "table" or getmetatable(val) ~= nil or Scope:__is_scope__(val)) then return val end
    -- 普通表构建scope
    return Scope:__new__(val);
end

-- 获取值
Scope.__get_val__ = __get_val__;


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

    -- 遍历  若不支持__pairs 外部将无法遍历对象 只能通过ToPlainObject值去遍历
    if (__is_support_pairs_meta_method__) then
        metatable.__pairs = function(scope)
            return pairs(metatable.__data__);
        end
    end

    -- 遍历
    if (__is_support_ipairs_meta_method__ and __is_support_len_meta_method__) then
        metatable.__ipairs = function(scope)
            return ipairs(metatable.__data__);
        end
    end

    -- 长度
    if (__is_support_len_meta_method__) then
        metatable.__len = function(scope)
            return #metatable.__data__;
        end
    end

    -- 构建scope对象
    local scope = setmetatable({}, metatable);
    
    -- 设置scope
    metatable.__scope__ = scope;
    metatable.__metatable__ = metatable;

    -- 拷贝原始数据时, 禁止触发回调
    metatable.__enable_index_callback__ = false;
    metatable.__enable_newindex_callback__ = false;
    if (type(obj) == "table") then 
        for key, val in pairs(obj) do
            scope[key] = val;
        end
    end
    metatable.__enable_index_callback__ = true;
    metatable.__enable_newindex_callback__ = true;
    -- 新建触发一次读取
    metatable:__call_index_callback__(scope, nil);

    return scope;
end

local scopeId = 0;
-- 构造函数
function Scope:__ctor__()
    scopeId = scopeId + 1;
    self.__id__ = scopeId ;
    self.__data__ = {};                                 -- 数据表
    self.__length__ = 0;                                -- 列表长度
    self.__scope__ = true;                              -- 是否为Scope
    self.__index_callback__ = nil;                      -- 读取回调
    self.__newindex_callback__ = nil;                   -- 写入回调   
    self.__enable_index_callback__ = true;              -- 使能index回调
    self.__enable_newindex_callback__ = true;           -- 使能newindex回调
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

-- 读取回调
function Scope:__call_index_callback__(scope, key)
    if (not self.__enable_index_callback__) then return end

    local val = key and self.__data__[key];

    -- 值为scope触发本身读索引
    if (self:__is_scope__(val)) then return val:__call_index_callback__(val, nil) end

    -- 触发普通值的读索引
    self:__call_global_index_callback__(scope, key);
    if (type(self.__index_callback__) == "function") then self.__index_callback__(scope, key) end
end

-- 设置读取回调
function Scope:__set_index_callback__(__index__)
    self.__index_callback__ = __index__;
end

-- 设置数字属性
function Scope:__set_by_index__(scope, index, value)
    -- print(__is_support_len_meta_method__, scope, index, value);
    if (__is_support_len_meta_method__) then
        self.__data__[index] = __get_val__(value);
    else
        rawset(scope, index, __get_val__(value));
    end

    self:__call_newindex_callback__(scope, nil, scope, scope);
end

-- 获取数字属性
function Scope:__get_by_index__(scope, index)
    self:__call_index_callback__(scope, nil);  -- 针对列表触发列表整体更新
    return if_else(__is_support_len_meta_method__, self.__data__[index], rawget(scope, index));
end

-- 获取键值
function Scope:__get__(scope, key)
    if (type(key) == "number") then return self:__get_by_index__(scope, key) end

    -- 内置属性直接返回
    if (self:__is_inner_attr__(key)) then return self[key] end

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
    if (not self.__enable_newindex_callback__) then return end

    -- print("__call_newindex_callback__", scope, key);

    -- 触发监控回调
    local watch = key and self.__watch__[key];
    if (watch) then
        for _, func in pairs(watch) do
            func(newval, oldval);
        end
    end

    -- 旧值为scope触发本身写索引
    if (key and self:__is_scope__(oldval)) then return oldval:__call_newindex_callback__(oldval, nil, newval, oldval) end
    
    -- 触发普通值的写索引
    self:__call_global_newindex_callback__(scope, key, newval, oldval);
    if (type(self.__newindex_callback__) == "function") then self.__newindex_callback__(scope, key, newval, oldval) end
end

-- 设置写入回调   
function Scope:__set_newindex_callback__(__newindex__)
    self.__newindex_callback__ = __newindex__;
end

-- 设置键值
function Scope:__set__(scope, key, val)
    if (type(key) == "number") then return self:__set_by_index__(scope, key, val) end
    
    if (self:__is_inner_attr__(key)) then
        if (self.__inner_can_set_attrs__[key]) then self[key] = val end
        return;
    end

    -- 更新值
    local oldval = self.__data__[key];
    self.__data__[key] = __get_val__(val);

    -- 相同直接退出
    if (oldval == val) then return end

    -- 触发更新回调
    self:__call_newindex_callback__(scope, key, val, oldval);
end

-- 获取真实数据
function Scope:__get_data__()
    return self.__data__;
end

-- 设置真实数据
function Scope:__set_data__(data)
    if (type(data) ~= "table") then return end
    self.__data__ = data;
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

-- 通知监控
function Scope:Notify(key)
    self:__call_newindex_callback__(self.__scope__, key);
end

-- 转化为普通对象
function Scope:ToPlainObject()
    local __data__ = self.__data__;
    if (not __is_support_len_meta_method__) then
        for index, val in ipairs(self.__scope__) do
            __data__[index] = val;
        end
    end

    return __data__;
end