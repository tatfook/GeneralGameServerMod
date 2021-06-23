--[[
Title: ConnectionBase
Author(s): wxa
Date: 2020/6/12
Desc: base connection
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Common/Connection.lua");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/System.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketTypes.lua");
local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketTypes");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local GGS = NPL.load("Mod/GeneralGameServerMod/Core/Common/GGS.lua");
local ConnectionBase = NPL.load("Mod/GeneralGameServerMod/Core/Common/ConnectionBase.lua");
local Connection = commonlib.inherit(ConnectionBase, commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection"));

Connection:Property("RemoteNeuronFile", "Mod/GeneralGameServerMod/Core/Common/Connection.lua");   -- 对端处理文件
Connection:Property("LocalNeuronFile", "Mod/GeneralGameServerMod/Core/Common/Connection.lua");    -- 本地处理文件
Connection:Property("NetHandler");

local NetDebug = GGS.NetDebug;

-- 初始化网络包
PacketTypes:StaticInit();

function Connection:Init(opts)
	Connection._super.Init(self, opts);
    if (opts.netHandler) then self:SetNetHandler(opts.netHandler) end
	return self;
end

function Connection:OnConnection()
	Connection._super.OnConnection(self);
	
	local netHandler = self:GetNetHandler();
	if(netHandler and netHandler.handleConnection) then
		netHandler:handleConnection();
	end
end

function Connection:OnClose(reason)
	local netHandler = self:GetNetHandler();
	if(netHandler and netHandler.handleDisconnection) then
		netHandler:handleDisconnection(reason);
	end
end

function Connection:AddPacketToSendQueue(packet)
	NetDebug(string.format("---------------------send packet: %d--------------------", packet:GetPacketId()), packet:WritePacket());
	return self:Send(packet);
end

function Connection:SendData(data)
	self:Send(Packets.PacketGeneral:GetDataPacket(data));
end

function Connection:OnSend(packet, neuronfile)
	return Connection._super.OnSend(self, type(packet.WritePacket) == "function" and packet:WritePacket() or packet, neuronfile);
end

-- 接受数据包
function Connection:OnReceive(msg)
	-- 读取数据包
	local packet = msg.id and PacketTypes:GetNewPacket(msg.id) or nil;
	if (packet) then packet:ReadPacket(msg) end

	NetDebug(string.format("---------------------recv packet: %s--------------------", packet and packet:GetPacketId() or msg.id), msg);
	-- GGS.INFO.Format("packetId = %s packetSize = %s", msg.id, string.len(commonlib.serialize_compact(msg)));

	-- 处理数据包前回调
	local netHandler = self:GetNetHandler();
	if (netHandler and netHandler.OnBeforeProcessPacket) then
		netHandler:OnBeforeProcessPacket(packet or msg, msg);
	end

	-- 处理数据包
	if(packet) then
		if (netHandler) then 
			packet:ProcessPacket(netHandler);
		else
			GGS.INFO("net handler no exist");
		end
	else
		-- GGS.INFO("invalid packet");
		if (netHandler and netHandler.handleMsg) then
			netHandler:handleMsg(msg);
		else 
			GGS.INFO("invalid msg");
			GGS.INFO(msg);
		end
	end

	-- 处理数据包后回调
	if (netHandler and netHandler.OnAfterProcessPacket) then
		netHandler:OnAfterProcessPacket(packet or msg, msg);
	end
end

NPL.this(function() 
	Connection:OnActivate(msg);
end);
