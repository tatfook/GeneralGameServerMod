--[[
Title: Log
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local Log = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/Log.lua");
------------------------------------------------------------
]]

local Log = inherit(ToolBase, module("Log"));

local ToString = Debug.ToString;
local Print = Debug.Print;
local LocationInfo = Debug.LocationInfo;



local Level = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    FATAL = 4,
    LOG = 5,
}

local LevelText = {
    DEBUG = "DEBUG",
    INFO = "INFO",
    WARN = "WARN",
    FATAL = "FATAL",
    LOG = "LOG",
}

local DefaultDepth = 3;
local DefaultModuleName = "GI";
local DefaultLevelText = IsDevEnv and LevelText.DEBUG or LevelText.INFO;

local __global_log_level__ = DefaultLevelText;

Log.Level = LevelText;

Log:Property("Module", DefaultModuleName);
Log:Property("Depth", DefaultDepth);
Log:Property("LevelText", DefaultLevelText);

local function __log__(module, level, depth, ...)
    local dateStr, timeStr = GetLogTimeString();
    local filepos = LocationInfo(depth);

    filepos = string.sub(filepos, 1, 256);

    Print(string.format("\n[%s %s][%s][%s][%s BEGIN]", dateStr, timeStr, module, filepos, level));

    for i = 1, select('#', ...) do      -->获取参数总数
        local arg = select(i, ...);     -->函数会返回多个值
        Print(arg);                 -->打印参数
    end  

    Print(string.format("[%s %s][%s][%s][%s END]", dateStr, timeStr, module, filepos, level));
end

function Log:SetLevel(level)
    self:SetLevelText(LevelText[upper(level)] or LevelText.INFO);
end

function Log:Debug(...)
    if (Level[self:GetLevelText()] > Level[LevelText.DEBUG]) then return end
    
    return __log__(self:GetModule(), "DEBUG", self:GetDepth(), ...);
end

function Log:Info(...)
    if (Level[self:GetLevelText()] > Level[LevelText.INFO]) then return end
    
    return __log__(self:GetModule(), "INFO", self:GetDepth(), ...);
end

function Log:Warn(...)
    if (Level[self:GetLevelText()] > Level[LevelText.WARN]) then return end
    
    return __log__(self:GetModule(), "WARN", self:GetDepth(), ...);
end

function Log:Fatal(...)
    if (Level[self:GetLevelText()] > Level[LevelText.FATAL]) then return end
    
    return __log__(self:GetModule(), "FATAL", self:GetDepth(), ...);
end

function Log:Log(...)
    if (Level[self:GetLevelText()] > Level[LevelText.LOG]) then return end
    
    return __log__(self:GetModule(), "LOG", self:GetDepth(), ...);
end

function set_log_level(level)
    __global_log_level__ = LevelText[upper(level)] or LevelText.INFO;
end

function debug(...)
    if (Level[__global_log_level__] > Level[LevelText.DEBUG]) then return end

    return __log__(DefaultModuleName, "DEBUG", DefaultDepth, ...);
end

function info(...)
    if (Level[__global_log_level__] > Level[LevelText.INFO]) then return end
    
    return __log__(DefaultModuleName, "INFO", DefaultDepth, ...);
end

function warn(...)
    if (Level[__global_log_level__] > Level[LevelText.WARN]) then return end
    
    return __log__(DefaultModuleName, "WARN", DefaultDepth, ...);
end

function fatal(...)
    if (Level[__global_log_level__] > Level[LevelText.FATAL]) then return end
    
    return __log__(DefaultModuleName, "FATAL", DefaultDepth, ...);
end

function log(...)
    if (Level[__global_log_level__] > Level[LevelText.LOG]) then return end
    
    return __log__(DefaultModuleName, "LOG", DefaultDepth, ...);
end


