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
local NetServerHandler = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.NetServerHandler"));

NetServerHandler:Property("Authenticated", false, "IsAuthenticated");  -- 是否认证
NetServerHandler:Property("Player");                                   -- 当前玩家
NetServerHandler:Property("World");                                    -- 当前世界
NetServerHandler:Property("PlayerManager");                            -- 世界玩家管理器
NetServerHandler:Property("WorldManager");                             -- 世界管理器
NetServerHandler:Property("WorkerServer");                             -- 工作服务器
NetServerHandler:Property("PlayerConnection");                               -- 玩家链接

function NetServerHandler:ctor() 
    self:SetWorkerServer(WorkerServer);
    self:SetWorldManager(WorldManager);
end

-- @param tid: this is temporary identifier of the socket connnection
function NetServerHandler:Init(tid)
	self:SetPlayerConnection(Connection:new():Init(tid, self));
	return self;
end

function NetServerHandler:SendPacketToPlayer(packet)
    if (not self:GetPlayerConnection()) then return end
    return self:GetPlayerConnection():AddPacketToSendQueue(packet);
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
    local worldName = packetPlayerLogin.worldName or "";

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
    self:SetWorld(self:GetWorldManager():GetWorld(worldId, worldName, true));
    -- 设置玩家管理器
    self:SetPlayerManager(self:GetWorld():GetPlayerManager());
    -- 获取并设置玩家
    self:SetPlayer(self:GetPlayerManager():CreatePlayer(username, self));   -- 创建玩家
    -- 玩家登录
    self:GetPlayer():Login();
    -- 打印日志
    Log:Info("player login; username : %s, worldkey: %s", self:GetPlayer():GetUserName(), self:GetWorld():GetWorldKey());

    -- 通知玩家登录
    packetPlayerLogin.entityId = self:GetPlayer().entityId;
    packetPlayerLogin.result = "ok";
    packetPlayerLogin.worldName = self:GetWorld():GetWorldName();
    packetPlayerLogin.username = self:GetPlayer().username;
    packetPlayerLogin.worldKey = self:GetWorld():GetWorldKey();
    self:SendPacketToPlayer(packetPlayerLogin);
end

-- 处理生成玩家包
function NetServerHandler:handlePlayerEntityInfo(packetPlayerEntityInfo)
    -- 用户不存在
    if (not self:GetPlayer()) then return self:handlePlayerRelogin() end

    -- 设置当前玩家实体信息
    local isNew = self:GetPlayer():SetPlayerEntityInfo(packetPlayerEntityInfo);
    -- 新玩家通知所有旧玩家
    self:GetPlayerManager():SendPacketToAllPlayersExcept(isNew and self:GetPlayer():GetPlayerEntityInfo() or packetPlayerEntityInfo, self:GetPlayer());
    -- self:GetPlayerManager():SendPacketToAreaPlayer(self:GetPlayer():GetPlayerEntityInfo(), self:GetPlayer());
    -- 所有旧玩家告知新玩家   最好只通知可视范围内的玩家信息
    if (isNew) then 
        self:handlePlayerEntityInfoList();
        -- 将玩家加入管理 有实体信息才加入玩家管理器
        self:GetPlayerManager():AddPlayer(self:GetPlayer());
    end

end

-- 同步玩家信息列表
function NetServerHandler:handlePlayerEntityInfoList()
    -- 用户不存在 重新登录
    if (not self:GetPlayer()) then return self:handlePlayerRelogin() end
    
    -- 更新玩家列表
    self:SendPacketToPlayer(Packets.PacketPlayerEntityInfoList:new():Init(self:GetPlayerManager():GetPlayerEntityInfoList(self:GetPlayer())));
end

-- 处理玩家退出
function NetServerHandler:handlePlayerLogout(packetPlayerLogout)
    if (not self:GetPlayer()) then return end
    
    -- 玩家退出
    self:GetPlayer():Logout();
    -- 从管理器中移除
    self:GetPlayerManager():RemovePlayer(self:GetPlayer());  -- 移除玩家内部通知其它玩家
    -- 尝试删除世界
    self:GetWorldManager():TryRemoveWorld(self:GetWorld()); 
end

-- 玩家重新登录, 当连接存在玩家丢失需要重新等陆, 这个问题与TCP自身自动重连有关(玩家第一次登录, 登录切后台, tcp自行断开, 程序恢复前台, tcp自行重连, 这样跳过了登录步骤,导致用户丢失, 这种发送客户端重连数据包)
function NetServerHandler:handlePlayerRelogin()
    Log:Info("client relogin: ", self:GetPlayerConnection():GetIPAddress());
    self:SendPacketToPlayer(Packets.PacketGeneral:GetReloginPacket());
end

-- 链接出错 玩家退出
function NetServerHandler:handleErrorMessage(text, data)
    -- 发送用户退出
    self:handlePlayerLogout();  

    self:GetPlayerConnection():CloseConnection();
    self:SetPlayerConnection(nil);
end

-- 服务强制退出玩家 
function NetServerHandler:KickPlayerFromServer(reason)
    Log:Info("kick player and reason: %s", reason);

    self:handlePlayerLogout(Packets.PacketPlayerLogout:new():Init({
        entityId = player and player.entityId,
        username = player and player.username,
        reason = reason;
    }));
end

-- 监听包处理后
function NetServerHandler:OnAfterProcessPacket(packet)
    -- 更新玩家心跳
    if (self:GetPlayer()) then 
        self:GetPlayer():UpdateTick();
    end
end

-- 转发聊天消息
function NetServerHandler:handleChat(packetChat)
    -- 用户不存在
    if (not self:GetPlayer()) then return self:handlePlayerRelogin() end

    self:GetPlayerManager():SendPacketToAllPlayersExcept(packetChat, self:GetPlayer());
end

-- 处理方块同步
function NetServerHandler:handleGeneral_SyncBlock(packetGeneral)
    -- 用户不存在
    if (not self:GetPlayer()) then return self:handlePlayerRelogin() end

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
    -- 用户不存在
    if (not self:GetPlayer()) then return self:handlePlayerRelogin() end

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
    -- 用户不存在
    if (not self:GetPlayer()) then return self:handlePlayerRelogin() end

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
    -- 用户不存在
    if (not self:GetPlayer()) then return self:handlePlayerRelogin() end
    
    if (packetMultiple.action == "SyncBlock") then
        self:GetPlayerManager():SendPacketToSyncBlockPlayers(packetMultiple, self:GetPlayer());
    else
        self:GetPlayerManager():SendPacketToAllPlayersExcept(packetMultiple, self:GetPlayer());
    end
end