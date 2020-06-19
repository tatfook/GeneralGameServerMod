
--[[
Title: Config
Author(s): wxa
Date: 2020/6/19
Desc: mod config
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Common/Config.lua");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Common.Config");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Common.Config");
Config.IsDevEnv = ParaEngine.GetAppCommandLineByParam("IsDevEnv","false") == "true";
Config.ConfigFile = ParaEngine.GetAppCommandLineByParam("ConfigFile", nil);


-- 初始化
function Config:Init(isServer)
    if (self.inited) then return end;

    self.inited = true;
    
    Log:Info("---------------------%s init config----------------", isServer and "server" or "client");

    self.isServer = isServer;
    -- 客户端默认世界ID
    self.defaultWorldId = 12706;
    -- ip, port 设置
    if (isServer) then
        -- 服务端监听Ip和Port
        self.ip = "0.0.0.0";
        self.port = 9000;
    else
        -- 客户端连接的Ip和Port
        if (self.IsDevEnv) then
            self.ip = "127.0.0.1";
            self.port = 9000;
        else 
            self.ip = "120.132.120.175";
            self.port = 9000;
        end    
    end

    -- 服务器配置
    self.maxWorldCount = 200;        -- 服务器最大世界数为200
    self.maxWorldClientCount = 100;  -- 每个世界限定100用户   
    self.maxClientCount = 8000;      -- 服务器最大连接数为8000

    -- 服务端才需要配置文件, 加载配置
    if (isServer) then
        self:LoadConfig(self.ConfigFile);
    end 

    self.log = self.log or {};
    
    -- 正式环境禁用网络包日志
    if (not IsDevEnv) then
        Log:SetModuleLogEnable("Mod.GeneralGameServerMod.Common.Connection", false);
        Log:SetModuleLogEnable("Mod.GeneralGameServerMod.Client.EntityMainPlayer", false);
    end
end


-- 加载配置文件
function Config:LoadConfig(filename)
    filename = filename or "config.xml"; -- 取当前目录下config.xml

    -- 加载配置文件
    local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
    if (not xmlRoot) then
		return Log:Error("failed loading paracraft server config file %s", filename);
    end

    local ServerCfg = commonlib.XPath.selectNodes(xmlRoot, "/GeneralGameServer/Server")[1];
    if (ServerCfg and ServerCfg.attr) then 
        commonlib.partialcopy(self, ServerCfg.attr);
    end

    local LogCfg = commonlib.XPath.selectNodes(xmlRoot, "/GeneralGameServer/Log")[1];
    if (LogCfg and LogCfg.attr) then
        commonlib.partialcopy(self, LogCfg.attr);
    end

    local LogModulesCfg = commonlib.XPath.selectNodes(xmlRoot, "/GeneralGameServer/Log/Module");
    for i, module in ipairs(LogModulesCfg) do 
        Log:SetModuleLogEnable(module.name, module.enable == "true" and true or false);
    end

    local LimitCfg = commonlib.XPath.selectNodes(xmlRoot, "/GeneralGameServer/Limit")[1];
    if (LimitCfg) then
        for key, val in pairs(LimitCfg.attr) do
            self[key] = tonumber(val) or self[key];
        end
    end

    -- Log:Info(self);
end
