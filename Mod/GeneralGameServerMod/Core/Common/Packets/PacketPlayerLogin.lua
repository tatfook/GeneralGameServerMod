--[[
Title: PacketPlayerLogin
Author(s): wxa
Date: 2020/6/12
Desc: 客户端登录成功, 服务器送玩家登录包通知客户端
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketPlayerLogin.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketPlayerLogin");
local packet = Packets.PacketPlayerLogin:new():Init();
-------------------------------------------------------
]]
local Packet = NPL.load("./Packet.lua");
local PacketPlayerLogin = commonlib.inherit(Packet, NPL.export());

function PacketPlayerLogin:GetPacketId()
    return 100;
end

function PacketPlayerLogin:ctor()
end

function PacketPlayerLogin:Init(packet)
	-- 响应包体
	self.result = packet.result;      -- 请求结果
	self.entityId = packet.entityId;  -- 玩家实体ID
	self.areaSize = packet.areaSize;  -- 玩家可视区大小
	self.errmsg = packet.errmsg;      -- 错误信息
	-- 请求包体
	self.username =	packet.username;  -- 用户名
	self.password = packet.password;  -- 密码
	self.worldId = packet.worldId;    -- 世界ID
	self.worldName = packet.worldName; -- 世界名
	self.worldType = packet.worldType; -- 世界类型
	self.worldKey = packet.worldKey;   -- 世界Key
	self.options = packet.options;     -- 玩家选项信息

	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketPlayerLogin:ProcessPacket(net_handler)
	if(net_handler.handlePlayerLogin) then
		net_handler:handlePlayerLogin(self);
	end
end


