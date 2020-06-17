--[[
Title: PacketPlayerEntityInfo
Author(s): wxa
Date: 2020/6/16
Desc: 多个方块信息
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Common/Packets/PacketBlockInfoList.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketBlockInfoList");
local packet = Packets.PacketBlockInfoList:new():Init();
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
local PacketBlockInfoList = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketBlockInfoList"));

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
