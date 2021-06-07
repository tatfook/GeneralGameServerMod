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
NPL.load("(gl)script/Truck/Utility/UTF8String.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");

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
    CodeEnv.pcall = pcall;
    CodeEnv.xpcall = xpcall;
    CodeEnv.setmetatable = setmetatable;
    CodeEnv.getmetatable = getmetatable;
    CodeEnv.format = string.format;
    
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

    CodeEnv.module = function(name)
        CodeEnv.__modules__[name] = CodeEnv.__modules__[name] or {};
		return CodeEnv.__modules__[name];
    end

    CodeEnv.GetTime = ParaGlobal.timeGetTime;
    CodeEnv.ToolBase = commonlib.gettable("System.Core.ToolBase");
end});