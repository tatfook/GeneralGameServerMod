--[[
Title: NetServerHandler
Author(s): wxa
Date: 2020/6/10
Desc: 网络处理程序
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/NetServerHandler.lua");
local NetServerHandler = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.NetServerHandler");
-------------------------------------------------------
]]
local GGS = NPL.load("Mod/GeneralGameServerMod/Core/Common/GGS.lua");
NPL.load("(gl)script/ide/System/System.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/WorldManager.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/WorkerServer.lua");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Config");
local WorkerServer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.WorkerServer");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local WorldManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.WorldManager");
local NetServerHandler = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.NetServerHandler"));
local ServerDataHandler = NPL.load("Mod/GeneralGameServerMod/Core/Server/ServerDataHandler.lua");

NetServerHandler:Property("Authenticated", false, "IsAuthenticated");  -- 是否认证
NetServerHandler:Property("Player");                                   -- 当前玩家
NetServerHandler:Property("World");                                    -- 当前世界
NetServerHandler:Property("PlayerManager");                            -- 世界玩家管理器
NetServerHandler:Property("WorldManager");                             -- 世界管理器
NetServerHandler:Property("WorkerServer");                             -- 工作服务器
NetServerHandler:Property("DataHandler");                              -- 数据处理

local PlayerLoginLogoutDebug = GGS.PlayerLoginLogoutDebug;

local function GetDataHandler(netHandler)
    local DataHandler = NPL.load(Config.DataHandler.filename) or ServerDataHandler;
    return DataHandler:new():Init(netHandler);
end

function NetServerHandler:ctor() 
    self:SetWorkerServer(WorkerServer);
    self:SetWorldManager(WorldManager);
    self:SetNetHandler(self);
    self:SetDataHandler(GetDataHandler(self));
end

function NetServerHandler:SendPacketToPlayer(packet)
    return self:AddPacketToSendQueue(packet);
end

-- 用户认证成功
function NetServerHandler:handlePlayerLogin(packetPlayerLogin)
    local username = packetPlayerLogin.username;
    local password = packetPlayerLogin.password;
    local worldId = tostring(packetPlayerLogin.worldId);
    local worldName = packetPlayerLogin.worldName or "";
    local worldType = packetPlayerLogin.worldType;
    local worldKey = packetPlayerLogin.worldKey;
    local options = packetPlayerLogin.options;

    PlayerLoginLogoutDebug(string.format("玩家请求登录 username : %s, worldId: %s, worldName: %s, worldType: %s, worldKey: %s, nid: %s, threadName: %s", username, worldId, worldName, worldType, worldkey, self:GetNid(), __rts__:GetName()));

    -- 获取并设置世界
    self:SetWorld(self:GetWorldManager():GetWorld(worldId, worldName, worldType, true, worldKey));
    -- 设置玩家管理器
    self:SetPlayerManager(self:GetWorld():GetPlayerManager());
    -- 获取并设置玩家
    self:SetPlayer(self:GetPlayerManager():CreatePlayer(username, self));   -- 创建玩家
    -- 设置玩家选项
    if (options) then self:GetPlayer():SetOptions(options) end         

    -- TODO 认证逻辑

    -- 认证通过
    self:SetAuthenticated();
    -- 玩家登录
    self:GetPlayer():Login();
    -- 打印日志
    PlayerLoginLogoutDebug(string.format("玩家登录成功 username : %s, worldkey: %s, entityId: %s", self:GetPlayer():GetUserName(), self:GetWorld():GetWorldKey(), self:GetPlayer():GetEntityId()));
    -- 通知玩家登录
    packetPlayerLogin.entityId = self:GetPlayer().entityId;
    packetPlayerLogin.result = "ok";
    packetPlayerLogin.worldName = self:GetWorld():GetWorldName();
    packetPlayerLogin.username = self:GetPlayer().username;
    packetPlayerLogin.worldKey = self:GetWorld():GetWorldKey();
    packetPlayerLogin.areaSize = self:GetPlayer():GetAreaSize();
    self:SendPacketToPlayer(packetPlayerLogin);
end

-- 处理生成玩家包
function NetServerHandler:handlePlayerEntityInfo(packetPlayerEntityInfo)
    -- 用户不存在
    if (not self:GetPlayer()) then return self:handlePlayerRelogin() end

    -- 设置当前玩家实体信息
    local isNew = self:GetPlayer():SetPlayerEntityInfo(packetPlayerEntityInfo);
    local packet = (isNew or self:GetPlayer():IsEnableArea()) and self:GetPlayer():GetPlayerEntityInfo() or packetPlayerEntityInfo;
    -- 新玩家通知所有旧玩家
    self:GetPlayerManager():SendPacketToAreaPlayers(packet, self:GetPlayer());

    -- 非新玩家, 检查玩家是否有效
    if (not isNew) then
        -- 无效玩家进行重新登录
        if (not self:GetPlayer():IsValid()) then self:handlePlayerRelogin() end
        return;
    end

    -- 新玩家同步玩家列表
    self:GetPlayerManager():SendPlayerListToPlayer(self:GetPlayer());
    -- 将玩家加入玩家管理器 有实体信息才加入玩家管理器
    self:GetPlayerManager():AddPlayer(self:GetPlayer());
    -- 开始块同步
    if (self:GetPlayer():IsSyncBlock()) then
        self:SendPacketToPlayer(Packets.PacketGeneral:new():Init({action = "SyncBlock", data = {state = "SyncBlock_Begin"}}));
    end

    -- 更新世界信息
    self:GetWorkerServer():SendWorldInfo(self:GetWorld():GetWorldInfo());
