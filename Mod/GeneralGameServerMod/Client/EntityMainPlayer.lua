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
    local maxMotionUpdateTickCount = 33; -- 1s
    local dx = self.x - self.oldPosX;
    local dy = self.y - self.oldPosY;
    local dz = self.z - self.oldPosZ;
    local hasMoved = self.x ~= self.oldPosX or self.y ~= self.oldPosY or self.z ~= self.oldPosZ;
    local moveDistance = dx * dx + dy * dy + dz * dz;
    local dRotY = self.facing - self.oldRotationYaw;
    local dRotPitch = self.rotationPitch - self.oldRotationPitch;
    local hasRotation = dRotY ~= 0 or dRotPitch ~= 0;
    local forceTick = self.motionUpdateTickCount >= maxMotionUpdateTickCount;
    local force = moveDistance > 1;
    if (self:IsRiding()) then
		-- make riding entity send movement update less frequently, such as when moving one meter. 
        force = moveDistance > 5;
    end

    -- tick 自增
    self.motionUpdateTickCount = self.motionUpdateTickCount + 1;

    -- 位置实时同步, 其它 hasMetaDataChange, hasHeadRotation, hasRotation 配合 Tick 同步
    if (not force and not (forceTick and (hasMetaDataChange or hasHeadRotation or hasRotation or hasMetaDataChange))) then
        return;
    end
    Log:Std("DEBUG", moduleName, "-----------------------------------------------");
    Log:Std("DEBUG", moduleName, "force: %s, moveDistance: %s", force, moveDistance);
    Log:Std("DEBUG", moduleName, "motionUpdateTickCount: %d, hasMoved: %s, hasRotation: %s, hasHeadRotation: %s, hasMetaDataChange: %s", self.motionUpdateTickCount, hasMoved, hasRotation, hasHeadRotation, hasMetaDataChange);
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

    self.oldPosX = self.x;
    self.oldMinY = self.y;
    self.oldPosY = self.y;
    self.oldPosZ = self.z;
    self.oldRotationYaw = self.facing;
    self.oldRotationPitch = self.rotationPitch;
    self.motionUpdateTickCount = 0; 
end