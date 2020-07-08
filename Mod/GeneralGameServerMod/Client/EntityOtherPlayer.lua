--[[
Title: entity player multiplayer client
Author(s): wxa
Date: 2020/6/15
Desc: the other player entity on the client side. 
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Client/EntityOtherPlayer.lua");
local EntityOtherPlayer = commonlib.gettable("Mod.GeneralGameServerMod.Client.EntityOtherPlayer");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayerMPOther.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
NPL.load("Mod/GeneralGameServerMod/Client/EntityPlayerHelper.lua");

local EntityPlayerHelper = commonlib.gettable("Mod.GeneralGameServerMod.Client.EntityPlayerHelper");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");
local EntityOtherPlayer = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayerMPOther"), commonlib.gettable("Mod.GeneralGameServerMod.Client.EntityOtherPlayer"));

local moduleName = "Mod.GeneralGameServerMod.Client.EntityOtherPlayer";


function EntityOtherPlayer:ctor()
    self.entityPlayerHelper = EntityPlayerHelper:new():Init(self, false);
end

-- 设置玩家信息
function EntityOtherPlayer:SetPlayerInfo(playerInfo)
    self.entityPlayerHelper:SetPlayerInfo(playerInfo);
end

-- virtual function:
function EntityOtherPlayer:OnClick(x,y,z, mouse_button,entity,side)
    self.entityPlayerHelper:OnClick(x,y,z, mouse_button,entity,side);
    -- 返回真 取消默认事件处理程序
    return true;
end

-- 是否可以被其它实体推动
function EntityOtherPlayer:CanBePushedBy(entity)
    return not self:IsOnline();
end

-- 实体玩家是否在家
function EntityOtherPlayer:IsOnline()
    return self.entityPlayerHelper:IsOnline();
end

-- 是否存在target
function EntityOtherPlayer:HasTarget()
    -- 在线用户使用 target 移动
    if (self:IsOnline()) then
        return self._super.HasTarget(self);
    end
    -- 离线用户使用 montion 避让
    return false;
end

-- 动画帧
function EntityOtherPlayer:FrameMove(deltaTime)
    if (not self:IsOnline()) then
        self._super.MoveEntity(self, deltaTime);	
    end

    self:OnUpdate();
end

-- 更改人物外观
function EntityOtherPlayer:UpdateEntityActionState()
    local dataWatcher = self:GetDataWatcher();
    -- 改写大小同步规则
    local curScale = dataWatcher:GetField(self.dataFieldScale);
	if(curScale and curScale ~= self:GetScaling()) then
		self:SetScaling(curScale > 1.5 and 1.5 or (curScale < 0.5 and 0.5 or curScale));
    end
    -- 调用基类函数
    self._super.UpdateEntityActionState(self);
end
