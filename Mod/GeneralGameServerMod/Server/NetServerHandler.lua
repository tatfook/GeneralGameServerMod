
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Server/WorldManager.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Server/WorkerServer.lua");
local WorkerServer = commonlib.gettable("Mod.GeneralGameServerMod.Server.WorkerServer");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Common.Config");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
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

-- 获取WorkerServer
function NetServerHandler:GetWorkerServer()
    return WorkerServer.GetSingleton();
end

-- 获取世界管理器
function NetServerHandler:GetWorldManager() 
    return WorldManager.GetSingleton();
end

-- 设置玩家世界
function NetServerHandler:SetWorld(world) 
    self.world = world;
end
-- 获取玩家世界
function NetServerHandler:GetWorld() 
    return self.world;
end

-- 设置当前玩家
function NetServerHandler:SetPlayer(player)
    self.player = player;
end

-- 获取链接对应的玩家
function NetServerHandler:GetPlayer()
    return self.player;
end

-- 获取世界玩家管理器
function NetServerHandler:GetPlayerManager() 
    return self:GetWorld():GetPlayerManager();
end

function NetServerHandler:GetBlockManager() 
    return self:GetWorld():GetBlockManager();
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
    self.playerConnection:AddPacketToSendQueue(Packets.PacketKickDisconnect:new():Init(reason));
    self.playerConnection:ServerShutdown();
    self.finishedProcessing = true;
end

-- 服务器是否已达到峰值
function NetServerHandler:IsAllowLoginWorld(worldId)
    local totalClientCount = self:GetWorldManager():GetClientCount();
    local worldClientCount = self:GetWorld() and self:GetWorld():GetClientCount() or 0;
    if (totalClientCount >= Config.Server.maxClientCount) then
        return false;
    end
    if (worldClientCount >= Config.World.maxClientCount) then
        return false;
    end
    return true;
end

function NetServerHandler:handlePlayerLogin(packetPlayerLogin)
    local username = packetPlayerLogin.username;
    local password = packetPlayerLogin.password;
    local worldId = tostring(packetPlayerLogin.worldId);

    -- 检测是否达到最大处理量
    if (not self:IsAllowLoginWorld(worldId)) then
        Log:Warn("服务器连接数已到上限");
        packetPlayerLogin.result = "failed";
        packetPlayerLogin.errmsg = "服务器连接数已到上限";
        return self:SendPacketToPlayer(packetPlayerLogin);
    end

    -- TODO 认证逻辑

    -- 认证通过
    self:SetAuthenticated();

    -- 获取并设置世界
    self:SetWorld(self:GetWorldManager():GetWorldById(worldId, true));
    self:GetWorld():SetWorldId(worldId);

    -- 将玩家加入世界
    self:SetPlayer(self:GetPlayerManager():CreatePlayer(username, self));
    self:GetPlayerManager():AddPlayer(self:GetPlayer());

    Log:Info("player login; username : %s, worldId: %s", self:GetPlayer():GetUserName(), self:GetWorld():GetWorldId());

    -- 标记登录完成
    self.finishedProcessing = true;

    -- 设置世界环境
    -- self:SendPacketToPlayer(self:GetWorld():GetPacketUpdateEnv());

    -- 通知玩家登录
    packetPlayerLogin.entityId = self:GetPlayer().entityId;
    packetPlayerLogin.result = "ok";
    self:SendPacketToPlayer(packetPlayerLogin);

    -- self:SendServerInfo();
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

-- 处理块信息更新
function NetServerHandler:handleBlockInfoList(packetBlockInfoList)
    self:GetBlockManager():AddBlockList(packetBlockInfoList.blockInfoList);

     -- 同步到其它玩家
     self:GetPlayerManager():SendPacketToAllPlayersExcept(packetBlockInfoList, self:GetPlayer());
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
    if (not self:GetPlayer()) then return end
    
    Log:Info("player logout; username : %s, worldId: %s", self:GetPlayer():GetUserName(), self:GetWorld():GetWorldId());

    self:GetPlayerManager():RemovePlayer(self:GetPlayer());
    self:GetPlayerManager():SendPacketToAllPlayersExcept(Packets.PacketPlayerLogout:new():Init(self:GetPlayer()), self:GetPlayer());
    self.connectionClosed = true;

    -- self:SendServerInfo();

    self:GetWorldManager():TryRemoveWorld(self:GetWorld():GetWorldId()); 
end

-- 发送服务器负载给控制器服务
function NetServerHandler:SendServerInfo()
    self:GetWorkerServer():SendServerInfo();
end

-- 转发聊天消息
function NetServerHandler:handleChat(packetChat)
    self:GetPlayerManager():SendPacketToAllPlayersExcept(packetChat, self:GetPlayer());
end