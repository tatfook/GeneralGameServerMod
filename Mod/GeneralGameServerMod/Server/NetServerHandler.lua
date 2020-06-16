
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Server/WorldManager.lua");

local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Common.Connection");
local WorldManager = commonlib.gettable("Mod.GeneralGameServerMod.Server.WorldManager");
local NetServerHandler = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Server.NetServerHandler"));

function NetServerHandler:ctor()
	self.isAuthenticated = nil;
end

-- @param tid: this is temporary identifier of the socket connnection
function NetServerHandler:Init(tid)
	self.playerConnection = Connection:new():Init(tid, self);
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

-- 获取链接对应的玩家
function NetServerHandler:GetPlayer()
    return self.player;
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

    -- 通知玩家登录
    self:SendPacketToPlayer(Packets.PacketPlayerLogin:new():Init(self.player));
end

-- 处理生成玩家包
function NetServerHandler:handlePlayerEntityInfo(packetPlayerEntityInfo)
    -- 设置当前玩家实体信息
    local isNew = self:GetPlayer():SetPlayerEntityInfo(packetPlayerEntityInfo);
    -- 新玩家通知所有旧玩家
    self:GetPlayerManager():SendPacketToAllPlayersExcept(packetPlayerEntityInfo, self:GetPlayer());
    -- 所有旧玩家告知新玩家   最好只通知可视范围内的玩家信息
    if (isNew) then 
        self:SendPacketToPlayer(Packets.PacketPlayerEntityInfoList:new():Init(self:GetPlayerManager():GetPlayerEntityInfoList()));
    end
end


function NetServerHandler:KickPlayerFromServer(reason)
    if (not self.connectionClosed) then
        self:SendPacketToPlayer(Packets.PacketKickDisconnect:new():Init(reason));
        self.playerConnection:ServerShutdown();
        self.connectionClosed = true;
    end
end

-- 玩家退出
function NetServerHandler:handleErrorMessage(text, data)
    local player = self:GetPlayer();
    LOG.std(nil, "info", "NetServerHandler", "%s lost connections %s", player.username, text or "");
    self:GetPlayerManager():RemovePlayer(player);
    self:GetPlayerManager():SendPacketToAllPlayersExcept(Packets.PacketPlayerLogout:new():Init(player), player);
    self.connectionClosed = true;
end
