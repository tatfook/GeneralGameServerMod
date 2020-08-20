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

-- local Scope = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
-- local Scope = NPL.export();
local Scope = {};
local nid = 0;

function Scope:New()
    nid = nid + 1;
    
    local o = {}
    local meta = {};            -- 元表
    local data = {};            -- 数据  任意存取
    local scope = Scope:new();  -- 类
    local __nid = nid;          -- ID
    local __metatable = nil     -- 元表
    
    -- 设置元表
    scope.SetMetaTable = function(self, metatable)
        __metatable = metatable;
    end

    -- 获取元表
    scope.GetMetaTable = function()
        return __metatable;
    end

    -- 更新数据
    meta.__newindex = function(obj, key, val)
        print("set", __nid, key, val);

        data[key] = val;
    end

    -- 读取数据
    meta.__index = function(obj, key)
        -- 取更新表
        if (data[key]) then 
            print("get", __nid, key);
            return data[key];
         end
        
        -- 获取只读ID
        if (key == "__nid") then return __nid end

        -- 取类数据
        if (scope[key]) then return scope[key] end

        -- 取元表
        return __metatable and __metatable[key];
    end
    
    setmetatable(o, meta);
    return o;
end

function Scope:new(o)
    o = o or {};
    setmetatable(o, {__index = Scope});
    return o;
end

-- 获取ID
local s = Scope:New();
s.key = 1;
s.__index = nil;
print(s.key, s.val);

-- 元表测试
-- local s1 = Scope:new();
-- local s2 = Scope:new();
-- s1.s1 = 1;
-- s2.s2 = 2;

-- s2:SetMetaTable(s1);
-- print(s2.s1, s2.s2);
-- s2.s1 = 3;
-- print(s2.s1, s2.s2);
-- print(s2:GetMetaTable() == s1)
