--[[
Title: EntityPlayerHelper
Author(s): wxa
Date: 2020/6/30
Desc: 实体玩家辅助类, 此类实现本应做为基类(EntityPlayer),  为了不更改基础类引入新类, 通过类组合实现相关需求
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Client/EntityPlayerHelper.lua");
local EntityPlayerHelper = commonlib.gettable("Mod.GeneralGameServerMod.Client.EntityPlayerHelper");
-------------------------------------------------------
]]
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
NPL.load("Mod/GeneralGameServerMod/View/UserInfo.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Config.lua");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Common.Config");
local UserInfo = commonlib.gettable("Mod.GeneralGameServerMod.View.UserInfo");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local EntityPlayerHelper = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Client.EntityPlayerHelper"));

function EntityPlayerHelper:Init(entityPlayer, isMainPlayer)
    self.entityPlayer = entityPlayer;
    self.isMainPlayer = isMainPlayer;
    self.playerInfo = {};

    return self;
end

function EntityPlayerHelper:IsOnline()
    return self.playerInfo.state == "online";
end

function EntityPlayerHelper:GetEntityPlayer()
    return self.entityPlayer;
end

function EntityPlayerHelper:GetUserInfoPage()
    return UserInfo:GetSingleton();
end

function EntityPlayerHelper:SetPlayerInfo(playerInfo)
    -- 显示信息是否更改
    local isSetHeadOnDisplay = playerInfo.state and playerInfo.username and (self.playerInfo.state ~= playerInfo.state or self.playerInfo.username ~= playerInfo.username);
    
    -- 拷贝数据
    commonlib.partialcopy(self.playerInfo, playerInfo);

    -- 设置显示
    if (isSetHeadOnDisplay) then self:SetHeadOnDisplay(); end
end

-- 设置头顶信息
function EntityPlayerHelper:SetHeadOnDisplay()
    local player = self.entityPlayer;
    local username = self.playerInfo.username;
    local state = self.playerInfo.state;
    local isVip = self.playerInfo.isVip;
    Log:Info("username: %s, state: %s, vip: %s", username, state, isVip);
    local color = state == "online" and (self.isMainPlayer and "#ffffff" or "#0cff05") or "#6d6d6b";
    local textWidth = _guihelper.GetTextWidth(username, System.DefaultLargeFontString);
    local vipIconUrl = "Texture/Aries/Creator/keepwork/chat/vip_32bits.png#0 0 18 18";
    local mcml = string.format([[
<pe:mcml>
    <div style="margin-left:-%spx;margin-top:-30px">
        <pe:if condition="%s"><div style="float:left;width:16px;height:16px;background:url(%s);"></div></pe:if>
        <div style="float:left; margin-left: 2px; margin-top: -3px; color: %s; font-size: 16px;">%s</div>
    </div>
</pe:mcml>
    ]], (textWidth + 2) / 2 + (isVip and 8 or 0), isVip and "true" or "false", vipIconUrl, color, username);
    player:SetHeadOnDisplay({url=ParaXML.LuaXML_ParseString(mcml)});
end

function EntityPlayerHelper:GetUserName() 
    return self.playerInfo.username;
end

-- virtual function:
function EntityPlayerHelper:OnClick(x,y,z, mouse_button,entity,side)
    if (self.isMainPlayer) then return end;

    self:GetUserInfoPage():Show(self:GetUserName());

    return;
end