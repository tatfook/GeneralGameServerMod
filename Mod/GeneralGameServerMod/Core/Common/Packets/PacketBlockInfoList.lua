--[[
Title: PacketPlayerEntityInfo
Author(s): wxa
Date: 2020/6/16
Desc: 多个方块信息
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketBlockInfoList.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketBlockInfoList");
local packet = Packets.PacketBlockInfoList:new():Init();
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/Packet.lua");

local PacketBlockInfoList = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketBlockInfoList"));

function PacketBlockInfoList:ctor()
end

function PacketBlockInfoList:Init(blockInfoList)
    self.blockInfoList = blockInfoList or {};
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketBlockInfoList:ProcessPacket(net_handler)
	if(net_handler.handleBlockInfoList) then
		net_handler:handleBlockInfoList(self);
	end
end
