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

Connection:Property("DefaultNeuronFile", "Mod/GeneralGameServerMod/Core/Common/Connection.lua");
ConnectionBase:Property("NetHandler");

local NetDebug = GGS.NetDebug;

-- 初始化网络包
PacketTypes:StaticInit();

function Connection:Init(opts)
	Connection._super.Init(self, opts);
    if (opts.netHandler) then self:SetNetHandler(opts.netHandler) end
	return self;
end

function Connection:OnConnection()
	
	
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
	local packet = PacketTypes:GetNewPacket(msg.id);
	if (packet) then packet:ReadPacket(msg) end

	NetDebug(string.format("---------------------recv packet: %s--------------------", packet and packet:GetPacketId() or msg.id), msg);
	
	-- 处理数据包前回调
	local netHandler = self:GetNetHandler();
	if (netHandler and netHandler.OnBeforeProcessPacket) then
		netHandler:OnBeforeProcessPacket(packet or msg, msg);
	end

	-- 处理数据包
	if(packet and netHandler) then
		packet:ProcessPacket(netHandler);
	else
		GGS.INFO("invalid packet");
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

-- 版本兼容, 升级几个小版本后可以移除
function Connection:OnActivate(msg)
	if (not GGS.IsServer or self ~= Connection) then return Connection._super.OnActivate(self, msg) end

	local nid = msg and (msg.nid or msg.tid);
	local connection = self:GetConnectionByNid(nid);
	if(connection) then return connection:OnReceive(msg) end


	NPL.load("Mod/GeneralGameServerMod/Core/Server/NetServerHandler.lua");
	local NetServerHandler = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.NetServerHandler");
	NetServerHandler:new():Init({nid = nid}):OnConnection();
end

NPL.this(function() 
	Connection:OnActivate(msg);
end);
