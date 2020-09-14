
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
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Config");
Config.IsDevEnv = ParaEngine.GetAppCommandLineByParam("IsDevEnv","false") == "true";
Config.IsTestEnv = ParaEngine.GetAppCommandLineByParam("IsTestEnv","false") == "true";
Config.ConfigFile = ParaEngine.GetAppCommandLineByParam("ConfigFile", nil);


function Config:SetEnv(env)
    if (env == "test") then
        self.IsTestEnv = true;
        self.serverIp = "ggs.keepwork.com";
        self.serverPort = "9001";
        GGS.INFO("切换到测试环境");
    elseif (env == "dev") then
        self.IsDevEnv = true;
        self.serverIp = "127.0.0.1";
        self.serverPort = "9000";
        GGS.INFO("切换到开发环境");
    else 
        self.IsDevEnv, self.IsTestEnv = false, false;
        self.serverIp = "ggs.keepwork.com";
        self.serverPort = "9000";
        GGS.INFO("切换到正式环境");
    end
end

-- 初始化
function Config:Init(isServer)
    if (self.inited) then return end;

    self.inited = true;
    GGS.INFO.Format("---------------------%s init config----------------", isServer and "server" or "client");

    self.IsServer = isServer;
    -- 客户端默认世界ID
    self.maxEntityId = 1000000;    -- 服务器统一分配的最大实体ID数
    self.defaultWorldId = 10373;   -- 新手岛世界ID
    self.isSyncBlock = false;      -- 默认不同步 Block 信息
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
        areaSize = 0,
        minClientCount = 50, 
        maxClientCount = 200,
    }
    self.ParaWorld = {
        areaSize = 128,
        areaMinClientCount = 50,
        areaMaxClientCount = 200,
        minClientCount = 200, 
        maxClientCount = 500,
    }
    self.ParaWorldMini = {
        areaSize = 128,
        areaMinClientCount = 0,
        areaMaxClientCount = 200,
        minClientCount = 0, 
        maxClientCount = 200,
    }
    self.Player = {
        minAliveTime = 60000,    -- 最小存活时间, 大于此值才可以进行离线缓存
        aliveDuration = 300000,  -- 玩家心跳时间 判断玩家是否存活
    }
    self.Debug = {
        Net = false,
        PlayerLoginLogoutDebug = true,
    }
    -- 服务端才需要配置文件, 加载配置
    if (isServer) then
        self:LoadConfig(self.ConfigFile);
    end 

    GGS.INFO(self);
end

-- 拷贝XML节点属性
local function CopyXmlAttr(dst, src)
    if (type(dst) ~= "table" or type(src) ~= "table") then return end

    for key, val in pairs(src) do 
        if (string.lower(val) == "true" or string.lower(val) == "false") then
            dst[key] = string.lower(val) == "true";
        elseif (string.match(val, "^%-?%d+$")) then
            dst[key] = tonumber(val) or dst[key];
        else
            dst[key] = val;
        end
    end
end

-- 加载配置文件
function Config:LoadConfig(filename)
    filename = filename or "config.xml"; -- 取当前目录下config.xml

    -- 加载配置文件
    local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
    local pathPrefix = self.IsDevEnv and "/GeneralGameServerDev" or (self.IsTestEnv and "/GeneralGameServerTest" or "/GeneralGameServer");
    if (not xmlRoot) then return GGS.Error.Format("failed loading paracraft server config file %s", filename) end

    -- 服务器配置
    local Server = commonlib.XPath.selectNode(xmlRoot, pathPrefix .. "/Server");
    CopyXmlAttr(self.Server, Server and Server.attr);

    -- 世界配置
    self.World = self.World or {};
    local World = commonlib.XPath.selectNode(xmlRoot, pathPrefix .. "/World");
    CopyXmlAttr(self.World, World and World.attr);

    -- 控制器服务配置
    local ControlServer = commonlib.XPath.selectNode(xmlRoot, pathPrefix .. "/Server/ControlServer");
    CopyXmlAttr(self.ControlServer, ControlServer and ControlServer.attr);

    -- 工作服务配置
    local WorkerServer = commonlib.XPath.selectNode(xmlRoot, pathPrefix .. "/Server/WorkerServer");
    CopyXmlAttr(self.WorkerServer, WorkerServer and WorkerServer.attr);

    -- 玩家配置
    local Player = commonlib.XPath.selectNode(xmlRoot, pathPrefix .. "/Player");
    CopyXmlAttr(self.Player, Player and Player.attr);

    -- Debug
    local Debug = commonlib.XPath.selectNode(xmlRoot, pathPrefix .. "/Debug");
    CopyXmlAttr(self.Debug, Debug and Debug.attr);
end
