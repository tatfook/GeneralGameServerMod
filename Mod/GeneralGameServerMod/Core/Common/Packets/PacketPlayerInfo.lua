--[[
Title: PacketPlayerInfo
Author(s): wxa
Date: 2020/6/12
Desc: 玩家信息
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketPlayerLogin.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketPlayerInfo");
local packet = Packets.PacketPlayerInfo:new():Init();
-------------------------------------------------------
]]

local Packet = NPL.load("./Packet.lua");
local PacketPlayerInfo = commonlib.inherit(Packet, NPL.export());

local PacketId = 108;
function PacketPlayerInfo:GetPacketId()
    return PacketId;
end

function PacketPlayerInfo:ctor()
end

function PacketPlayerInfo:Init(packet)
	-- 响应包体
    self.entityId = packet.entityId;  -- 玩家实体ID
    self.username = packet.username;  -- 玩家用户名
	self.state = packet.state;        -- 玩家在线状态
	self.role = packet.role;          -- 玩家角色  0 -- 访客  1 --  成员 2 -- 管理员 4 -- 超级管理员(创建者)
	self.userinfo = packet.userinfo;  -- 玩家用户信息 {isVip = 是否是Vip,}
	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketPlayerInfo:ProcessPacket(net_handler)
	if(net_handler.handlePlayerInfo) then
		net_handler:handlePlayerInfo(self);
	end
end
