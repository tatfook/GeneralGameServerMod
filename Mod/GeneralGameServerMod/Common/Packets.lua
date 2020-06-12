--[[
Title: ConnectionBase
Author(s): wxa
Date: 2014/6/12
Desc: base connection
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Common/ConnectionBase.lua");
local ConnectionBase = commonlib.gettable("Mod.GeneralGameServerMod.Common.ConnectionBase");
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet_Types.lua");
local Packet_Types = commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet_Types");

local Packets = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets"), commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets"));

function Packets:StaticInit()

    Packet_Types:StaticInit();

    NPL.load("Mod/GeneralGameServerMod/Common/Packets/PacketPlayerLogin.lua");
    Packet_Types:AddIdClassMapping(100, false, true, Packets.PacketPlayerLogin);
end