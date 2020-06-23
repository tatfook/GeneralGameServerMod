
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
Config.IsTestEnv = ParaEngine.GetAppCommandLineByParam("IsTestEnv","false") == "true";
Config.ConfigFile = ParaEngine.GetAppCommandLineByParam("ConfigFile", nil);


-- 初始化
function Config:Init(isServer)
    if (self.inited) then return end;

    self.inited = true;
    
    Log:Info("---------------------%s init config----------------", isServer and "server" or "client");

    self.isServer = isServer;
    -- 客户端默认世界ID
    self.defaultWorldId = 12706;
    if (self.IsDevEnv) then 
        self.serverIp = "127.0.0.1";
        self.serverPort = "9000";
    else
        self.serverIp = "ggs.keepwork.com";
        self.serverPort = "9000";
    end

    -- 服务器配置
    self.maxWorldCount = 200;        -- 服务器最大世界数为200
    self.worldMaxClientCount = 100;  -- 每个世界限定100用户   
    self.maxClientCount = 8000;      -- 服务器最大连接数为8000

    -- 服务端才需要配置文件, 加载配置
    if (isServer) then
        self:LoadConfig(self.ConfigFile);
    end 

    -- 正式环境禁用网络包日志
    if (not self.IsDevEnv) then
        Log:SetModuleLogEnable("Mod.GeneralGameServerMod.Common.Connection", false);
        Log:SetModuleLogEnable("Mod.GeneralGameServerMod.Client.EntityMainPlayer", false);
    end
end


-- 加载配置文件
function Config:LoadConfig(filename)
    filename = filename or "config.xml"; -- 取当前目录下config.xml

    -- 加载配置文件
    local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
    local pathPrefix = self.IsDevEnv and "/GeneralGameServerDev" or (self.IsTestEnv and "/GeneralGameServerTest" or "/GeneralGameServer");
    if (not xmlRoot) then
		return Log:Error("failed loading paracraft server config file %s", filename);
    end

    -- 服务器配置
    self.Server = self.Server or {};
    local Server = commonlib.XPath.selectNodes(xmlRoot, pathPrefix .. "/Server")[1];
    local ServerAttr = Server and (Server.attr or {});
    commonlib.partialcopy(self.Server, ServerAttr);
    self.ip = ServerAttr.ip or self.ip;
    self.port = ServerAttr.port or self.port;
    self.Server.maxClientCount = tonumber(ServerAttr.maxClientCount) or self.maxClientCount;
    self.Server.maxWorldCount = tonumber(ServerAttr.maxWorldCount) or self.maxWorldCount;
    self.Server.isControlServer = ServerAttr.isControlServer == "true" and true or false;
    self.Server.isWorkerServer = ServerAttr.isWorkerServer == "true" and true or false;

    -- 日志配置
    self.Log = self.Log or {};
    local LogCfg = commonlib.XPath.selectNodes(xmlRoot, pathPrefix .. "/Log")[1];
    local LogAttr = LogCfg and (LogCfg.attr or {});
    commonlib.partialcopy(self.Log, LogAttr);

    local LogModules = commonlib.XPath.selectNodes(xmlRoot, pathPrefix .. "/Log/Module");
    for i, module in ipairs(LogModules) do 
        Log:SetModuleLogEnable(module.name, module.attr.enable == "true" and true or false);
    end

    -- 世界配置
    self.World = self.World or {};
    local World = commonlib.XPath.selectNodes(xmlRoot, pathPrefix .. "/World")[1];
    local WorldAttr = World and (World.attr or {});
    commonlib.partialcopy(self.World, WorldAttr);
    self.World.maxClientCount = tonumber(WorldAttr.maxClientCount) or self.worldMaxClientCount;
    -- Log:Info(self);

    -- 控制器服务配置
    self.ControlServer = self.ControlServer or {};
    local ControlServer = commonlib.XPath.selectNodes(xmlRoot, pathPrefix .. "/Server/ControlServer")[1];
    local ControlServerAttr = ControlServer and (ControlServer.attr or {});
    commonlib.partialcopy(self.ControlServer, ControlServerAttr);

    -- 工作服务配置
    self.WorkerServer = self.WorkerServer or {};
    local WorkerServer = commonlib.XPath.selectNodes(xmlRoot, pathPrefix .. "/Server/WorkerServer")[1];
    local WorkerServerAttr = WorkerServer and (WorkerServer.attr or {});
    commonlib.partialcopy(self.WorkerServer, WorkerServerAttr);
end
