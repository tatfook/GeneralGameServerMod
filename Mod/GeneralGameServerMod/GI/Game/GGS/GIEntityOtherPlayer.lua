--[[
Title: GIEntityOtherPlayer
Author(s): wxa
Date: 2020/7/9
Desc: 非主玩家实体类, 主实现非主玩家相关操作
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/GI/Game/GGS/GIEntityOtherPlayer.lua");
-------------------------------------------------------
]]
NPL.load("Mod/GeneralGameServerMod/Core/Client/EntityOtherPlayer.lua");
local GIEntityOtherPlayer = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityOtherPlayer"), NPL.export());

-- 构造函数
function GIEntityOtherPlayer:ctor()
    -- 非主玩家是否检测碰撞
    self:SetCheckCollision(false);
    self:SetEnableAssetsWhiteList(false);
end

-- 是否使用默认用户名显示
function GIEntityOtherPlayer:IsShowHeadOnDisplay()
    return true;
end

-- 设置玩家信息
function GIEntityOtherPlayer:SetPlayerInfo(playerInfo)
    self:UpdateDisplayName(playerInfo.username or "");
end



