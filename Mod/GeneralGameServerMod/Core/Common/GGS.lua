--[[
Title: GGS
Author(s): wxa
Date: 2020/6/19
Desc: GGS 全局对象
use the lib:
-------------------------------------------------------
local GGS = NPL.load("Mod/GeneralGameServerMod/Core/Common/GGS.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/System.lua");
local Debug = NPL.load("Mod/GeneralGameServerMod/Core/Common/Debug.lua");

local GGS = NPL.export();

local GeneralGameClients = {};
local IsDevEnv = ParaEngine.GetAppCommandLineByParam("IsDevEnv","false") == "true";
local IsServer = ParaEngine.GetAppCommandLineByParam("servermode","false") == "true";
local Env = ParaEngine.GetAppCommandLineByParam("env", "online");  -- online release stage local

_G.IsDevEnv = true and IsDevEnv;
_G.IsServer = IsServer;
_G.IsClient = not IsServer;
_G.Env = Env;

-- ENV
GGS.IsDevEnv = IsDevEnv or Env == "local";
GGS.IsTestEnv = Env == "release";
GGS.IsProdEnv = Env == "online";
GGS.IsServer = IsServer;

	
-- DEBUG 调试类以及调试函数
GGS.Debug = Debug;
GGS.DEBUG = Debug.GetModuleDebug("DEBUG");
GGS.INFO = Debug.GetModuleDebug("INFO");
GGS.WARN = Debug.GetModuleDebug("WARN");
GGS.ERROR= Debug.GetModuleDebug("ERROR");
GGS.FATAL= Debug.GetModuleDebug("FATAL");

if (not IsDevEnv) then GGS.DEBUG.Disable() end

-- 业务逻辑DEBUG
GGS.PlayerLoginLogoutDebug = Debug.GetModuleDebug("PlayerLoginLogoutDebug");   -- 玩家登录登出日志
GGS.NetDebug = Debug.GetModuleDebug("NetDebug");                               -- 发送接收数据包日志
GGS.BlockSyncDebug = Debug.GetModuleDebug("BlockSyncDebug");                   -- 方块同步日志
GGS.AreaSyncDebug = Debug.GetModuleDebug("AreaSyncDebug");                     -- 区域同步日志

-- Util
GGS.ToString = Debug.ToString;

-- 配置
GGS.MaxEntityId =  1000000;                                                    -- 服务器统一分配的最大实体ID数
GGS.WorkerThreadName = "WorkerThread";                                         -- 工作线程名
function GGS.GetWorkerThreadName(no)
    return GGS.WorkerThreadName .. tostring(no);
end

-- 注册主客户端类
function GGS.RegisterClientClass(appName, clientClass)
    GeneralGameClients[appName] = clientClass;
end

function GGS.GetClientClass(appName)
    return GeneralGameClients[appName];
end

_G.GGS = GGS;

local PublicFileID = 1000;
_G.AddPublicFile = function(filepath, nid)
    if (not nid) then
        PublicFileID = PublicFileID + 1;
        nid = PublicFileID;
    end
    NPL.AddPublicFile(filepath, nid);
end

