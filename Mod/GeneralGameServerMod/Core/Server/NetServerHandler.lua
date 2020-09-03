--[[
Title: NetServerHandler
Author(s): wxa
Date: 2020/6/10
Desc: 网络处理程序
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/NetServerHandler.lua");
local NetServerHandler = commonlib.gettable("GeneralGameServerMod.Core.Server.NetServerHandler");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NetHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/WorldManager.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/WorkerServer.lua");
local WorkerServer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.WorkerServer");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Config");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection");
local WorldManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.WorldManager");
local NetServerHandler = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.NetServerHandler"));

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
    return WorkerServer;
end

-- 获取世界管理器
function NetServerHandler:GetWorldManager() 
    return WorldManager;
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
    if (not self.playerConnection  or self.disconnection) then return end
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
    local totalClientCount = self:GetWorldManager():GetOnlineClientCount();
    local worldClientCount = self:GetWorld() and self:GetWorld():GetOnlineClientCount() or 0;
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
    local parallelWorldName = packetPlayerLogin.parallelWorldName or "";

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
    self:SetWorld(self:GetWorldManager():GetWorld(worldId, parallelWorldName, true));
    -- 获取并设置玩家
    self:SetPlayer(self:GetPlayerManager():CreatePlayer(username, self));   -- 创建玩家
    -- 将玩家加入管理
    self:GetPlayerManager():AddPlayer(self:GetPlayer());
    -- 玩家登录
    self:GetPlayer():Login();
    -- 打印日志
    Log:Info("player login; username : %s, worldkey: %s", self:GetPlayer():GetUserName(), self:GetWorld():GetWorldKey());

    -- 标记登录完成
    self.finishedProcessing = true;

    -- 设置世界环境
    -- self:SendPacketToPlayer(self:GetWorld():GetPacketUpdateEnv());

    -- 通知玩家登录
    packetPlayerLogin.entityId = self:GetPlayer().entityId;
    packetPlayerLogin.result = "ok";
    packetPlayerLogin.parallelWorldName = self:GetWorld():GetParallelWorldName();
    packetPlayerLogin.username = self:GetPlayer().username;
    packetPlayerLogin.worldKey = self:GetWorld():GetWorldKey();
    self:SendPacketToPlayer(packetPlayerLogin);
    -- self:SendServerInfo();
end

-- 处理生成玩家包
function NetServerHandler:handlePlayerEntityInfo(packetPlayerEntityInfo)
    -- 设置当前玩家实体信息
    local isNew = self:GetPlayer():SetPlayerEntityInfo(packetPlayerEntityInfo);
    -- 新玩家通知所有旧玩家
    self:GetPlayerManager():SendPacketToAllPlayersExcept(isNew and self:GetPlayer():GetPlayerEntityInfo() or packetPlayerEntityInfo, self:GetPlayer());
    -- 所有旧玩家告知新玩家   最好只通知可视范围内的玩家信息
    if (isNew) then 
        self:handlePlayerEntityInfoList();
    end
end

-- 同步玩家信息列表
function NetServerHandler:handlePlayerEntityInfoList()
    self:SendPacketToPlayer(Packets.PacketPlayerEntityInfoList:new():Init(self:GetPlayerManager():GetPlayerEntityInfoList(self:GetPlayer())));
end

-- 处理玩家退出
function NetServerHandler:handlePlayerLogout(packetPlayerLogout)
    if (self.disconnection or not self:GetPlayer()) then return end

    -- 玩家退出
    self:GetPlayer():Logout();
    -- 从管理器中移除
    self:GetPlayerManager():RemovePlayer(self:GetPlayer());  -- 移除玩家内部通知其它玩家
    -- 尝试删除世界
    self:GetWorldManager():TryRemoveWorld(self:GetWorld()); 

     -- 表记断开, 不主动断开, 让客户端自行断开,   服务服务器主动断开表明服务器重启, 客户端尝试重连
    self.disconnection = true; 
    
end

-- 链接出错 玩家退出
function NetServerHandler:handleErrorMessage(text, data)
    -- 发送用户退出
    self:handlePlayerLogout();  

    self.playerConnection:CloseConnection();
    self.playerConnection = nil;

    -- 更新服务器信息
    -- self:SendServerInfo();
end


-- 服务强制退出玩家 
function NetServerHandler:KickPlayerFromServer(reason)
    Log:Info("kick player and reason: %s", reason);

    local player = self:GetPlayer();
    if (not player) then return end

    self:handlePlayerLogout(Packets.PacketPlayerLogout:new():Init({
        entityId = player.entityId,
        username = player.username,
        reason = reason;
    }));
end

-- 玩家
function NetServerHandler:handleTick(packetTick)
    if (packetTick.userinfo) then
        self:GetPlayer():SetPlayerInfo({userinfo = packetTick.userinfo});
    end

    self:GetPlayer():UpdateTick();
end

-- 发送服务器负载给控制器服务
function NetServerHandler:SendServerInfo()
    self:GetWorkerServer():SendServerInfo();
end

-- 转发聊天消息
function NetServerHandler:handleChat(packetChat)
    self:GetPlayerManager():SendPacketToAllPlayersExcept(packetChat, self:GetPlayer());
end

-- 处理方块同步
function NetServerHandler:handleGeneral_SyncBlock(packetGeneral)
    local state = packetGeneral.data.state;       -- 同步状态
    local playerId = packetGeneral.data.playerId; -- 请求同步玩家ID
    local player = self:GetPlayerManager():GetPlayer(playerId);
    if (player and player:IsSyncBlockFinish()) then return end;

    if (state == "SyncBlock_Finish") then
        self:GetPlayer():SetSyncBlockFinish();
    elseif (state == "SyncBlock_RequestBlockIndexList" or state == "SyncBlock_RequestSyncBlock") then
        local player = self:GetPlayerManager():GetSyncBlockOldestPlayer();
        if (not player or player == self:GetPlayer()) then
            return self:SendPacketToPlayer(Packets.PacketGeneral:new():Init({action = "SyncBlock", data = {state = "SyncBlock_Finish"}}));
        else
            self:GetPlayerManager():SendPacketToPlayer(packetGeneral, player);
        end
    elseif (state == "SyncBlock_ResponseBlockIndexList" or state == "SyncBlock_ResponseSyncBlock") then
        self:GetPlayerManager():SendPacketToPlayer(packetGeneral, player);
    else

    end
end

-- 处理调试信息
function NetServerHandler:handleGeneral_Debug(packetGeneral)
    local cmd = packetGeneral.data.cmd;
    if (cmd == "WorldInfo") then
        packetGeneral.data.debug = self:GetWorld():GetDebugInfo();
        self:SendPacketToPlayer(packetGeneral);
    elseif (cmd == "ServerInfo") then
        packetGeneral.data.debug = self:GetWorkerServer():GetServerList();
        self:SendPacketToPlayer(packetGeneral);
    end
end

-- 通用数据包转发
function NetServerHandler:handleGeneral(packetGeneral)
    if (packetGeneral.action == "PlayerOptions") then
        self:GetPlayer():SetOptions(packetGeneral.data);
    elseif (packetGeneral.action == "SyncCmd") then
        self:GetPlayerManager():SendPacketToSyncCmdPlayers(packetGeneral, self:GetPlayer());
    elseif (packetGeneral.action == "SyncBlock") then
        self:handleGeneral_SyncBlock(packetGeneral);
    elseif (packetGeneral.action == "Debug") then
        self:handleGeneral_Debug(packetGeneral);
    else
        self:GetPlayerManager():SendPacketToAllPlayersExcept(packetGeneral, self:GetPlayer());
    end
end

-- 数据包列表转发
function NetServerHandler:handleMultiple(packetMultiple)
    if (packetMultiple.action == "SyncBlock") then
        self:GetPlayerManager():SendPacketToSyncBlockPlayers(packetMultiple, self:GetPlayer());
    else
        self:GetPlayerManager():SendPacketToAllPlayersExcept(packetMultiple, self:GetPlayer());
    end
end