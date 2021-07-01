--[[
Title: PacketPlayerLogin
Author(s): wxa
Date: 2020/6/12
Desc: 客户端登录成功, 服务器送玩家登录包通知客户端
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketPlayerLogout.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketPlayerLogout");
local packet = Packets.PacketPlayerLogout:new():Init();
-------------------------------------------------------
]]

local Packet = NPL.load("./Packet.lua");
local PacketPlayerLogout = commonlib.inherit(Packet, NPL.export());

function PacketPlayerLogout:GetPacketId()
    return 101;
end

function PacketPlayerLogout:ctor()
end

function PacketPlayerLogout:Init(packet)
	self.entityId = packet.entityId;
	self.username =	packet.username;

	-- 退出原因
	self.reason = packet.reason;

	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketPlayerLogout:ProcessPacket(net_handler)
	if(net_handler.handlePlayerLogout) then
		net_handler:handlePlayerLogout(self);
	end
end


