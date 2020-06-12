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
local PacketPlayerLogin = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketPlayerLogin"));

function PacketPlayerLogin:ctor()
end

function PacketPlayerLogin:Init(player)
	self.playerId = player.playerId;
	self.username =	player.username;
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketPlayerLogin:ProcessPacket(net_handler)
	if(net_handler.handleLogin) then
		net_handler:handlePlayerLogin(self);
	end
end


