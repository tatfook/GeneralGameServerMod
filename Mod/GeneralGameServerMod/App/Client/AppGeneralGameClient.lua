--[[
Title: AppGeneralGameClient
Author(s): wxa
Date: 2020/7/9
Desc: 客户端入口文件
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameClient.lua");
local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");
-------------------------------------------------------
]]
NPL.load("Mod/GeneralGameServerMod/Core/Client/GeneralGameClient.lua");
NPL.load("Mod/GeneralGameServerMod/App/Client/AppEntityMainPlayer.lua");
NPL.load("Mod/GeneralGameServerMod/App/Client/AppEntityOtherPlayer.lua");
local AppEntityOtherPlayer = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppEntityOtherPlayer");
local AppEntityMainPlayer = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppEntityMainPlayer");
local AppGeneralGameClient = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameClient"), commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient"));

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local moduleName = "Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient";

-- 构造函数
function AppGeneralGameClient:ctor()
end

-- 获取世界类
function AppGeneralGameClient:GetGeneralGameWorldClass()
    return AppGeneralGameClient._super.GetGeneralGameWorldClass(self);  -- 不定制
end
-- 获取网络处理类
function AppGeneralGameClient:GetNetClientHandlerClass()
    return AppGeneralGameClient._super.GetNetClientHandlerClass(self);  -- 不定制
end
-- 获取主玩家类
function AppGeneralGameClient:GetEntityMainPlayerClass()
    return AppEntityMainPlayer;
end
-- 获取其它玩家类
function AppGeneralGameClient:GetEntityOtherPlayerClass()
    return AppEntityOtherPlayer;
end

-- 获取当前认证用户信息
-- 此函函数返回用户信息会在各玩家间同步, 所以尽量精简
function AppGeneralGameClient:GetUserInfo()
    local userinfo = KeepWorkItemManager.GetProfile();
    local usertag = KeepWorkItemManager.GetUserTag(userinfo);
    return {
        username = userinfo.username,
        nickname = userinfo.nickname,
        isVip = usertag == "VT" or usertag == "V",
    }
end

-- 是否是匿名用户
function AppGeneralGameClient:IsAnonymousUser()
    -- if (self:GetConfig().IsDevEnv) then return false end
    
    return self:GetOptions().username ~= System.User.keepworkUsername;  -- 匿名用户不支持离线缓存
end

-- 初始化成单列模式
AppGeneralGameClient:InitSingleton();