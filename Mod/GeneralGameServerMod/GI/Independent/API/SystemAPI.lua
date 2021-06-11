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

setmetatable(SystemAPI, {__call = function(_, CodeEnv)
    CodeEnv.print = print;
    CodeEnv.ipairs = ipairs;
    CodeEnv.next = next;
    CodeEnv.pairs = pairs;
    CodeEnv.pcall = pcall;
    CodeEnv.tonumber = tonumber;
    CodeEnv.tostring = tostring;
    CodeEnv.type = type;
    CodeEnv.unpack = unpack;
    CodeEnv.error = error;
    CodeEnv.rawset = rawset;
    CodeEnv.rawget = rawget;
    CodeEnv.select = select;
    CodeEnv.pcall = pcall;
    CodeEnv.xpcall = xpcall;
    CodeEnv.setmetatable = setmetatable;
    CodeEnv.getmetatable = getmetatable;
    CodeEnv.format = string.format;
    CodeEnv.upper = string.upper;
    CodeEnv.lower = string.lower;

    -- lua class
    CodeEnv.coroutine = coroutine;
    CodeEnv.string = string;
    CodeEnv.table = table;
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

    local Independent = CodeEnv.Independent;

    CodeEnv.exit = function()
        Independent:Stop();
    end

    CodeEnv.require = function(name)
        if (CodeEnv.__modules__[name]) then return CodeEnv.__modules__[name] end
        CodeEnv.__modules__[name] = {}; -- 解决循环依赖
        -- 为单词则默认为系统库文件
        if (string.match(name, "^[%a%d]+$")) then 
            Independent:LoadFile(string.format("Mod/GeneralGameServerMod/GI/Independent/Lib/%s.lua", name));
        else -- 加载指令路径文件
            Independent:LoadFile(name);
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