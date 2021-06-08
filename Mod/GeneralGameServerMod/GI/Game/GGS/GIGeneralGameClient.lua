--[[
Title: GIGeneralGameClient
Author(s): wxa
Date: 2020/7/9
Desc: 客户端入口文件
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/GI/Game/GGS/GIGeneralGameClient.lua");
-------------------------------------------------------
]]
NPL.load("Mod/GeneralGameServerMod/Core/Client/GeneralGameClient.lua");
local GIEntityMainPlayer = NPL.load("./GIEntityMainPlayer.lua", IsDevEnv);
local GIEntityOtherPlayer = NPL.load("./GIEntityOtherPlayer.lua", IsDevEnv);
local GIClientDataHandler = NPL.load("./GIClientDataHandler.lua", IsDevEnv);
local GIGeneralGameClient = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameClient"), NPL.export());

-- 获取世界类
function GIGeneralGameClient:GetGeneralGameWorldClass()
    return GIGeneralGameClient._super.GetGeneralGameWorldClass(self);  -- 使用默认类
end
-- 获取网络处理类
function GIGeneralGameClient:GetNetClientHandlerClass()
    return GIGeneralGameClient._super.GetNetClientHandlerClass(self);  -- 使用默认类
end
-- 获取主玩家类
function GIGeneralGameClient:GetEntityMainPlayerClass()
    return GIEntityMainPlayer;
end
-- 获取其它玩家类
function GIGeneralGameClient:GetEntityOtherPlayerClass()
    return GIEntityOtherPlayer;
end
-- 获取网络数据处理类
function GIGeneralGameClient:GetClientDataHandlerClass()
    return GIClientDataHandler;
end

local Nid = 0;
-- 加载世界 
function GIGeneralGameClient:LoadWorld(opts)
    Nid = Nid + 1;

    opts = opts or {};
    opts.worldId = opts.worldId or GameLogic.options:GetProjectId() or "GGS";
    opts.worldName = opts.worldName or string.format("WorldName_%s", Nid);
    opts.worldKey = opts.worldKey or string.format("WorldKey_%s", Nid);
    return GIGeneralGameClient._super.LoadWorld(self, opts);
end

-- 初始化成单列模式
GIGeneralGameClient:InitSingleton();