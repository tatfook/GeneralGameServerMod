--[[
Title: PacketPlayerEntityInfo
Author(s): wxa
Date: 2020/6/16
Desc: 多个方块信息
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Common/Packets/PacketServerInfo.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketServerInfo");
local packet = Packets.PacketServerInfo:new():Init();
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Common/Packets/Packet.lua");

local PacketServerInfo = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketServerInfo"));

function PacketServerInfo:ctor()
end

function PacketServerInfo:Init(svrInfo)
	self.innerIp = svrInfo.innerIp;                 -- 内网IP 
    self.innerPort = svrInfo.innerPort;             -- 内网Port
    self.outerIp = svrInfo.outerIp;                 -- 外网IP
	self.outerPort = svrInfo.outerPort;             -- 外网Port 
	self.totalWorldClientCounts = svrInfo.totalWorldClientCounts;                   -- 服务器世界 
	self.totalWorldCount = svrInfo.totalWorldCount;           -- 世界的数量
	self.totalClientCount = svrInfo.totalClientCount;         -- 客户端的数量
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketServerInfo:ProcessPacket(net_handler)
	if(net_handler.handleServerInfo) then
		net_handler:handleServerInfo(self);
	end
end
