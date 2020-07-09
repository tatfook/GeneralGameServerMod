--[[
Title: ConnectionBase
Author(s): wxa
Date: 2014/6/18
Desc: packet types
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/Packet.lua");
local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.Packet");
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");

local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketTypes");
local Packet = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.Packet"));

-- Returns the ID of this packet. A faster way is to access the self.id. 
function Packet:GetPacketId()
    return PacketTypes:GetPacketId(self:class());
end