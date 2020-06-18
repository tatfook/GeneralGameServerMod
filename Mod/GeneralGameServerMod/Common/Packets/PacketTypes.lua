--[[
Title: ConnectionBase
Author(s): wxa
Date: 2014/6/18
Desc: packet types
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Common/Packets/ConnectionBase.lua");
local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketTypes");
PacketTypes:StaticInit();
-------------------------------------------------------
]]

local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");
local PacketTypes = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketTypes"));

PacketTypes.packetIdToClassMap = {}
PacketTypes.packetClassToIdMap = {}

function PacketTypes:StaticInit()
    NPL.load("Mod/GeneralGameServerMod/Common/Packets/PacketPlayerLogin.lua");
    self:AddIdClassMapping(100, Packets.PacketPlayerLogin);

    NPL.load("Mod/GeneralGameServerMod/Common/Packets/PacketPlayerLogout.lua");
    self:AddIdClassMapping(101, Packets.PacketPlayerLogout);

    NPL.load("Mod/GeneralGameServerMod/Common/Packets/PacketPlayerEntityInfo.lua");
    self:AddIdClassMapping(102, Packets.PacketPlayerEntityInfo);

    NPL.load("Mod/GeneralGameServerMod/Common/Packets/PacketPlayerEntityInfoList.lua");
    self:AddIdClassMapping(103, Packets.PacketPlayerEntityInfoList);

    NPL.load("Mod/GeneralGameServerMod/Common/Packets/PacketBlockInfoList.lua");
    self:AddIdClassMapping(104, Packets.PacketBlockInfoList);
end

-- Adds a two way mapping between the packet ID and packet class. and assign the packet id. 
function PacketTypes:AddIdClassMapping(packet_id, packet_class)
	if(not packet_class) then
		LOG.std(nil, "warn", "Packet_Types", "unknown class for packet id:"..packet_id);
    elseif (self.packetIdToClassMap[packet_id]) then
		LOG.std(nil, "warn", "Packet_Types", "Duplicate packet id:"..packet_id);
    elseif (self.packetClassToIdMap[packet_class]) then
        LOG.std(nil, "warn", "Packet_Types", "Duplicate packet class:"..packet_class);
    else
        self.packetIdToClassMap[packet_id] = packet_class;
        self.packetClassToIdMap[packet_class] = packet_id;
		packet_class.id = packet_id;
    end
end

function PacketTypes:GetPacketId(packet_class)
    return self.packetClassToIdMap[packet_class];
end

-- Create/Get a new instance of the specified Packet class.
-- it may create a new intance or a singleton is returned depending on packet type. 
function PacketTypes:GetNewPacket(packet_id)
    local packet_class = self.packetIdToClassMap[packet_id];
	if(packet_class) then
		return packet_class:GetInstance();
    end
end