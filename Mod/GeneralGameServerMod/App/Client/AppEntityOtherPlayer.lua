--[[
Title: AppEntityOtherPlayer
Author(s): wxa
Date: 2020/7/9
Desc: 非主玩家实体类, 主实现非主玩家相关操作
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/App/Client/AppEntityOtherPlayer.lua");
local AppEntityOtherPlayer = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppEntityOtherPlayer");
-------------------------------------------------------
]]
NPL.load("Mod/GeneralGameServerMod/Core/Client/EntityOtherPlayer.lua");
NPL.load("Mod/GeneralGameServerMod/App/View/UserInfo.lua");
NPL.load("Mod/GeneralGameServerMod/App/Client/AppEntityPlayerHelper.lua");
local AppEntityPlayerHelper = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppEntityPlayerHelper");
local UserInfo = commonlib.gettable("Mod.GeneralGameServerMod.App.View.UserInfo");
local AppEntityOtherPlayer = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityOtherPlayer"), commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppEntityOtherPlayer"));

local moduleName = "Mod.GeneralGameServerMod.App.Client.AppEntityOtherPlayer";

-- 构造函数
function AppEntityOtherPlayer:ctor()
    self.appEntityPlayerHelper = AppEntityPlayerHelper:new():Init(self, false);

    -- 非主玩家是否检测碰撞
    self:SetCheckCollision(false);
end

-- 禁用默认用户名显示
function AppEntityOtherPlayer:IsShowHeadOnDisplay()
    return false;
end

-- 玩家被点击
function AppEntityOtherPlayer:OnClick(x,y,z, mouse_button,entity,side)
    UserInfo:Show(self);
    -- 阻止默认行为     
    return true;
end

-- 是否可以被点击
function AppEntityOtherPlayer:IsCanClick() 
    return true;
end

-- 设置玩家信息
function AppEntityOtherPlayer:SetPlayerInfo(playerInfo)
    self.appEntityPlayerHelper:SetPlayerInfo(playerInfo);
end

-- 获取用户名
function AppEntityOtherPlayer:GetUserName()
    return self:GetPlayerInfo().username;
end

-- 设置父类用户信息
function AppEntityOtherPlayer:SetSuperPlayerInfo(playerInfo)
    AppEntityOtherPlayer._super.SetPlayerInfo(self, playerInfo);
end


