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
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");

local EntityMainPlayer = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayerMPClient"), commonlib.gettable("Mod.GeneralGameServerMod.Client.EntityMainPlayer"));

-- Send updated motion and position information to the server
function EntityMainPlayer:SendMotionUpdates()
	local obj = self:GetInnerObject();
	if(not obj) then
		return;
	end
	if(not self:IsNearbyChunkLoaded()) then
		return;
	end
	-- send animation and action
	-- the channel 0 of the animation is always the Entity action. channel 1,2,3,... are for PacketAnimation
    local curAnimID = obj:GetField("AnimID", 0);
	self:SetAnimId(curAnimID);

    local hasMetaDataChange = self.dataWatcher:HasChanges();
    local metadata = hasMetaDataChange and self.dataWatcher:UnwatchAndReturnAllWatched() or nil;
    local data = metadata and DataWatcher.WriteObjectsInListToData(metadata, nil);


	-- send head rotation if any 
	local dHeadRot = self.rotationHeadYaw - self.oldRotHeadYaw;
    local dHeadPitch = self.rotationHeadPitch - self.oldRotHeadPitch;
    local hasHeadRotation = dHeadRot~=0 or dHeadPitch~=0;
	if (hasHeadRotation) then
		self.oldRotHeadYaw = self.rotationHeadYaw;
		self.oldRotHeadPitch = self.rotationHeadPitch;
	end

    -- send movement and body facing. 
    local maxMotionUpdateTickCount = 33 * 120; -- 120s
    local dx = self.x - self.oldPosX;
    local dy = self.y - self.oldPosY;
    local dz = self.z - self.oldPosZ;
    local dRotY = self.facing - self.oldRotationYaw;
    local dRotPitch = self.rotationPitch - self.oldRotationPitch;
	local distSqMoved = (dx * dx + dy * dy + dz * dz);
    local hasMovedOrForceTick = distSqMoved > 0.001 or self.motionUpdateTickCount >= maxMotionUpdateTickCount;
    local hasRotation = dRotY ~= 0 or dRotPitch ~= 0;

    if (self:IsRiding()) then
		-- make riding entity send movement update less frequently, such as when moving one meter. 
        hasMovedOrForceTick = hasMovedOrForceTick and (distSqMoved > 2 or self.motionUpdateTickCount >= maxMotionUpdateTickCount);
	end

    -- 忽略 hasHeadRotation or hasRotation 影响
    if (hasMovedOrForceTick or hasMetaDataChange) then
        LOG.debug("entity info change, hasMovedOrForceTick: %s, hasRotation: %s, hasHeadRotation: %s, hasMetaDataChange: %s", hasMovedOrForceTick, hasRotation, hasHeadRotation, hasMetaDataChange);
        self:AddToSendQueue(Packets.PacketPlayerEntityInfo:new():Init({
            entityId = self.entityId, 
            x = self.x, 
            y = self.y, 
            stance = self.y, 
            z = self.z, 
            facing = self.facing, 
            pitch = self.rotationPitch, 
            onground = self.onGround,
            headYaw = hasHeadRotation and self.rotationHeadYaw or nil,
            HeadPitch = hasHeadRotation and self.rotationHeadPitch or nil,
            data = data,
        }));
    end

    self.motionUpdateTickCount = self.motionUpdateTickCount + 1;
    self.wasOnGround = self.onGround;

    if (hasMovedOrForceTick) then
        self.oldPosX = self.x;
        self.oldMinY = self.y;
        self.oldPosY = self.y;
        self.oldPosZ = self.z;
        self.motionUpdateTickCount = 0;
    end

    if (hasRotation) then
        self.oldRotationYaw = self.facing;
        self.oldRotationPitch = self.rotationPitch;
    end
end