--[[
Title: SystemAPI
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local SystemAPI = NPL.load("Mod/GeneralGameServerMod/GI/Independent/API/SystemAPI.lua");
------------------------------------------------------------
]]

local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local vector3d = commonlib.gettable("mathlib.vector3d");
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");

local SystemAPI = NPL.export();

local Table = {concat = table.concat};
-- 自定排序
local function sort(list, comp)
	comp = comp or function(n1, n2) return n1 > n2 end

	for i = 1, #list do
        for j = i + 1, #list do 
            if (comp(list[i], list[j])) then
                list[i], list[j] = list[j], list[i];
            end
        end
    end
end
local function IsScope(t)
    return type(t) == "table" and t.__scope__;
end
function Table.insert(t, i, v)
    if (IsScope(t)) then
        t:Insert(i, v);
    else
        if (v == nil) then i, v = #t + 1, i end
        table.insert(t, i, v);
    end
end
function Table.remove(t, i)
    if (IsScope(t)) then
        t:Remove(i);
    else
        table.remove(t, i);
    end
end
function Table.sort(t, comp)
    if (IsScope(t)) then
        t:Sort(comp, sort);
    else
        sort(t, comp);
    end
end
local function Pairs(t)
    if (IsScope(t)) then
        return t:Pairs();
    else
        return pairs(t);
    end
end
local function IPairs(t)
    if (IsScope(t)) then
        return t:IPairs();
    else
        return ipairs(t);
    end
end

setmetatable(SystemAPI, {__call = function(_, CodeEnv)
    CodeEnv.print = print;
    CodeEnv.next = next;
    CodeEnv.pairs = Pairs;
    CodeEnv.ipairs = IPairs;
    CodeEnv.pcall = pcall;
    CodeEnv.tonumber = tonumber;
    CodeEnv.tostring = tostring;
    CodeEnv.type = type;
    -- CodeEnv.unpack = unpack;
    CodeEnv.error = error;
    CodeEnv.rawset = rawset;
    CodeEnv.rawget = rawget;
    -- CodeEnv.select = select;
    CodeEnv.loadstring = loadstring;
    CodeEnv.setfenv = setfenv;
    CodeEnv.pcall = pcall;
    CodeEnv.xpcall = xpcall;
    CodeEnv.setmetatable = setmetatable;
    CodeEnv.getmetatable = getmetatable;
    CodeEnv.format = string.format;
    CodeEnv.upper = string.upper;
    CodeEnv.lower = string.lower;

    -- lua class
    -- CodeEnv.coroutine = coroutine;
    CodeEnv.string = string;
    CodeEnv.table = Table;
    CodeEnv.sort = sort;
    CodeEnv.math = math;
    CodeEnv.os = os;
    
    CodeEnv.vector3d = vector3d;
    CodeEnv.utf8string = UTF8String;
    CodeEnv.utf8char = UTF8Char;
    
    CodeEnv.echo = echo;
    CodeEnv.serialize = commonlib.serialize
    CodeEnv.unserialize = commonlib.LoadTableFromString;
    CodeEnv.inherit = commonlib.inherit;
    CodeEnv.getfield = function(key) return commonlib.getfield(key, CodeEnv) end 
    CodeEnv.setfield = function(key, val) return commonlib.setfield(key, val, CodeEnv) end 
    CodeEnv.gettable = function(key) return commonlib.gettable(key, CodeEnv) end 
    CodeEnv.settable = function(key, val) return commonlib.settable(key, val, CodeEnv) end 
    CodeEnv.deepcopy = commonlib.deepcopy
    CodeEnv.copy = commonlib.copy
    CodeEnv.partialcopy = commonlib.partialcopy
    CodeEnv.mincopy = commonlib.mincopy

	CodeEnv.cmd = function(...) CommandManager:RunCommand(...) end
    CodeEnv.exit = CodeEnv.__stop__;

    CodeEnv.__get_url__ = function(config, callback) 
        System.os.GetUrl(config, function(...)
            CodeEnv.__call__(callback, ...);
        end);
    end

    -- 会切换协程需做等待处理
    local __modules__ = {};
    CodeEnv.require = function(name)
        local filename = (string.match(name, "^[%a%d]+$")) and (string.format("Mod/GeneralGameServerMod/GI/Independent/Lib/%s.lua", name)) or name;
        if (__modules__[filename]) then return __modules__[filename] end
        __modules__[filename] = CodeEnv.__loadfile__(filename);
        return __modules__[filename];
    end

    CodeEnv.module = function(name, module)
        module = module or {};
        CodeEnv.__module__.__module__ = module;
        CodeEnv.__module__.__name__ = name;
        return module;
    end

    CodeEnv.GetTime = ParaGlobal.timeGetTime;
    CodeEnv.GetTimeStamp = ParaGlobal.timeGetTime;
    CodeEnv.ToolBase = commonlib.gettable("System.Core.ToolBase");
end});