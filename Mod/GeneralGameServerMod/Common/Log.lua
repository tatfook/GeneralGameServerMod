
--[[
Title: Config
Author(s): wxa
Date: 2020/6/19
Desc: log file, 添加模块日志使能效果
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
-------------------------------------------------------
]]

local log = commonlib.logging.GetLogger("GeneralGameServerMod");
local Log = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Common.Log"));

function Log:ctor()
    self.moduleLogEnableMap = {};   -- 实例属性
end

function Log:Init(level, defaultModuleName)
    self:SetDefaultModuleName(defaultModuleName);
    self:SetLevel(level or "INFO");
    return self;
end

-- 单列模式
local g_instance;
function Log.GetSingleton()
	if(g_instance) then
		return g_instance;
	else
		g_instance = Log:new():Init(nil, nil);
		return g_instance;
	end
end

local function GetSelf(self)
    -- self 为 nil, Log 或不是 Log 实例时使用默认实例
    if (not self or self == Log or not self:isa(Log)) then
        return Log.GetSingleton();
    end

    return self;
end

function Log:SetDefaultModuleName(defaultModuleName)
    self = GetSelf(self);
    self.defaultModuleName = defaultModuleName or "ModuleLog";
end

function Log:GetDefaultModuleName()
    self = GetSelf(self);
    return self.defaultModuleName
end


function Log:SetModuleLogEnable(moduleName, enable)
    self = GetSelf(self);
    self.moduleLogEnableMap[moduleName] = enable;
end

function Log:GetModuleLogEnable(moduleName)
    self = GetSelf(self);
    if (self.moduleLogEnableMap[module_name] == false) then 
        return false;
    else
        return true;                            -- 默认开启 
    end
end

-- Cls.Func(self) 显示申明self  Cls:Func() 隐式申明self   无论哪种方式定义 使用均为 Inst:Func()

function Log:SetLevel(level)
    self = GetSelf(self);
    if(level) then
		level = string.lower(level);
		if(level~=log.level) then
			log.level = level;
			log.std(nil, "info", "Log", "log level is set to %s", log.level);
		end
	end
end

function StdLog(self, depth, threadOrWord, level, moduleName, input, ...)
    self = GetSelf(self);

    -- 没有模块名 文件名做模块名
    if (not moduleName) then
        if (IsDevEnv) then
            moduleName = commonlib.debug.locationinfo(depth or 3);  -- 调用深度 默认为3
        else
            moduleName = self:GetDefaultModuleName();
        end
    end
    
    -- 模块存在且未使能
    if (moduleName and not self:GetModuleLogEnable(moduleName)) then
        return ;
    end

    -- 日志输出
    log.std(threadOrWord, level, moduleName, input, ...);
end

-- 当需要明确指定模块名时使用此函数输出日志
function Log:Std(level, moduleName, ...)
    StdLog(self, nil, nil, level, moduleName, ...);
end

function Log:Debug(...)
    StdLog(self, nil, nil, "DEBUG", nil, ...);
end

function Log:Info(...)
    StdLog(self, nil, nil, "INFO", nil, ...);
end

function Log:Warn(...)
    StdLog(self, nil, nil, "WARN", nil, ...);
end

function Log:Error(...)
    StdLog(self, nil, nil, "ERROR", nil, ...);
end

function Log:Fatal(...)
    StdLog(self, nil, nil, "FATAL", nil, ...);
end
