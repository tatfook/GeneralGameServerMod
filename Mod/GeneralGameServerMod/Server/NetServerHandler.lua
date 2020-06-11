NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ConnectionTCP.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetHandler.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerListener.lua");

NPL.load("Mod/GeneralGameServerMod/Server/WorldManager.lua");

local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local ConnectionTCP = commonlib.gettable("MyCompany.Aries.Game.Network.ConnectionTCP");
local ServerListener = commonlib.gettable("MyCompany.Aries.Game.Network.ServerListener");

local WorldManager = commonlib.gettable("GeneralGameServerMod.Server.WorldManager");
local NetServerHandler = commonlib.inherit(nil, commonlib.gettable("GeneralGameServerMod.Server.NetServerHandler"));

-- 重写或改写ServerListener类  仅生效在服务端
-- whenever an unknown pending message is received. 
function ServerListener:OnAcceptIncomingConnection(msg, tunnelClient)
	local tid;
	if(msg and msg.tid) then
		tid = msg.tid;
	end
	if(tid) then
		if(self.pendingConnectionCount > self.max_pending_connection) then
			LOG.std(nil, "info", "ServerListener", "max pending connection reached ignored connection %s", tid);
		end
		self.connectionCounter = self.connectionCounter + 1;
		local login_handler = NetServerHandler:new():Init(tid, tunnelClient);
		self:AddPendingConnection(tid, login_handler);
	end
end

function NetServerHandler:ctor()
	self.isAuthenticated = nil;
end

-- @param tid: this is temporary identifier of the socket connnection
function NetServerHandler:Init(tid, tunnelClient)
	self.playerConnection = ConnectionTCP:new():Init(tid, nil, self, tunnelClient);
	return self;
end

-- 获取世界管理器
function NetServerHandler:GetWorldManager() 
    return WorldManager.GetSingleton();
end

-- 获取玩家世界
function NetServerHandler:GetWorld() 
    return self.world;
end

-- 获取世界玩家管理器
function NetServerHandler:GetPlayerManager() 
    return self:GetWorld():GetPlayerManager();
end

function NetServerHandler:SetAuthenticated()
	self.isAuthenticated = true;
end

function NetServerHandler:IsAuthenticated()
	return self.isAuthenticated;
end

-- either succeed or error. 
function NetServerHandler:IsFinishedProcessing()
	return self.finishedProcessing;
end

function NetServerHandler:SendPacketToPlayer(packet)
    LOG.debug(packet);
    return self.playerConnection:AddPacketToSendQueue(packet);
end

-- called periodically by ServerListener:ProcessPendingConnections()
function NetServerHandler:Tick()
	self.loginTimer = (self.loginTimer or 0) + 1;
	if (self.loginTimer >= 600) then
       self:KickUser("take too long to log in");
	end
end

--  Disconnects the user with the given reason.
function NetServerHandler:KickUser(reason)
    LOG.std(nil, "info", "NetLoginHandler", "Disconnecting %s, reason: %s", self:GetUsernameAndAddress(), tostring(reason));
    self.playerConnection:AddPacketToSendQueue(Packets.PacketKickDisconnect:new():Init(reason));
    self.playerConnection:ServerShutdown();
    self.finishedProcessing = true;
end

function NetServerHandler:GetUsernameAndAddress()
	if(self.clientUsername) then
		return format("%s (%s)", self.clientUsername, tostring(self.playerConnection:GetRemoteAddress()));
	else
		return tostring(self.playerConnection:GetRemoteAddress());
	end
end

function NetServerHandler:handleAuthUser(packet_AuthUser)
    if(packet_AuthUser.username and packet_AuthUser.username ~= "") then
		self.clientUsername = packet_AuthUser.username;
	end
	self.clientPassword = packet_AuthUser.password;

    -- TODO 认证逻辑
    LOG.debug("----------------auth user-------------------");
    
    -- 认证通过
    self:SetAuthenticated();
    if(self:IsAuthenticated()) then
        self:SendPacketToPlayer(Packets.PacketAuthUser:new():Init(self.clientUsername, nil, "ok", info));
    end
end

function NetServerHandler:handleLoginClient(packet_loginclient)
    if (not self:IsAuthenticated()) then
        return;
    end
    -- 获取世界
    self.world = self:GetWorldManager():GetDefaultWorld();
    -- 将玩家加入世界
    self.player = self:GetPlayerManager():CreatePlayer(self.clientUsername, self);
    self:GetPlayerManager():AddPlayer(self.player);

    -- 标记登录完成
    self.finishedProcessing = true;

    -- 设置出生地点
    self:SendPacketToPlayer(self:GetWorld():GetPacketSpawnPosition());
    -- 设置世界环境
    self:SendPacketToPlayer(self:GetWorld():GetPacketUpdateEnv());
end

function NetServerHandler:KickPlayerFromServer(reason)
    if (not self.connectionClosed) then
        self:SendPacketToPlayer(Packets.PacketKickDisconnect:new():Init(reason));
        self.playerConnection:ServerShutdown();
        self.connectionClosed = true;
    end
end
