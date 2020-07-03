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
local UserInfo = commonlib.gettable("Mod.GeneralGameServerMod.View.UserInfo");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local EntityPlayerHelper = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Client.EntityPlayerHelper"));

function EntityPlayerHelper:Init(entityPlayer, isMainPlayer)
    self.entityPlayer = entityPlayer;
    self.isMainPlayer = isMainPlayer;
    self.playerInfo = {};

    return self;
end

function EntityPlayerHelper:GetEntityPlayer()
    return self.entityPlayer;
end

function EntityPlayerHelper:GetUserInfoPage()
    return UserInfo:GetSingleton();
end

function EntityPlayerHelper:SetPlayerInfo(playerInfo)
    local curPlayerInfo = self.playerInfo;
    if (playerInfo.state and playerInfo.username and (curPlayerInfo.state ~= playerInfo.state or curPlayerInfo.username ~= playerInfo.username)) then
        curPlayerInfo.username = playerInfo.username or curPlayerInfo.username or self:GetEntityPlayer():GetDisplayName() or "";
        curPlayerInfo.state = playerInfo.state or curPlayerInfo.state;
        Log:Info("username: %s, state: %s", curPlayerInfo.username, curPlayerInfo.state);
        local color = curPlayerInfo.state == "online" and (self.isMainPlayer and "12 5 245" or "12 245 5") or "200 200 200";
        local displayName = curPlayerInfo.username;
        if(self:GetEntityPlayer():IsShowHeadOnDisplay() and System.ShowHeadOnDisplay) then
            System.ShowHeadOnDisplay(true, self:GetEntityPlayer():GetInnerObject(), displayName, color);	
        end
    end
end

function EntityPlayerHelper:GetUserName() 
    return self.playerInfo.username;
end

-- virtual function:
function EntityPlayerHelper:OnClick(x,y,z, mouse_button,entity,side)
    Log:Info("我被点击了");

    if (self.isMainPlayer) then return end;

    self:GetUserInfoPage():Show(self:GetUserName());

    return;
end