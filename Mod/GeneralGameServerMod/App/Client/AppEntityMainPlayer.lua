--[[
Title: AppEntityOtherPlayer
Author(s): wxa
Date: 2020/7/9
Desc: 主玩家实体类, 主实现主玩家相关操作
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/App/Client/AppEntityMainPlayer.lua");
local AppEntityMainPlayer = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppEntityMainPlayer");
-------------------------------------------------------
]]
NPL.load("Mod/GeneralGameServerMod/Core/Client/EntityMainPlayer.lua");
NPL.load("Mod/GeneralGameServerMod/App/Client/AppEntityPlayerHelper.lua");
local AppEntityPlayerHelper = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppEntityPlayerHelper");
local AppEntityMainPlayer = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityMainPlayer"), commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppEntityMainPlayer"));

local moduleName = "Mod.GeneralGameServerMod.App.Client.AppEntityMainPlayer";

-- 构造函数
function AppEntityMainPlayer:ctor()
    self.appEntityPlayerHelper = AppEntityPlayerHelper:new():Init(self, true);

    GameLogic.GetFilters():add_filter("ggs", function(msg)
        if (type(msg) == "table" and msg.action == "UpdateUserInfo") then
            local userinfo = msg.userinfo;
            self:SetSuperPlayerInfo({userinfo = userinfo});
            self.appEntityPlayerHelper:SetHeadOnDisplay();
        end
        return msg;
    end);
end

-- 禁用默认用户名显示
function AppEntityMainPlayer:IsShowHeadOnDisplay()
    return false;
end

-- 玩家被点击
function AppEntityMainPlayer:OnClick()
end

-- 是否可以被点击
function AppEntityMainPlayer:IsCanClick() 
    return false;
end

-- 设置玩家信息
function AppEntityMainPlayer:SetPlayerInfo(playerInfo)
    self.appEntityPlayerHelper:SetPlayerInfo(playerInfo);
end

-- 设置父类玩家信息
function AppEntityMainPlayer:SetSuperPlayerInfo(playerInfo)
    AppEntityMainPlayer._super.SetPlayerInfo(self, playerInfo);
end

-- 设置头顶显示内容
-- function AppEntityMainPlayer:SetHeadOnDisplay()
-- end