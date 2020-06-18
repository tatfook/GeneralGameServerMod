--[[
Title: PacketPlayerEntityInfo
Author(s): wxa
Date: 2020/6/15
Desc: 玩家实体包
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Common/Packets/PacketPlayerLogin.lua");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketPlayerEntityInfo");
local packet = Packets.PacketPlayerEntityInfo:new():Init();
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Packets/Packet.lua");

local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local PacketPlayerEntityInfo = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.Packet"), commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets.PacketPlayerEntityInfo"));

function PacketPlayerEntityInfo:ctor()
end

function PacketPlayerEntityInfo:Init(entityInfo)
    if (not entityInfo) then 
        return self;
    end
    -- 命令
    self.cmd = "";

    -- 实体基础属性
    self.entityId = entityInfo.entityId;
    self.name = entityInfo.name;

    -- 实体数据
    self.data = entityInfo.data;
    
    -- 位置信息
    self.x = entityInfo.x;
    self.y = entityInfo.y;
    self.z = entityInfo.z
    self.facing = entityInfo.facing;
    self.pitch = entityInfo.pitch;
    
    -- 头部信息
    self.headYaw = entityInfo.headYaw;
    self.headPitch = entityInfo.headPitch;

    -- 移动信息
    -- self.stance = entityInfo.stance;
    -- self.onground = entityInfo.onground;
    -- self.moving = entityInfo.moving;

	return self;
end

-- Passes this Packet on to the NetHandler for processing.
function PacketPlayerEntityInfo:ProcessPacket(net_handler)
	if(net_handler.handlePlayerEntityInfo) then
		net_handler:handlePlayerEntityInfo(self);
	end
end
