--[[
Title: PlayerManager
Author(s): wxa
Date: 2020/6/10
Desc: 管理所有世界玩家
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/PlayerManager.lua");
local PlayerManager = commonlib.gettable("GeneralGameServerMod.Core.Server.PlayerManager");

-------------------------------------------------------
]]

-- 文件加载
NPL.load("Mod/GeneralGameServerMod/Core/Server/Player.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Config");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
-- 对象获取
local Player = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Player");

-- 对象定义
local PlayerManager = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.PlayerManager"));


function PlayerManager:ctor()
    self.playerList = commonlib.UnorderedArraySet:new();
    self.minPlayerCount = Config.World.minClientCount;             -- 保持至少玩家数
    self.minAliveTime = Config.Player.minAliveTime;                -- 最少存活时间   
    self.offlinePlayerQueue = commonlib.Queue:new();  -- 离线玩家队列
end

function PlayerManager:Init(world)
    self.world = world;  -- 所属世界
    return self;
end

function PlayerManager:GetWorld() 
    return self.world;
end

function PlayerManager:GetNextEntityId()
    return self.world:GetNextEntityId();
end

-- 创建用户 若用户已存在则踢出系统
function PlayerManager:CreatePlayer(username, netHandler)
    local duplicated_players;
    local username_lower_cased = string.lower(username or "");
    for i = 1, #(self.playerList) do
        local player = self.playerList[i];
        if (string.lower(player:GetUserName() or "") == username_lower_cased) then
			duplicated_players = duplicated_players or {};
			duplicated_players[#duplicated_players+1] = player;
        end
    end

    if(duplicated_players) then
		for i=1, #(duplicated_players) do
			local player = duplicated_players[i];
			player:KickPlayerFromServer("You logged in from another location");
		end
	end
    
    -- 创建玩家
    local player = Player:new():Init({
        entityId = self:GetNextEntityId(),
        username = username,
    }, self, netHandler);

    return player;
end

-- 从离线列表中移除玩家
function PlayerManager:RemoveOfflinePlayer(username)
    for i = self.offlinePlayerQueue.first, self.offlinePlayerQueue.last do
        local offlinePlayer = self.offlinePlayerQueue[i];
        if (username and offlinePlayer.username == username) then
            for j = i, self.offlinePlayerQueue.last do
                self.offlinePlayerQueue[j] = self.offlinePlayerQueue[j + 1];
            end
            self.offlinePlayerQueue.last = self.offlinePlayerQueue.last - 1;
            self.playerList:removeByValue(offlinePlayer);
            self:SendPacketPlayerLogout(offlinePlayer);
            break;
        end
    end
end

-- 用户是否存在于离线玩家列表
function PlayerManager:IsExistOfflinePlayerList(username)
    for i = self.offlinePlayerQueue.first, self.offlinePlayerQueue.last do
        local offlinePlayer = self.offlinePlayerQueue[i];
        if (username and offlinePlayer.username == username) then
            return true;
        end
    end

    return false;
end

-- 添加玩家
function PlayerManager:AddPlayer(player)
    -- 添加至玩家列表
    self.playerList:add(player);

    -- 新上线的玩家在离线列表, 先简单移除, 后续直接使用上次状态
    self:RemoveOfflinePlayer(player.username);

    -- 当前玩家数过多时移除玩家
    if (#self.playerList > self.minPlayerCount) then 
        local logoutPlayer = self.offlinePlayerQueue:popleft();
        if (logoutPlayer) then
            self:SendPacketPlayerLogout(logoutPlayer);
        end
    end
end

-- 移除玩家
function PlayerManager:RemovePlayer(player)
    -- 匿名玩家或存活时间小于指定时间时不做留存直接删除
    if (player:IsAnonymousUser() or player.aliveTime < self.minAliveTime) then
        return self:SendPacketPlayerLogout(player);
    end

    -- 留存策略采用队列模式, 留存最新玩家
    self.offlinePlayerQueue:pushright(player);  
    -- 发送玩家信息  通知玩家下线   player.state = "offline"
    self:SendPacketPlayerInfo(player);

    -- 当前玩家数小于指定值 留存玩家不做删除
    if (#self.playerList < self.minPlayerCount) then return end

    -- 当前玩家数较多时移除最旧玩家(下线时间最早)
    local logoutPlayer = self.offlinePlayerQueue:popleft();
    if (logoutPlayer) then
        self:SendPacketPlayerLogout(logoutPlayer);
    end
end

-- 获取玩家列表
function PlayerManager:GetPlayerList() 
    return self.playerList;
end

-- 发送玩家退出
function PlayerManager:SendPacketPlayerLogout(player)
    self.playerList:removeByValue(player);  -- 玩家登出世界, 从玩家列表中移除
    self:SendPacketToAllPlayers(Packets.PacketPlayerLogout:new():Init(player));

    Log:Info("player logout; username : %s, worldkey: %s", player:GetUserName(), self:GetWorld():GetWorldKey());
end

-- 发送玩家信息
function PlayerManager:SendPacketPlayerInfo(player)
    Log:Info("player offline; username : %s, worldkey: %s", player:GetUserName(), self:GetWorld():GetWorldKey());
    self:SendPacketToAllPlayers(Packets.PacketPlayerInfo:new():Init(player:GetPlayerInfo()));
end

-- 发数据给所有玩家
function PlayerManager:SendPacketToAllPlayers(packet, filterFunc)
    for i = 1, #(self.playerList) do 
        local player = self.playerList[i];
        if (not filterFunc or filterFunc(player)) then
            player:SendPacketToPlayer(packet);
        end
    end
end

-- 发数据包给所有玩家排除指定玩家
function PlayerManager:SendPacketToAllPlayersExcept(packet, excludedPlayer)
    for i = 1, #(self.playerList) do 
        local player = self.playerList[i];
        if excludedPlayer ~= player then
            player:SendPacketToPlayer(packet);
        end
    end
end

-- 发送给同步方块的玩家
function PlayerManager:SendPacketToSyncBlockPlayers(packet, excludedPlayer)
    self:SendPacketToAllPlayers(packet, function(player)
        return player ~= excludedPlayer and player:IsSyncBlock();
    end);
end

-- 发送给同步命令的玩家
function PlayerManager:SendPacketToSyncCmdPlayers(packet, excludedPlayer)
    self:SendPacketToAllPlayers(packet, function(player) 
        return player ~= excludedPlayer and player:IsSyncCmd();
    end);
end

-- 是否是玩家
function PlayerManager:IsPlayer(player)
    return type(player) == "table" and player.isa and player:isa(Player);
end

-- 发送给指定玩家
function PlayerManager:SendPacketToPlayer(packet, player)
    player = self:IsPlayer(player) and player or self:GetPlayer(player);
    if (not player) then
        player:SendPacketToPlayer(packet);
    end
end

-- 获取指定玩家
function PlayerManager:GetPlayer(id)
    for i = 1, #(self.playerList) do 
        local player = self.playerList[i];
        if (type(id) == "number" and player.entityId == id) then
            return player;
        end
        if (type(id) == "string" and player.username == id) then
            return player;
        end
        if (type(id) == "table" and player == id) then
            return player;
        end
    end

    return id;
end

-- 获取所有玩家实体信息列表
function PlayerManager:GetPlayerEntityInfoList()
    local playerEntityInfoList = {};
    for i = 1, #(self.playerList) do 
        local player = self.playerList[i];
        playerEntityInfoList[i] = player:GetPlayerEntityInfo();
    end
    return playerEntityInfoList;
end

-- 获取玩家数量
function PlayerManager:GetPlayerCount()
    return self.playerList:size();
end

-- called period 移除没有心跳的玩家
function PlayerManager:RemoveInvalidPlayer()
    local list = {};
    for i = 1, #(self.playerList) do 
        local player = self.playerList[i];
        if (not player:IsAlive()) then
            list[#list + 1] = player;
        end
    end

    for i = 1, #list do
        local player = list[i];
        player:KickPlayerFromServer("remove inactive users");
    end
end

-- 获取最旧的方块同步玩家
function PlayerManager:GetSyncBlockOldestPlayer()
    local oldestPlayer = nil
    for i = 1, #(self.playerList) do 
        local player = self.playerList[i];
        if (player:IsSyncBlock()) then
            if (not oldestPlayer or oldestPlayer.syncBlockTime > player.syncBlockTime) then
                oldestPlayer = player;
            end
        end
    end
    return oldestPlayer;
end