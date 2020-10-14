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

local __index = nil;
local __newindex = nil;

local function IsScope(scope)
    return type(scope) == "table" and scope.__scope;
end

local function __index_callback(obj, key)
    if (type(__index) ~= "function") then return end
    __index(obj, key);
end

local function __newindex_callback(obj, key, val, oldval)
    if (type(__newindex) ~= "function") then return end
    __newindex(obj, key, val, oldval);
end

local function NewScope(deep)
    nid = nid + 1;

    local o = {};
    local meta = {};            -- 元表
    local data = {};            -- 数据  任意存取
    local watchs = {};          -- 监控
    local scope = {};           -- 类
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

    -- 设置值
    -- scope.Set = function(self, key, val)
    --     self[key] = Scope.New(val);
    --     return self[key];
    -- end

    -- -- 获取值
    -- scope.Get = function(self, key)
    --     return self[key];
    -- end

    -- List Insert
    scope.insert = function(self, pos, val)
        table.insert(data, pos, val);
        __newindex_callback(self, nil, self, self);
    end

    scope.remove = function(self, pos)
        table.remove(data, pos)
        __newindex_callback(self, nil, self, self);
    end

    -- 监控变量
    scope.Watch = function(self, key, func)
        if (type(func) ~= "function") then return end
        watchs[key] = watchs[key] or {};
        table.insert(watchs[key], func);
    end

    -- 取消监控变量
    scope.UnWatch = function(self, key, func)
        if (type(func) ~= "function") then return end
        local watch = watchs[key];
        if (not watch) then return end
        for index, val in ipairs(watch) do
            if (val == func) then table.remove(watch, index) end
        end
    end
    
    -- 更新数据
    meta.__newindex = function(obj, key, val)
        -- __scope 类标识
        if (key == "__scope") then 
            echo("Error: scope object disable set key: " .. key);
            return 
        end

        -- 相同则直接返回
        if (data[key] == val) then return end

        -- 如果为表则构建新的scope
        if (type(val) == "table" and not val.__scope and __deep) then
            val = Scope.New(val);
        end

        -- 更新数据值
        local oldval = data[key];
        data[key] = val;

        -- 自定义全局回调
        if (type(__newindex) == "function") then __newindex(obj, key, val, oldval) end

        -- 监控函数回调
        if (watchs[key]) then
            for _, func in ipairs(watchs[key]) do
                func(val, oldval);
            end
        end

        -- 自定义局部回调
        if (type(data.__newindex) == "function") then
            data.__newindex(obj, key, val, oldval);
        end
    end

    -- 读取数据
    meta.__index = function(obj, key)
        -- 全局回调
        if (type(__index) == "function") then __index(obj, key) end

        -- 读取回调
        if (type(data.__index) == "function") then data.__index(obj, key) end

        -- 识别是否Scope 对象
        if (key == "__scope") then return true end

        -- 取更新表
        local val = data[key];
        if (val) then 
            if (IsScope(val)) then __index_callback(val, nil) end
            return val;
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
    deep = deep ~= false and true or false;
    obj = obj or {};
    if (type(obj) ~= "table") then return obj end

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

    __index_callback(scope, nil); -- 将自身加入依赖

    return scope;
end

function Scope.__SetIndex(index)
    __index = index;
end

function Scope.__SetNewIndex(newindex)
    __newindex = newindex;
end