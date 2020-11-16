
--[[
Title: Config
Author(s): wxa
Date: 2020/6/19
Desc: mod config
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/Config.lua");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Config");
-------------------------------------------------------
]]
local GGS = NPL.load("Mod/GeneralGameServerMod/Core/Common/GGS.lua");

local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Config");

Config.ConfigFile = ParaEngine.GetAppCommandLineByParam("ConfigFile", "config.xml");

local inited = false;

-- 初始化
function Config:StaticInit()
    if (inited) then return end
    inited = true;

    -- 服务配置
    self.Server = {
        threadCount = 3,
        threadMaxClientCount = 500,
        listenIp="0.0.0.0", 
        isControlServer=true,
        isWorkerServer=true,
        maxClientCount=8000,
        maxWorldCount=200,
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
        NetDebug = false,
        PlayerLoginLogoutDebug = true,
    }
    self.DataHandler = {
        filename = "Mod/GeneralGameServerMod/Core/Server/ServerDataHandler.lua",
    }
    self.PublicFiles = {};
    self.IsDevEnv = IsDevEnv;
    
    -- 服务端才需要配置文件, 加载配置
    self:LoadConfig(self.ConfigFile);

    -- GGS.INFO(self);
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
    -- 加载配置文件
    local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
    local pathPrefix = GGS.IsDevEnv and "/GeneralGameServerDev" or (GGS.IsTestEnv and "/GeneralGameServerTest" or "/GeneralGameServer");
    if (not xmlRoot) then return GGS.ERROR.Format("failed loading paracraft server config file %s", filename) end

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

    -- 玩家配置
    local DataHandler = commonlib.XPath.selectNode(xmlRoot, pathPrefix .. "/DataHandler");
    CopyXmlAttr(self.DataHandler, DataHandler and DataHandler.attr);

    -- Debug
    local Debug = commonlib.XPath.selectNode(xmlRoot, pathPrefix .. "/Debug");
    CopyXmlAttr(self.Debug, Debug and Debug.attr);
    for key, val in pairs(self.Debug) do
        if (val) then
            GGS.Debug.EnableModule(key);
        else
            GGS.Debug.DisableModule(key);
        end
    end

    -- public file
    local PublicFileNodes = commonlib.XPath.selectNodes(xmlRoot, pathPrefix .. "/PublicFile") or {};
    for _, node in ipairs(PublicFileNodes) do
        local filename = node.attr and node.attr.filename;
        if (filename) then table.insert(self.PublicFiles, #(self.PublicFiles) + 1, filename) end
    end
    
end

-- 加载配置
Config:StaticInit();