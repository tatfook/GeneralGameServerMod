--[[
Title: entity player multiplayer client
Author(s): wxa
Date: 2020/6/15
Desc: the main player entity on the client side. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayerMPClient.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayerMPClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");

local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");
local EntityMainPlayer = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayerMPClient"), commonlib.gettable("Mod.GeneralGameServerMod.Client.EntityMainPlayer"));

local moduleName = "Mod.GeneralGameServerMod.Client.EntityMainPlayer";

-- Send updated motion and position information to the server
function EntityMainPlayer:SendMotionUpdates()
    local obj = self:GetInnerObject();
	if(not obj) then
		return;
	end
	if(not self:IsNearbyChunkLoaded()) then
		return;
	end
    if(not self:GetInnerObject() or not self:IsNearbyChunkLoaded()) then return end
    
    local hasMetaDataChange = self.dataWatcher:HasChanges();
	-- send head rotation if any 
	local dHeadRot = self.rotationHeadYaw - self.oldRotHeadYaw;
    local dHeadPitch = self.rotationHeadPitch - self.oldRotHeadPitch;
    local hasHeadRotation = dHeadRot~=0 or dHeadPitch~=0;
    -- send movement and body facing. 
    local maxMotionUpdateTickCount = 33; -- 1s
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
    if (not hasMetaDataChange and not force and not (forceTick and (hasMoved or hasHeadRotation or hasRotation))) then
        return;
    end

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