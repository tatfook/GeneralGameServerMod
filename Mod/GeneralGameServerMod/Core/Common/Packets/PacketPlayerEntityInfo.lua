--[[
Title: PacketPlayerEntityInfo
Author(s): wxa
Date: 2020/6/15
Desc: 玩家实体包
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketPlayerEntityInfo.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketPlayerEntityInfo");
local packet = Packets.PacketPlayerEntityInfo:new():Init();
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/Packet.lua");

local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local PacketPlayerEntityInfo = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketPlayerEntityInfo"));

function PacketPlayerEntityInfo:ctor()
end

function PacketPlayerEntityInfo:Init(entityInfo, dataWatcher, isAllObject)
    -- 实体数据
    if (isAllObject) then
        self.metadata = dataWatcher and dataWatcher:GetAllObjectList();
    else
        self.metadata = dataWatcher and dataWatcher:UnwatchAndReturnAllWatched();
    end

    if (not entityInfo) then 
        return self;
    end
    
    -- 遍历信息
    for key, val in pairs(entityInfo) do
        if (type(val) ~= "table" and type(val) ~= "function") then
            self[key] = val;
        end
    end

    -- 实体基础属性
    self.entityId = entityInfo.entityId;
    self.username = entityInfo.username;

    -- 位置信息
    self.x = entityInfo.x;
    self.y = entityInfo.y;
    self.z = entityInfo.z;
    self.bx = entityInfo.bx;
    self.by = entityInfo.by;
    self.bz = entityInfo.bz;
    self.facing = entityInfo.facing;
    self.pitch = entityInfo.pitch;
    
    -- 头部信息
    self.headYaw = entityInfo.headYaw;
    self.headPitch = entityInfo.headPitch;

    -- tickcount = frmaecount
    self.tick = entityInfo.tick;
    self.motionAnimId = entityInfo.motionAnimId;

    -- 实体对应的玩家信息
    self.playerInfo = entityInfo.playerInfo;

	return self;
end

-- virtual: read packet from network msg data
function PacketPlayerEntityInfo:ReadPacket(msg)
    self._super.ReadPacket(self, msg);
    if (self.data) then
        self.metadata = DataWatcher.ReadWatchebleObjects(self.data);
        self.data = nil;
    end
end

-- the list of watcheble objects
function PacketPlayerEntityInfo:GetMetadata()
    return self.metadata;
end

-- virtual: By default, the packet itself is used as the raw message. 
-- @return a packet to be send. 
function PacketPlayerEntityInfo:WritePacket()
	if(self.metadata) then
		self.data = DataWatcher.WriteObjectsInListToData(self.metadata, nil);
		self.metadata = nil;
	end
	return self._super.WritePacket(self);
end

-- Passes this Packet on to the NetHandler for processing.
function PacketPlayerEntityInfo:ProcessPacket(net_handler)
	if(net_handler.handlePlayerEntityInfo) then
		net_handler:handlePlayerEntityInfo(self);
	end
end