end

-- 同步玩家信息列表
function NetServerHandler:handlePlayerEntityInfoList(packetPlayerEntityInfoList)
    -- 非有效用户直接忽视
    if (not self:GetPlayer() or not self:GetPlayer():IsValid()) then return end

    local playerEntityInfoList = packetPlayerEntityInfoList.playerEntityInfoList;
    for _, packetPlayerEntityInfo in ipairs(playerEntityInfoList) do 
        self:GetPlayer():SetPlayerEntityInfo(packetPlayerEntityInfo);
    end
    self:GetPlayerManager():SendPacketToAllPlayers(packetPlayerEntityInfoList, self:GetPlayer());
end

-- 玩家重新登录, 当连接存在玩家丢失需要重新等陆, 这个问题与TCP自身自动重连有关(玩家第一次登录, 登录切后台, tcp自行断开, 程序恢复前台, tcp自行重连, 这样跳过了登录步骤,导致用户丢失, 这种发送客户端重连数据包)
function NetServerHandler:handlePlayerRelogin()
    PlayerLoginLogoutDebug("玩家丢失重新登录: " .. tostring(self:GetIPAddress()));

    self:SendPacketToPlayer(Packets.PacketGeneral:GetReloginPacket());
end

-- 链接出错 玩家退出
function NetServerHandler:handlePlayerLogout(text)
    -- 玩家不存在, 直接退出    
    if (not self:GetPlayer()) then return end
    
    PlayerLoginLogoutDebug.Format("玩家链接断开: UserName = %s", self:GetPlayer():GetUserName());
   
    -- 下线走离线流程 登出直接踢出服务器
    self:GetPlayerManager():Offline(self:GetPlayer(), "连接断开, 玩家主动下线");
  
    -- 更新世界信息
    self:GetWorkerServer():SendWorldInfo(self:GetWorld():GetWorldInfo());
end

-- 监听包处理后
function NetServerHandler:OnAfterProcessPacket(packet)
    if (not self:GetPlayer()) then return end
    -- 更新玩家心跳
    self:GetPlayer():UpdateTick();
    -- 清空玩家数据队列
    self:GetPlayer():AddPacketToSendQueue(nil, true);
end

-- 转发聊天消息
function NetServerHandler:handleChat(packetChat)
    -- 用户不存在
    if (not self:GetPlayer()) then return self:handlePlayerRelogin() end

    self:GetPlayerManager():SendPacketToAllPlayers(packetChat, self:GetPlayer());
end

-- 处理方块同步
function NetServerHandler:handleGeneral_SyncBlock(packetGeneral)
    -- 用户不存在
    if (not self:GetPlayer()) then return self:handlePlayerRelogin() end

    local state = packetGeneral.data.state;       -- 同步状态
    local playerId = packetGeneral.data.playerId; -- 请求同步玩家ID
    local player = self:GetPlayerManager():GetPlayer(playerId);

    -- 请求的玩家不存在或同步完成直接跳出
    if (not player and player:IsSyncBlockFinish()) then return GGS.DEBUG.Format("请求同步世界方块信息的玩家不存在或已同步完成 playerId = %s", playerId) end

    -- 方块同步逻辑
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
    local debug = packetGeneral.data.debug;
    if (cmd == "WorldInfo") then
        packetGeneral.data.debug = self:GetWorld():GetDebugWorldInfo();
        self:SendPacketToPlayer(packetGeneral);
    elseif (cmd == "PlayerInfo") then
        packetGeneral.data.debug = self:GetWorld():GetDebugPlayerInfo();
        self:SendPacketToPlayer(packetGeneral);
    elseif (cmd == "ServerInfo") then
        packetGeneral.data.debug = self:GetWorkerServer():GetServerInfo();
        self:SendPacketToPlayer(packetGeneral);
    elseif (cmd == "ServerList") then
        packetGeneral.data.debug = self:GetWorkerServer():GetServerList();
        self:SendPacketToPlayer(packetGeneral);
    elseif (cmd == "StatisticsInfo") then
        self:GetWorkerServer():UpdateStatisticsInfo();
        packetGeneral.data.debug = self:GetWorkerServer():GetStatisticsInfo();
        self:SendPacketToPlayer(packetGeneral);
    elseif (cmd == "ping") then
        packetGeneral.data.debug = self:GetPlayer():IsValid();
        self:SendPacketToPlayer(packetGeneral);
    elseif (cmd == "debug") then
        GGS.Debug.ToggleModule(debug);
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
    elseif (packetGeneral.action == "DATA") then
        self:GetDataHandler():RecvData(packetGeneral.data);
    else
        self:GetPlayerManager():SendPacketToAllPlayers(packetGeneral, self:GetPlayer());
    end
end

-- 数据包列表转发
function NetServerHandler:handleMultiple(packetMultiple)
    -- 用户不存在
    if (not self:GetPlayer()) then return self:handlePlayerRelogin() end
    
    if (packetMultiple.action == "SyncBlock") then
        self:GetPlayerManager():SendPacketToSyncBlockPlayers(packetMultiple, self:GetPlayer());
    else
        self:GetPlayerManager():SendPacketToAllPlayers(packetMultiple, self:GetPlayer());
    end
end

-- 处理链接关闭
function NetServerHandler:handleDisconnection(reason)
    self:handlePlayerLogout(reason);
end

NPL.this(function() 
	NetServerHandler:OnActivate(msg);
end);