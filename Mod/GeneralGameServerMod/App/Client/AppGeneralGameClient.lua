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
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/GeneralGameClient.lua");
NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameWorld.lua");
NPL.load("Mod/GeneralGameServerMod/App/Client/AppEntityMainPlayer.lua");
NPL.load("Mod/GeneralGameServerMod/App/Client/AppEntityOtherPlayer.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
local Encoding = commonlib.gettable("System.Encoding");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local AppGeneralGameWorld = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameWorld");
local AppEntityOtherPlayer = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppEntityOtherPlayer");
local AppEntityMainPlayer = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppEntityMainPlayer");
local AppGeneralGameClient = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameClient"), commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient"));

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local KpUserTag = NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/KpUserTag.lua");
local moduleName = "Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient";

-- 构造函数
function AppGeneralGameClient:ctor()
    self.userinfo = {
        username = System.User.keepworkUsername,
    }; -- 认证用户信息

    -- 业务初始化
    GameLogic.GetFilters():remove_filter("OnKeepWorkLogin", AppGeneralGameClient.OnKeepWorkLogin_Callback);
    GameLogic.GetFilters():remove_filter("OnKeepWorkLogout", AppGeneralGameClient.OnKeepWorkLogout_Callback);
    GameLogic.GetFilters():add_filter("OnKeepWorkLogin", AppGeneralGameClient.OnKeepWorkLogin_Callback);
    GameLogic.GetFilters():add_filter("OnKeepWorkLogout", AppGeneralGameClient.OnKeepWorkLogout_Callback);

    KeepWorkItemManager.StaticInit();
    KeepWorkItemManager.GetFilter():add_filter("loaded_all", AppGeneralGameClient.OnKeepworkLoginLoadedAll_Callback);

    GameLogic.GetFilters():add_filter("ggs", function(msg)
        if (type(msg) == "table" and msg.action == "UpdateNickName") then
            self.userinfo.nickname = msg.nickname;
        end
        return msg;
    end);
end

-- 初始化函数
function AppGeneralGameClient:Init()
    if (self.inited) then return end

    -- 基类初始化
    AppGeneralGameClient._super.Init(self);

    -- 配置GGS的默认选项值
    -- self:GetOptions().isSyncBlock = true;
    -- self:GetOptions().serverIp = "127.0.0.1";
    -- self:GetOptions().serverPort = "9000";

    self.inited = true;
end

-- 加载世界
function AppGeneralGameClient:LoadWorld(opts)
    AppGeneralGameClient._super.LoadWorld(self, opts);

    local options = self:GetOptions();
    self.userinfo.school = options.school or self.userinfo.school;
    self.userinfo.isVip = options.isVip or self.userinfo.isVip;
    self.userinfo.nickname = options.nickname or self.userinfo.nickname;
end

-- 获取世界类
function AppGeneralGameClient:GetGeneralGameWorldClass()
    return AppGeneralGameWorld;  
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

function AppGeneralGameClient.OnKeepworkLoginLoadedAll_Callback()
    local self = AppGeneralGameClient;
    local userinfo = KeepWorkItemManager.GetProfile();

    self.userinfo.id = userinfo.id;
    self.userinfo.username = userinfo.username;
    self.userinfo.nickname = userinfo.nickname;
    self.userinfo.isVip = userinfo.vip == 1;
    self.userinfo.usertag = KpUserTag.GetMcml(userinfo);
    self.userinfo.worldCount = 0;
    -- 拉取学校
    keepwork.user.school(nil, function(statusCode, msg, data) 
        if (not data) then return end
        self.userinfo.school = data.name;
    end)
    -- 拉取作品数
    local id = "kp" .. Encoding.base64(commonlib.Json.Encode({username=userinfo.username}));
    keepwork.user.getinfo({router_params = {id = id}}, function(statusCode, msg, data) 
        if (statusCode ~= 200 or not data) then return end
        self.userinfo.worldCount = data.rank.world or 0;
    end)

    -- 发送用户通知
    GameLogic.GetFilters():apply_filters("ggs", {action = "UpdateUserInfo", userinfo = self.userinfo});
end
-- 用户登录
function AppGeneralGameClient.OnKeepWorkLogin_Callback()
end

-- 用户退出
function AppGeneralGameClient.OnKeepWorkLogout_Callback() 
end

-- 获取当前认证用户信息
-- 此函函数返回用户信息会在各玩家间同步, 所以尽量精简
function AppGeneralGameClient:GetUserInfo()
    return self.userinfo;
end

-- 是否是匿名用户
function AppGeneralGameClient:IsAnonymousUser()
    local isAnonymousUser = self:GetOptions().isAnonymousUser;
    if (isAnonymousUser ~= nil) then return isAnonymousUser end

    return self:GetOptions().username ~= System.User.keepworkUsername;  -- 匿名用户不支持离线缓存
end

-- 初始化成单列模式
AppGeneralGameClient:InitSingleton();