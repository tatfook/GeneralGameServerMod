
--[[
Title: Config
Author(s): wxa
Date: 2020/6/19
Desc: mod config
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Config.lua");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Config");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Config");
Config.IsDevEnv = ParaEngine.GetAppCommandLineByParam("IsDevEnv","false") == "true";
Config.IsTestEnv = ParaEngine.GetAppCommandLineByParam("IsTestEnv","false") == "true";
Config.ConfigFile = ParaEngine.GetAppCommandLineByParam("ConfigFile", nil);


function Config:SetEnv(env)
    if (env == "test") then
        self.IsTestEnv = true;
        self.serverIp = "ggs.keepwork.com";
        self.serverPort = "9001";
        Log:Info("切换到测试环境");
    elseif (env == "dev") then
        self.IsDevEnv = true;
        self.serverIp = "127.0.0.1";
        self.serverPort = "9000";
        Log:Info("切换到开发环境");
    else 
        self.IsDevEnv, self.IsTestEnv = false, false;
        self.serverIp = "ggs.keepwork.com";
        self.serverPort = "9000";
        Log:Info("切换到正式环境");
    end
end

-- 初始化
function Config:Init(isServer)
    if (self.inited) then return end;

    self.inited = true;
    Log:Info("---------------------%s init config----------------", isServer and "server" or "client");

    self.isServer = isServer;
    -- 客户端默认世界ID
    self.maxEntityId = 100000;    -- 服务器统一分配的最大实体ID数
    self.defaultWorldId = 10373;  -- 新手岛世界ID
    self.isSyncBlock = false;     -- 默认不同步 Block 信息
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

    -- 服务配置
    self.Server = {
        listenIp="0.0.0.0", 
        listenPort="9000",
        isControlServer=true,
        isWorkerServer=true,
        maxClientCount=8000,
        maxWorldCount=200,
        innerIp="10.28.18.2",
        innerPort="9000",
        outerIp="120.132.120.175",
        outerPort="9000",
    }
    self.ControlServer = {
        innerIp="10.28.18.2",
        innerPort="9000",
        outerIp="120.132.120.175",
        outerPort="9000",
    }
    self.WorkerServer = {
        innerIp="10.28.18.2",
        innerPort="9000",
        outerIp="120.132.120.175",
        outerPort="9000",
    }
    self.World = {
        minClientCount=50, 
        maxClientCount=200,
    }
    self.Player = {
        minAliveTime = 60000,
    }
    self.Log = {
        level = "INFO",
    }
    -- 服务端才需要配置文件, 加载配置
    if (isServer) then
        self:LoadConfig(self.ConfigFile);
    end 

    Log:Info(self);
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
    self.World.minClientCount = tonumber(WorldAttr.minClientCount) or 50;
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

    -- 玩家配置
    self.Player = self.Player or {};
    -- 最小存活时间
    local MinAliveTime = commonlib.XPath.selectNodes(xmlRoot, pathPrefix .. "/Player/MinAliveTime")[1];
    self.Player.minAliveTime = tonumber(MinAliveTime and MinAliveTime[1] or 120000);
    self.Player.aliveDuration = 3 * 60 * 1000; -- 心跳间隔
end
