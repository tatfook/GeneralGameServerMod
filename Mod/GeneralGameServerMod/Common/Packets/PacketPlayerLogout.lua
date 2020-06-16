--[[
Title: PacketPlayerLogin
Author(s): wxa
Date: 2020/6/12
Desc: 客户端登录成功, 服务器送玩家登录包通知客户端
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Common/Packets/PacketPlayerLogin.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketPlayerLogin");
local packet = Packets.PacketLogin:new():Init(username, password);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");
local PacketPlayerLogout = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketPlayerLogout"));

function PacketPlayerLogout:ctor()
end

function PacketPlayerLogout:Init(player)
	self.entityId = player.entityId;
	self.username =	player.username;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketPlayerLogout:ProcessPacket(net_handler)
	if(net_handler.handlePlayerLogout) then
		net_handler:handlePlayerLogout(self);
	end
end


