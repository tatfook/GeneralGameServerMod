--[[
Title: PlayerManager
Author(s): wxa
Date: 2020/6/10
Desc: 管理所有世界玩家
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/PlayerManager.lua");
local PlayerManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.PlayerManager");

-------------------------------------------------------
]]

-- 文件加载
NPL.load("Mod/GeneralGameServerMod/Core/Server/Player.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/QuadTree.lua");
local QuadTree = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.QuadTree");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Config");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local Player = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Player");
local PlayerManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.PlayerManager"));

local WorldMaxSize = 30000;  -- 世界的最大bx, by, bz值
PlayerManager:Property("World");   -- 管理器所属世界

function PlayerManager:ctor()
    
    self.players = {};                                             -- 玩家集 以用户名做key
    self.playerList = commonlib.UnorderedArraySet:new();
    self.minPlayerCount = Config.World.minClientCount;             -- 保持至少玩家数
    self.offlinePlayerQueue = commonlib.Queue:new();               -- 离线玩家队列
    self.ParaWorldAreaSize =  Config.ParaWorld.areaSize;  
    self.areaMinPlayerCount = Config.ParaWorld.areaMinClientCount;

    -- 玩家四叉树  ParaWorld 世界特有
    local quadtreeOptions = {
        minWidth = self.ParaWorldAreaSize,
        minHeight = self.ParaWorldAreaSize,
        left = 0, top = 0, right = WorldMaxSize, bottom = WorldMaxSize,
    }
    self.onlineQuadtree = QuadTree:new():Init(quadtreeOptions);
    self.offlineQuadtree = QuadTree:new():Init(quadtreeOptions);

    -- 世界四叉树 所有世界都有 实现玩家世界按可视化区加载变化同步
    local worldAreaSize = 10;
    self.worldQuadTree = QuadTree:new():Init({minWidth = worldAreaSize, minHeight = worldAreaSize, left = 0, top = 0, right = WorldMaxSize, bottom = WorldMaxSize});
end

function PlayerManager:Init(world)
    self:SetWorld(world);
    return self;
end

