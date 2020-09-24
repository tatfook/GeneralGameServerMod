--[[
Title: ConnectionBase
Author(s): wxa
Date: 2014/6/18
Desc: packet types
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketTypes.lua");
local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketTypes");
PacketTypes:StaticInit();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet_Types.lua");
local Packet_Types = commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet_Types");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local PacketTypes = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketTypes"));

PacketTypes.packetIdToClassMap = {}
PacketTypes.packetClassToIdMap = {}

function PacketTypes:StaticInit()
    Packet_Types:StaticInit();

    NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketPlayerLogin.lua");
    self:AddIdClassMapping(100, Packets.PacketPlayerLogin);

    NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketPlayerLogout.lua");
    self:AddIdClassMapping(101, Packets.PacketPlayerLogout);

    NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketPlayerEntityInfo.lua");
    self:AddIdClassMapping(102, Packets.PacketPlayerEntityInfo);

    NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketPlayerEntityInfoList.lua");
    self:AddIdClassMapping(103, Packets.PacketPlayerEntityInfoList);

    NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketBlock.lua");
    self:AddIdClassMapping(104, Packets.PacketBlock);

    NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketServerInfo.lua");
    self:AddIdClassMapping(105, Packets.PacketServerInfo);

    NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketWorldServer.lua");
    self:AddIdClassMapping(106, Packets.PacketWorldServer);

    NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketTick.lua");
    self:AddIdClassMapping(107, Packets.PacketTick);

    NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketPlayerInfo.lua");
    self:AddIdClassMapping(108, Packets.PacketPlayerInfo);

    NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketMultiple.lua");
    self:AddIdClassMapping(109, Packets.PacketMultiple);

    NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketGeneral.lua");
    self:AddIdClassMapping(110, Packets.PacketGeneral);
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
    return self.packetClassToIdMap[packet_class] or Packet_Types:GetPacketId(packet_class);
end

-- Create/Get a new instance of the specified Packet class.
-- it may create a new intance or a singleton is returned depending on packet type. 
function PacketTypes:GetNewPacket(packet_id)
    local packet_class = self.packetIdToClassMap[packet_id] or Packet_Types:GetNewPacket(packet_id);
	if(packet_class) then
		return packet_class:GetInstance();
    end
end