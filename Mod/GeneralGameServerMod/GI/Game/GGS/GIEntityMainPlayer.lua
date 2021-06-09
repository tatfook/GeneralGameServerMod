--[[
Title: GIEntityMainPlayer
Author(s): wxa
Date: 2020/7/9
Desc: 主玩家实体类, 主实现主玩家相关操作
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/GI/Game/GGS/GIEntityMainPlayer.lua");
-------------------------------------------------------
]]
NPL.load("Mod/GeneralGameServerMod/Core/Client/EntityMainPlayer.lua", IsDevEnv);
local GIEntityMainPlayer = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityMainPlayer"), NPL.export());

-- 构造函数
function GIEntityMainPlayer:ctor()
    self:SetEnableAssetsWhiteList(false);
end

-- 是否使用默认用户名显示
function GIEntityMainPlayer:IsShowHeadOnDisplay()
    return true;
end

-- 设置玩家信息
function GIEntityMainPlayer:SetPlayerInfo(playerInfo)
    self:UpdateDisplayName(playerInfo.username or "");
end

