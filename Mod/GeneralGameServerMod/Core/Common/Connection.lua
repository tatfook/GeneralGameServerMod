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
local GGS = NPL.load("Mod/GeneralGameServerMod/Core/Common/GGS.lua");

NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ConnectionBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Connections.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketTypes.lua");
local PacketTypes = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketTypes");
local Connections = commonlib.gettable("MyCompany.Aries.Game.Network.Connections");
local Connection = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.ConnectionBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection"));
local defaultNeuronFile = "Mod/GeneralGameServerMod/Core/Common/Connection.lua";
local nextNid = 100;

Connection.default_neuron_file = defaultNeuronFile;

local NetDebug = GGS.NetDebug;

-- 初始化网络包
PacketTypes:StaticInit();
-- 初始化网络连接
Connections:Init();

-- 服务端初始化方式
function Connection:Init(nid, thread, net_handler)
	self.thread = thread;

	self:SetNid(nid);
	self:SetNetHandler(net_handler);
	return self;
end

-- 客户端初始化方式
function Connection:InitByIpPort(ip, port, thread, net_handler)
	nextNid = nextNid + 1;
	local nid = "ggs_" .. tostring(nextNid);
	NPL.AddNPLRuntimeAddress({host = tostring(ip), port = tostring(port), nid = nid});
	
	return self:Init(nid, thread, net_handler);
end

-- 获取连接ID
function Connection:GetId() 
	return self.id;
end

-- inform the netServerHandler about an error.
-- @param text: this is usually "OnConnectionLost" from ServerListener. or "ConnectionNotEstablished" from client
function Connection:OnError(text)
	if(self.net_handler and self.net_handler.handleErrorMessage) then
		self.net_handler:handleErrorMessage(text, self);
	end
end

function Connection:AddPacketToSendQueue(packet)
	NetDebug(string.format("---------------------send packet: %d--------------------", packet:GetPacketId()), packet:WritePacket());

	return Connection._super.AddPacketToSendQueue(self, packet);
end

-- 接受数据包
function Connection:OnNetReceive(msg)
	-- 读取数据包
	local packet = PacketTypes:GetNewPacket(msg.id);
	if (packet) then packet:ReadPacket(msg) end

	NetDebug(string.format("---------------------recv packet: %s--------------------", packet and packet:GetPacketId() or msg.id), msg);
	
	-- 处理数据包前回调
	if (self.net_handler and self.net_handler.OnBeforeProcessPacket) then
		self.net_handler:OnBeforeProcessPacket(packet or msg, msg);
	end

	-- 处理数据包
	if(packet) then
		packet:ProcessPacket(self.net_handler);
	else
		GGS.INFO("invalid packet");
		if (self.net_handler and self.net_handler.handleMsg) then
			self.net_handler:handleMsg(msg);
		else 
			GGS.INFO("invalid msg");
			GGS.INFO(msg);
		end
	end

	-- 处理数据包后回调
	if (self.net_handler and self.net_handler.OnAfterProcessPacket) then
		self.net_handler:OnAfterProcessPacket(packet or msg, msg);
	end
end

-- 新链接触发回调
function Connection.OnConnection(msg)
	-- 兼容旧版本实现
	if (GGS.IsServer) then
		NPL.load("Mod/GeneralGameServerMod/Core/Server/NetServerHandler.lua");
		local NetServerHandler = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.NetServerHandler");
		return NetServerHandler:new():Init(msg.nid or msg.tid):GetPlayerConnection();
	end

	return nil;
end

function Connection.OnActivate(msg)
	local id = msg.nid or msg.tid;
	if (not id) then return end

	local connection = Connections:GetConnection(id);
	if (connection) then 
		connection:OnNetReceive(msg);
	else 
		Connection.OnConnection(msg);
	end
end

local function activate()
	Connection.OnActivate(msg);
end

NPL.this(activate);
