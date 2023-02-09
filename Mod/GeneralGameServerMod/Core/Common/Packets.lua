--[[
Title: ConnectionBase
Author(s): wxa
Date: 2014/6/18
Desc: packet types
use the lib:
-------------------------------------------------------
local Packets = NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet_Types.lua");
local Packet_Types = commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet_Types");

local Packets = NPL.export({
    Packet = NPL.load("./Packets/Packet.lua"),
    PacketBlock = NPL.load("./Packets/PacketBlock.lua"),
    PacketGeneral = NPL.load("./Packets/PacketGeneral.lua"),
    PacketMultiple = NPL.load("./Packets/PacketMultiple.lua"),
    PacketPlayerEntityInfo = NPL.load("./Packets/PacketPlayerEntityInfo.lua"),
    PacketPlayerEntityInfoList = NPL.load("./Packets/PacketPlayerEntityInfoList.lua"),
    PacketPlayerInfo = NPL.load("./Packets/PacketPlayerInfo.lua"),
    PacketPlayerLogin = NPL.load("./Packets/PacketPlayerLogin.lua"),
    PacketPlayerLogout = NPL.load("./Packets/PacketPlayerLogout.lua"),
    PacketTick = NPL.load("./Packets/PacketTick.lua"),
    PacketWorldServer = NPL.load("./Packets/PacketWorldServer.lua"),
});

for key, packet in pairs(Packets) do
    if (type(packet) == "table") then
        packet:RegisterPacket();
    end
end

function Packets:GetPacket(packetId)
    return self.Packet:GetPacket(packetId) or Packet_Types:GetPacketId(packetId);
end


