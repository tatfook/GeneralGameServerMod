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
        t:Sort(comp);
    else
        table.sort(t, comp);
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

    CodeEnv.require = function(name)
        if (CodeEnv.__modules__[name]) then return CodeEnv.__modules__[name] end
        CodeEnv.__modules__[name] = {}; -- 解决循环依赖
        -- 为单词则默认为系统库文件
        if (string.match(name, "^[%a%d]+$")) then 
            CodeEnv.__loadfile__(string.format("Mod/GeneralGameServerMod/GI/Independent/Lib/%s.lua", name));
        else -- 加载指令路径文件
            CodeEnv.__loadfile__(name);
        end
        return CodeEnv.__modules__[name];
    end

    CodeEnv.module = function(name, module)
        CodeEnv.__modules__[name] = CodeEnv.__modules__[name] or module or {};
		return CodeEnv.__modules__[name];
    end

    CodeEnv.GetTime = ParaGlobal.timeGetTime;
    CodeEnv.ToolBase = commonlib.gettable("System.Core.ToolBase");
end});