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

NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/Packet.lua");

local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketTypes");
local Packet = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.Packet"));

-- 构造函数
function Packet:ctor()
end

-- 获取包ID
function Packet:GetPacketId()
    return PacketTypes:GetPacketId(self:class());
end

-- 写包
function Packet:WritePacket()
    local msg = Packet._super.WritePacket(self);
    msg.id = self:GetPacketId();   -- 增加包Id字段
    return msg;
end

-- 获取包ID
-- function Packet:GetPacketIdByMsg(msg)
--     return msg.__id__ or msg.id;
-- end
