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
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local EntityMainPlayer = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayerMPClient"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityMainPlayer"));
local AssetsWhiteList = NPL.load("./AssetsWhiteList.lua");

local moduleName = "Mod.GeneralGameServerMod.Core.Client.EntityMainPlayer";
local maxMotionUpdateTickCount = 33;

EntityMainPlayer:Property("UpdatePlayerInfo", false, "IsUpdatePlayerInfo");

-- 构造函数
function EntityMainPlayer:ctor()
    self.playerInfo = {};
    self.oldBX, self.oldBY, self.oldBZ = 0, 0, 0;
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
    self:SetUpdatePlayerInfo(true);
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
    
    -- 获取模型验证模型的有效性
    local curMainAsset = self.dataWatcher:GetField(self.dataMainAsset);
    if(not AssetsWhiteList.IsInWhiteList(curMainAsset)) then self.dataWatcher:SetField(self.dataMainAsset, AssetsWhiteList.GetRandomFilename()) end

    local hasMetaDataChange = self.dataWatcher:HasChanges();
    local hasHeadRotation = self.rotationHeadYaw ~= self.oldRotHeadYaw or self.rotationHeadPitch ~= self.oldRotHeadPitch;
    local hasMoved = self.x ~= self.oldPosX or self.y ~= self.oldPosY or self.z ~= self.oldPosZ;
    local hasRotation = self.facing ~= self.oldRotationYaw or self.rotationPitch ~= self.oldRotationPitch;
    local bx, by, bz = self:GetBlockPos();
    local dx, dy, dz = math.abs(bx - self.oldBX), math.abs(by - self.oldBY), math.abs(bz - self.oldBZ);
    local moveDistance = math.max(dy, math.max(dx, dz));
    local force = self:IsUpdatePlayerInfo() or moveDistance > 3 or (hasMoved and self.motionUpdateTickCount > 100); -- 如果发生移动， 最大延迟为3s同步一次
    local forceTick = self.motionUpdateTickCount >= maxMotionUpdateTickCount; -- 如果

    -- tick 自增
    self.motionUpdateTickCount = self.motionUpdateTickCount + 1;

    -- 位置实时同步, 其它 hasMetaDataChange, hasHeadRotation, hasRotation 配合 Tick 同步
    if (not force and not (forceTick and (hasMetaDataChange or hasMoved or hasHeadRotation or hasRotation))) then return end
    if (force) then                                                                     -- 位置变动超标
        maxMotionUpdateTickCount = self.motionUpdateTickCount                           -- 尽量保证下个数据包比上时间长， 因在在其它玩家世界自己人物慢一个节拍， 如果是强制更新, 则将tick频率调低  30fps  33 = 1s
    else                                                                                -- 原地操作降低更新频率
        maxMotionUpdateTickCount = maxMotionUpdateTickCount + maxMotionUpdateTickCount; -- 5 10 20 40 80 160 320 640
    end
    local packet = Packets.PacketPlayerEntityInfo:new():Init(nil, self.dataWatcher, false);
    -- 设置用户名
    packet.username = self:GetUserName();
    packet.entityId = self.entityId;
    packet.tick = self.motionUpdateTickCount;

    if (self:IsUpdatePlayerInfo()) then
        packet.playerInfo = self:GetPlayerInfo();
        self:SetUpdatePlayerInfo(false);
    end

    if (hasMoved or hasRotation) then
        packet.x, packet.y, packet.z = self.x, self.y, self.z; 
        packet.facing, packet.pitch = self.facing, self.rotationPitch;
        packet.bx, packet.by, packet.bz = bx, by, bz;
    end
    
    if (hasHeadRotation) then
        packet.headYaw, packet.headPitch = self.rotationHeadYaw, self.rotationHeadPitch;
    end
  
    self:AddToSendQueue(packet);

    self.oldPosX, self.oldPosY, self.oldPosZ = self.x, self.y, self.z;
    self.oldBX, self.oldBY, self.oldBZ = bx, by, bz;
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

-- 获取实体信息
function EntityMainPlayer:GetPacketPlayerEntityInfo()
    local packet = Packets.PacketPlayerEntityInfo:new():Init({entityId = self.entityId}, self.dataWatcher, true);
    packet.x, packet.y, packet.z = self.x, self.y, self.z; 
    packet.facing, packet.pitch = self.facing, self.rotationPitch;
    packet.headYaw, packet.headPitch = self.rotationHeadYaw, self.rotationHeadPitch;
    packet.bx, packet.by, packet.bz = self:GetBlockPos();
    packet.playerInfo = self:GetPlayerInfo();
    return packet;
end
