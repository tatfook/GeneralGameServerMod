--[[
Title: ConnectionBase
Author(s): wxa
Date: 2014/6/18
Desc: packet types
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/Packet.lua");
local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.Packet");
-------------------------------------------------------
]]
local PacketIdToClassMap = {}

local Packet = commonlib.inherit(nil, NPL.export());

local PacketId = 0;
function Packet:GetPacketId()
    return PacketId;
end

-- 构造函数
function Packet:ctor()
    self.__id__ =  self:GetPacketId();
end

function Packet:Init(msg)
	commonlib.partialcopy(self, msg);
	return self;
end



-- 读包
function Packet:ReadPacket(msg)
	commonlib.partialcopy(self, msg);
    return self;
end

-- 写包
function Packet:WritePacket()
    return self;
end

-- 处理包
function Packet:ProcessPacket(net_handler)
end


-- 注册包
function Packet:RegisterPacket()
    PacketIdToClassMap[self:GetPacketId()] = self;
end

function Packet:GetPacketClass(packetId)
    return PacketIdToClassMap[packetId];
end

function Packet:GetPacket(packetId)
    local PacketClass = self:GetPacketClass(packetId);
    if (PacketClass) then return PacketClass:new() end 
end