
--[[
Title: API
Author(s):  wxa
Date: 2021-06-30
Desc: API
use the lib:
------------------------------------------------------------
local API = NPL.load("Mod/GeneralGameServerMod/Server/SandBox/API/API.lua");
------------------------------------------------------------
]]

local API = NPL.export();

setmetatable(API, {__call = function(_, __env__)
    __env__.print = print;
    __env__.next = next;
    __env__.pairs = pairs;
    __env__.ipairs = ipairs;
    __env__.pcall = pcall;
    __env__.tonumber = tonumber;
    __env__.tostring = tostring;
    __env__.type = type;
    __env__.unpack = unpack;
    __env__.error = error;
    __env__.rawset = rawset;
    __env__.rawget = rawget;
    __env__.select = select;
    __env__.pcall = pcall;
    __env__.xpcall = xpcall;
    __env__.setmetatable = setmetatable;
    __env__.getmetatable = getmetatable;
    __env__.format = string.format;
    __env__.upper = string.upper;
    __env__.lower = string.lower;

    __env__.coroutine = coroutine;
    __env__.string = string;
    __env__.table = table;
    __env__.math = math;
    __env__.os = os;
    
    __env__.echo = echo;
    __env__.serialize = commonlib.serialize
    __env__.unserialize = commonlib.LoadTableFromString;
    __env__.inherit = commonlib.inherit;

    __env__.getfield = function(key) return commonlib.getfield(key, __env__) end 
    __env__.setfield = function(key, val) return commonlib.setfield(key, val, __env__) end 
    __env__.gettable = function(key) return commonlib.gettable(key, __env__) end 
    __env__.settable = function(key, val) return commonlib.settable(key, val, __env__) end 

    __env__.deepcopy = commonlib.deepcopy;
    __env__.copy = commonlib.copy;
    __env__.partialcopy = commonlib.partialcopy;
    __env__.mincopy = commonlib.mincopy;

    -- 会切换协程需做等待处理
    local __modules__ = __env__.__modules__;
    __env__.require = function(name)
        if (__modules__[name]) then return __modules__[name] end 
        __modules__[name] = {}; -- 解决循环依赖
        
        -- 为单词则默认为系统库文件
        if (string.match(name, "^[%a%d]+$")) then 
            __env__.__loadfile__(string.format("Mod/GeneralGameServerMod/Server/SandBox/Lib/%s.lua", name));
        else -- 加载指令路径文件
            __env__.__loadfile__(name);
        end
        
        return __modules__[name];
    end

    __env__.module = function(name, module)
        __modules__[name] = __modules__[name] or module or {};
        return __modules__[name];
    end

    __env__.GetTimeStamp = ParaGlobal.timeGetTime;
    __env__.ToolBase = commonlib.gettable("System.Core.ToolBase");
end});
