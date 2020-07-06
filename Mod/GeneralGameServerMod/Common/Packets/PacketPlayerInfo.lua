--[[
Title: PacketPlayerInfo
Author(s): wxa
Date: 2020/6/12
Desc: 玩家信息
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Common/Packets/PacketPlayerLogin.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketPlayerInfo");
local packet = Packets.PacketLogin:new():Init();
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Common/Packets/Packet.lua");
local PacketPlayerInfo = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketPlayerInfo"));

function PacketPlayerInfo:ctor()
end

function PacketPlayerInfo:Init(packet)
	-- 响应包体
    self.entityId = packet.entityId;  -- 玩家实体ID
    self.username = packet.username;  -- 玩家用户名
    self.state = packet.state         -- 玩家在线状态
    self.userType = packet.userType;  -- teacher vip
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketPlayerInfo:ProcessPacket(net_handler)
	if(net_handler.handlePlayerInfo) then
		net_handler:handlePlayerInfo(self);
	end
end