-- 获取下一个实体ID
function PlayerManager:GetNextEntityId()
    return self:GetWorld():GetNextEntityId();
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
			self:Logout(player, "You logged in from another location");
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
            self:SendPacketPlayerLogout(offlinePlayer, "离线玩家重新上线, 踢出旧离线玩家");
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
    if (not player) then return end

    local username = player:GetUserName();
    local bx, by, bz = player:GetBlockPos();
    local areaSize = self.ParaWorldAreaSize;
    local areaLeft, areaTop = math.floor(bx / areaSize) * areaSize, math.floor(bz / areaSize) * areaSize;
    local areaRight, areaBottom = areaLeft + areaSize, areaTop + areaSize;

    -- 添加至玩家列表
    self.playerList:add(player);
    self.players[username] = player;

    -- 将玩家添加到世界中
    self.worldQuadTree:AddObject(username, bx, bz, bx, bz);

    -- 新上线的玩家在离线列表, 先简单移除, 后续直接使用上次状态
    self:RemoveOfflinePlayer(username);

    -- 是平行世界
    if (self:GetWorld():IsParaWorld()) then
         -- 添加到在线四叉树
        self.onlineQuadtree:AddObject(username, bx, bz, bx, bz);
        -- 移除离线四叉树
        self.offlineQuadtree:RemoveObject(username);
        -- 移除离线玩家
        local onlineObjects = self.onlineQuadtree:GetObjects(areaLeft, areaTop, areaRight, areaBottom);
        local offlineObjects = self.offlineQuadtree:GetObjects(areaLeft, areaTop, areaRight, areaBottom);
        if (((#offlineObjects) + (#offlineObjects)) > self.areaMinPlayerCount and (#offlineObjects) > 0) then
            self:SendPacketPlayerLogout(self.players[offlineObjects[1]]);
        end
        return ;
    end

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
    if (not player or not self.playerList:contains(player)) then return end

    -- 匿名玩家或存活时间小于指定时间时不做留存直接删除
    if (not player:IsKeepworkOffline()) then
        return self:SendPacketPlayerLogout(player);
    end
    -- 发送玩家信息  通知玩家下线   player.state = "offline"
    self:SendPacketPlayerInfo(player);
    
    -- 是平行世界
    if (self:GetWorld():IsParaWorld()) then
        local username = player:GetUserName();
        local bx, by, bz = player:GetBlockPos();
        local areaSize = self.ParaWorldAreaSize;
        local areaLeft, areaTop = math.floor(bx / areaSize) * areaSize, math.floor(bz / areaSize) * areaSize;
        local areaRight, areaBottom = areaLeft + areaSize, areaTop + areaSize;
        local onlineObjects = self.onlineQuadtree:GetObjects(areaLeft, areaTop, areaRight, areaBottom);
        local offlineObjects = self.offlineQuadtree:GetObjects(areaLeft, areaTop, areaRight, areaBottom);
        -- 添加到离线区
        self.offlineQuadtree:AddObject(username, bx, bz, bx, bz);
        -- 人数过少直接返回
        if (((#offlineObjects) + (#offlineObjects)) < self.areaMinPlayerCount) then return end
        -- 随机移除一个
        self:SendPacketPlayerLogout(self.players[offlineObjects[1] or username]);
        return 
    end

    -- 留存策略采用队列模式, 留存最新玩家
    self.offlinePlayerQueue:pushright(player);  
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

-- 下线玩家
function PlayerManager:Offline(player)
    if (not player) then return end
    -- 置玩家登出状态
    player:Logout();
    -- 移除玩家
    self:RemovePlayer(player);
end

-- 踢出玩家
function PlayerManager:Logout(player, reason)
    -- 置玩家登出状态
    player:Logout();
    -- 踢出玩家
    self:SendPacketPlayerLogout(player, reason);
end

-- 发送玩家退出
function PlayerManager:SendPacketPlayerLogout(player, reason)
    if (not player) then return end

    local username = player:GetUserName();

    -- 先发送后移除, 不然移除没法收到自己登出消息
    local packet = Packets.PacketPlayerLogout:new():Init({
        username = username,
        entityId = player:GetEntityId(),
        reason = reason,
    });

    -- 发送退出包
    self:SendPacketToAllPlayersExcept(packet, player);        -- 通知其它人退出
    player:SendPacket(packet);                                -- 单独发, 确保自己一定知道自己退出

    -- 从玩家列表移除
    self.playerList:removeByValue(player);  -- 玩家登出世界, 从玩家列表中移除
    self.players[username] = nil;
    self.onlineQuadtree:RemoveObject(username);
    self.offlineQuadtree:RemoveObject(username);

    -- 打印日志
    GGS.Debug.GetModuleDebug("PlayerLoginLogoutDebug")(string.format("player logout, reason: %s username : %s, worldkey: %s, entityId: %s", tostring(reason), player:GetUserName(), self:GetWorld():GetWorldKey(), player:GetEntityId()));
end

-- 发送玩家信息
function PlayerManager:SendPacketPlayerInfo(player)
    self:SendPacketToAllPlayers(Packets.PacketPlayerInfo:new():Init(player:GetPlayerInfo()));

    GGS.Debug.GetModuleDebug("PlayerLoginLogoutDebug")(string.format("player offline; username : %s, worldkey: %s, entityId: %s", player:GetUserName(), self:GetWorld():GetWorldKey(), player:GetEntityId()));
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

-- 获取区域FIlter
function PlayerManager:GetPlayerAreaFilter(areaPlayer, isAreaPlayerCenter)
    return function(player)
        if (areaPlayer.entityId == player.entityId) then return false end
        local areaSize = if_else(isAreaPlayerCenter, areaPlayer:GetAreaSize(), player:GetAreaSize());
        if (areaSize == 0) then return true end
        local playerBX = areaPlayer and areaPlayer:GetEntityInfo().bx or 0;
        local playerBZ = areaPlayer and areaPlayer:GetEntityInfo().bz or 0;
        local playerAreaX = areaSize ~= 0 and math.floor(playerBX / areaSize) or 0;
        local playerAreaZ = areaSize ~= 0 and math.floor(playerBZ / areaSize) or 0;
        local bx = player:GetEntityInfo().bx or 0; 
        local bz = player:GetEntityInfo().bz or 0; 
        local areaX = math.floor(bx / areaSize);
        local areaZ = math.floor(bz / areaSize);
        if (math.abs(areaX - playerAreaX) <= 1 and math.abs(areaZ - playerAreaZ) <= 1) then
            return true;
        end
        return false;
    end
end

-- 发送给指定区域的玩家
function PlayerManager:SendPacketToAreaPlayer(packet, areaPlayer)
    self:SendPacketToAllPlayers(packet, self:GetPlayerAreaFilter(areaPlayer, false));
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
    if (not player) then return end
    player:SendPacketToPlayer(packet);
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

    return nil;
end

-- 获取所有玩家实体信息列表
function PlayerManager:GetPlayerEntityInfoList(areaPlayer)
    local areaSize = areaPlayer and areaPlayer:GetAreaSize() or 0;
    local playerBX = areaPlayer and areaPlayer:GetEntityInfo().bx or 0;
    local playerBZ = areaPlayer and areaPlayer:GetEntityInfo().bz or 0;
    local playerAreaX = areaSize ~= 0 and math.floor(playerBX / areaSize) or 0;
    local playerAreaZ = areaSize ~= 0 and math.floor(playerBZ / areaSize) or 0;
    local function filter(player)
        if (areaPlayer.entityId == player.entityId) then return false end
        if (areaSize == 0 or player:IsAlive()) then return true end
        local bx = player:GetEntityInfo().bx or 0; 
        local bz = player:GetEntityInfo().bz or 0; 
        local areaX = math.floor(bx / areaSize);
        local areaZ = math.floor(bz / areaSize);
        if (math.abs(areaX - playerAreaX) <= 1 and math.abs(areaZ - playerAreaZ) <= 1) then
            return true;
        end
        return false;
    end

    local playerEntityInfoList = {};
    for i = 1, #(self.playerList) do 
        local player = self.playerList[i];
        if (filter(player)) then
            table.insert(playerEntityInfoList, player:GetPlayerEntityInfo());
        end
    end

    return playerEntityInfoList;
end

-- 获取玩家数量
function PlayerManager:GetPlayerCount()
    return #(self.playerList);
end

-- 获取在线玩家数量
function PlayerManager:GetOnlinePlayerCount()
    local count = 0;
    for i = 1, #(self.playerList) do 
        local player = self.playerList[i];
        if (player:IsAlive()) then
            count = count + 1;
        end
    end
    return count;
end

-- called period 移除没有心跳的玩家
function PlayerManager:RemoveInvalidPlayer()
    local deleted = {};
    for i = 1, #(self.playerList) do 
        local player = self.playerList[i];
        -- 玩家不活跃但链接还在则踢出玩家
        if (not player:IsAlive() and player:IsConnection()) then
            table.insert(deleted, player);
        end
    end
    -- 下线不活跃的用户
    for i = 1, #deleted do
        self:Logout(deleted[i], "inactive player remove");
    end
end

-- 获取最旧的方块同步玩家
function PlayerManager:GetSyncBlockOldestPlayer()
    local oldestPlayer = nil
    for i = 1, #(self.playerList) do 
        local player = self.playerList[i];
        if (player:IsSyncBlock() and player:IsSyncBlockFinish() and player:IsAlive()) then
            if (not oldestPlayer or oldestPlayer.syncBlockTime > player.syncBlockTime) then
                oldestPlayer = player;
            end
        end
    end
    return oldestPlayer;
end