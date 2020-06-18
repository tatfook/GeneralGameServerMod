--[[
Title: PacketPlayerEntityInfo
Author(s): wxa
Date: 2020/6/15
Desc: 玩家实体包列表
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Common/Packets/PacketPlayerLogin.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketPlayerEntityInfoList");
local packet = Packets.PacketPlayerEntityInfoList:new():Init();
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Common/Packets/Packet.lua");
local PacketPlayerEntityInfoList = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketPlayerEntityInfoList"));

function PacketPlayerEntityInfoList:ctor()
end

function PacketPlayerEntityInfoList:Init(entityInfoList)
    self.playerEntityInfoList = entityInfoList or {};
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketPlayerEntityInfoList:ProcessPacket(net_handler)
	if(net_handler.handlePlayerEntityInfoList) then
		net_handler:handlePlayerEntityInfoList(self);
	end
end
