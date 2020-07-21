--[[
Title: entity player multiplayer client
Author(s): wxa
Date: 2020/6/15
Desc: the main player entity on the client side. 
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Client/EntityMainPlayer.lua");
local EntityOtherPlayer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityMainPlayer");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayerMPClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local EntityMainPlayer = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayerMPClient"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityMainPlayer"));

local moduleName = "Mod.GeneralGameServerMod.Core.Client.EntityMainPlayer";
local maxMotionUpdateTickCount = 33;

-- 构造函数
function EntityMainPlayer:ctor()
    self.playerInfo = {};
end

-- 初始化函数
function EntityMainPlayer:init(world, netHandler, entityId)
    EntityMainPlayer._super.init(self, world, netHandler, entityId);
    self:SetSkipPicking(not self:IsCanClick());
    return self;
end

-- 发送网络数据包
function EntityMainPlayer:AddToSendQueue(packet)
    EntityMainPlayer._super.AddToSendQueue(self, packet);
end

-- 是否可以被点击
function EntityMainPlayer:IsCanClick() 
    return false;
end
-- 设置玩家信息
function EntityMainPlayer:SetPlayerInfo(playerInfo)
    commonlib.partialcopy(self.playerInfo, playerInfo);
end
-- 获取玩家信息
function EntityMainPlayer:GetPlayerInfo()
    return self.playerInfo;
end
-- 实体玩家是否在家
function EntityMainPlayer:IsOnline()
    return self.playerInfo.state == "online";
end

-- Send updated motion and position information to the server
function EntityMainPlayer:SendMotionUpdates()
    if(not self:GetInnerObject() or not self:IsNearbyChunkLoaded()) then return end
    
    local hasMetaDataChange = self.dataWatcher:HasChanges();
	-- send head rotation if any 
	local dHeadRot = self.rotationHeadYaw - self.oldRotHeadYaw;
    local dHeadPitch = self.rotationHeadPitch - self.oldRotHeadPitch;
    local hasHeadRotation = dHeadRot~=0 or dHeadPitch~=0;
    -- send movement and body facing. 
    local dx = self.x - self.oldPosX;
    local dy = self.y - self.oldPosY;
    local dz = self.z - self.oldPosZ;
    local hasMoved = self.x ~= self.oldPosX or self.y ~= self.oldPosY or self.z ~= self.oldPosZ;
    local moveDistance = dx * dx + dy * dy + dz * dz;
    local dRotY = self.facing - self.oldRotationYaw;
    local dRotPitch = self.rotationPitch - self.oldRotationPitch;
    local hasRotation = dRotY ~= 0 or dRotPitch ~= 0;
    local force = self:IsRiding() and (moveDistance > 2) or (moveDistance > 0.1);
    local forceTick = self.motionUpdateTickCount >= maxMotionUpdateTickCount;

    -- tick 自增
    self.motionUpdateTickCount = self.motionUpdateTickCount + 1;

    -- 位置实时同步, 其它 hasMetaDataChange, hasHeadRotation, hasRotation 配合 Tick 同步
    if (not force and not (forceTick and (hasMetaDataChange or hasMoved or hasHeadRotation or hasRotation))) then return end
    if (force) then                   -- 位置变动超标
        maxMotionUpdateTickCount = 5; -- 如果是强制更新, 则将tick频率调低  30fps  33 = 1s
    else                              -- 原地操作降低更新频率
        maxMotionUpdateTickCount = maxMotionUpdateTickCount + maxMotionUpdateTickCount;  -- 5 10 20 40 80 160 320 640
    end;
    -- Log:Std("DEBUG", moduleName, "-----------------------------------------------");
    -- Log:Std("DEBUG", moduleName, "force: %s, moveDistance: %s, ", force, moveDistance);
    -- Log:Std("DEBUG", moduleName, "motionUpdateTickCount: %d, hasMoved: %s, hasRotation: %s, hasHeadRotation: %s, hasMetaDataChange: %s", self.motionUpdateTickCount, hasMoved, hasRotation, hasHeadRotation, hasMetaDataChange);
    local packet = Packets.PacketPlayerEntityInfo:new():Init({entityId = self.entityId}, self.dataWatcher, false);
    if (hasMoved or hasRotation) then
        packet.x, packet.y, packet.z = self.x, self.y, self.z; 
        packet.facing, packet.pitch = self.facing, self.rotationPitch;
    end
    if (hasHeadRotation) then
        packet.headYaw, packet.headPitch = self.rotationHeadYaw, self.rotationHeadPitch;
    end
  
    self:AddToSendQueue(packet);

    self.oldPosX = self.x;
    self.oldMinY = self.y;
    self.oldPosY = self.y;
    self.oldPosZ = self.z;
    self.oldRotationYaw = self.facing;
    self.oldRotationPitch = self.rotationPitch;
    self.oldRotHeadYaw = self.rotationHeadYaw;
	self.oldRotHeadPitch = self.rotationHeadPitch;
    self.motionUpdateTickCount = 0; 
end

-- @param chatmsg: ChatMessage or string. 
function EntityMainPlayer:SendChatMsg(chatmsg, chatdata)
    return false;
end

-- 是否可以触发压力
function EntityMainPlayer:doesEntityTriggerPressurePlate()
    return true;
end
