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
NPL.load("Mod/GeneralGameServerMod/Core/Server/QuadTree.lua");
local QuadTree = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.QuadTree");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Config");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local Player = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Player");
local PlayerManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.PlayerManager"));

local WorldMaxSize = 30000;  -- 世界的最大bx, by, bz值
local WorldMarginSize = 10;  -- 以用户为中心计算区域加上次边距, 方便客户端识别玩家是否离开自己的可视区域

PlayerManager:Property("World");   -- 管理器所属世界

function PlayerManager:ctor()
    self.players = {};                                             -- 玩家集 以用户名做key
end

function PlayerManager:Init(world)
    self:SetWorld(world);

    self.minClientCount = self:GetWorld():GetMinClientCount();             -- 保持至少玩家数
    self.onlinePlayerList = commonlib.UnorderedArraySet:new();             -- 在线玩家列表
    self.offlinePlayerQueue = commonlib.Queue:new();                       -- 离线玩家队列

    -- 世界区域化
    local worldConfig = self:GetWorld():GetConfig();
    self.areaSize =  if_else(worldConfig.areaSize == nil or worldConfig.areaSize == 0, 128, worldConfig.areaSize);  
    self.areaMinClientCount = worldConfig.areaMinClientCount or 0;

    -- 四叉树选项 
    local quadtreeOptions = {
        minWidth = self.areaSize,
        minHeight = self.areaSize,
        left = 0, top = 0, right = WorldMaxSize, bottom = WorldMaxSize,
    }
    -- 在线用户四叉树
    self.onlineQuadtree = QuadTree:new():Init(quadtreeOptions);
    -- 离线用户四叉树  仅对平行世界生效
    self.offlineQuadtree = QuadTree:new():Init(quadtreeOptions);

    -- 世界四叉树 包含世界都有方块信息 实现玩家世界按可视化区加载变化同步
    self.worldQuadTree = QuadTree:new():Init({minWidth = self.areaSize, minHeight = self.areaSize, left = 0, top = 0, right = WorldMaxSize, bottom = WorldMaxSize});

    return self;
end

-- 获取下一个实体ID
function PlayerManager:GetNextEntityId()
    return self:GetWorld():GetNextEntityId();
end

-- 获取区域大小
function PlayerManager:GetAreaSize()
    return self.areaSize;
end

-- 是否使能区域化
function PlayerManager:IsEnableArea()
    local worldAreaSize = self:GetWorld():GetConfig().areaSize;
    return worldAreaSize ~= nil and worldAreaSize ~= 0;
end

-- 创建用户 若用户已存在则踢出系统
function PlayerManager:CreatePlayer(username, netHandler)
    -- 移除旧玩家
    self:Logout(self.players[username], "离线玩家重新上线, 踢出旧同名离线玩家");
    
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
        local offlineUsername = self.offlinePlayerQueue[i];
        if (offlineUsername == username) then
            for j = i, self.offlinePlayerQueue.last do
                self.offlinePlayerQueue[j] = self.offlinePlayerQueue[j + 1];
            end
            self.offlinePlayerQueue.last = self.offlinePlayerQueue.last - 1;
            break;
        end
    end
end

-- 用户是否存在于离线玩家列表
function PlayerManager:IsExistOfflinePlayerList(username)
    for i = self.offlinePlayerQueue.first, self.offlinePlayerQueue.last do
        local offlineUsername = self.offlinePlayerQueue[i];
        if (username == offlineUsername) then
            return true;
        end
    end
    return false;
end

-- 添加玩家
function PlayerManager:AddPlayer(player)
    if (not player) then return end

    -- 离线用户留存策略直接以玩家所在世界区域来统计,  不以玩家为中心的动态区域
    local username = player:GetUserName();
    local bx, by, bz = player:GetBlockPos();
    local areaSize = self.areaSize;
    local areaLeft, areaTop = math.floor(bx / areaSize) * areaSize, math.floor(bz / areaSize) * areaSize;
    local areaRight, areaBottom = areaLeft + areaSize, areaTop + areaSize;

    -- 获取旧玩家
    local oldPlayer = self.players[username];
    -- 先移除玩家后添加新玩家
    if (oldPlayer) then self:Logout(oldPlayer, "离线玩家重新上线, 踢出旧同名离线玩家") end

    -- 设置新玩家
    self.players[username] = player;
    -- 添加在线玩家列表
    self.onlinePlayerList:add(username);
    -- 将玩家添加到世界中
    self.worldQuadTree:AddObject(username, bx, bz, bx, bz);
    -- 添加到在线四叉树
    self.onlineQuadtree:AddObject(username, bx, bz, bx, bz);

    -- 是平行世界
    if (self:GetWorld():IsParaWorld() and self.offlineQuadtree:GetObjectCount() > 0) then
        -- 移除离线玩家
        local onlineObjects = self.onlineQuadtree:GetObjects(areaLeft, areaTop, areaRight, areaBottom);
        local offlineObjects = self.offlineQuadtree:GetObjects(areaLeft, areaTop, areaRight, areaBottom);
        if (((#offlineObjects) + (#offlineObjects)) > self.areaMinClientCount and (#offlineObjects) > 0) then
            local logoutUsername = offlineObjects[i];
            self.offlineQuadtree:RemoveObject(logoutUsername);
            self:RemoveOfflinePlayer(logoutUsername);
            self:Logout(self.players[logoutUsername], "新玩家上线, 移除随机离线玩家");
        end
    end

    -- 当前玩家数过少或无离线玩家时直接退出
    if (self:GetPlayerCount() < self.minClientCount or self.offlinePlayerQueue:size() == 0) then return end 

    local logoutUsername = self.offlinePlayerQueue:popleft();
    self.offlineQuadtree:RemoveObject(logoutUsername);
    self:Logout(self.players[logoutUsername],  "新玩家上线, 移除最早离线玩家");
end

-- 移除玩家
function PlayerManager:RemovePlayer(player)
    if (not player) then return end

    -- 匿名玩家或存活时间小于指定时间时不做留存直接删除
    if (not player:IsKeepworkOffline()) then
        return self:Logout(player, "链接断开, 用户下线");
    end

    -- 离线用户留存策略直接以玩家所在世界区域来统计,  不以玩家为中心的动态区域
    local username = player:GetUserName();
    local bx, by, bz = player:GetBlockPos();
    local areaSize = self.areaSize;
    local areaLeft, areaTop = math.floor(bx / areaSize) * areaSize, math.floor(bz / areaSize) * areaSize;
    local areaRight, areaBottom = areaLeft + areaSize, areaTop + areaSize;

    -- 在线列表中移除玩家
    self.onlinePlayerList:removeByValue(username);
    self.worldQuadTree:RemoveObject(username);
    self.onlineQuadtree:RemoveObject(username);
    
    -- 是平行世界
    if (self:GetWorld():IsParaWorld()) then
        -- 统计人数
        local onlineObjects = self.onlineQuadtree:GetObjects(areaLeft, areaTop, areaRight, areaBottom);
        local offlineObjects = self.offlineQuadtree:GetObjects(areaLeft, areaTop, areaRight, areaBottom);
        -- 添加到离线区 先统计后添加, 避免将自己移除, 一般通用离线正常使用
        self.offlineQuadtree:AddObject(username, bx, bz, bx, bz);
        -- 人数过少直接返回
        if (((#offlineObjects) + (#offlineObjects)) > self.areaMinClientCount and (#offlineObjects) > 0) then 
            -- 随机移除一个
            local logoutUsername = offlineObjects[1];
            self.offlineQuadtree:RemoveObject(logoutUsername);
            self:RemoveOfflinePlayer(logoutUsername);
            self:Logout(self.players[logoutUsername], "玩家下线, 随机踢出旧离线玩家");
        end
    end

    -- 留存策略采用队列模式, 留存最新玩家
    self.offlinePlayerQueue:pushright(username);  
    -- 当前玩家数小于指定值 留存玩家不做删除
    if (self:GetPlayerCount() < self.minClientCount or self.offlinePlayerQueue:size() == 0) then return end
    -- 当前玩家数较多时移除最旧玩家(下线时间最早)
    local logoutUsername = self.offlinePlayerQueue:popleft();
    -- 同时移除区间用户
    self.offlineQuadtree:RemoveObject(logoutUsername);
    self:Logout(self.players[logoutUsername], "玩家下线, 踢出最早下线玩家");
end

-- 更新玩家位置信息
function PlayerManager:UpdatePlayerPosInfo(player)
    local bx, by, bz = player:GetBlockPos();
    local username = player:GetUserName();
    if (not self.onlinePlayerList:contains(username)) then return end
    self.onlineQuadtree:AddObject(username, bx, bz, bx, bz);
end

-- 获取所有玩家
function PlayerManager:GetPlayers() 
    return self.players;
end

-- 下线玩家
function PlayerManager:Offline(player, reason)
    if (not player) then return end
    -- 置玩家登出状态
    player:Logout();
    
    -- 如果在线用户数大于最小用户数, 此时逻辑上应没有离线玩家了也不需要离线玩家, 可以直接登出当前用户
    if ((#self.onlinePlayerList) > self.minClientCount) then
        return self:Logout(player, reason);
    end

    -- 获取当前玩家
    local username = player:GetUserName();
    local curPlayer = self.players[username];

    -- 玩家不存在, 或不是最新玩家直接退出
    if (not curPlayer or curPlayer.entityId ~= player.entityId) then
        return self:Logout(player, reason);
    end

    -- 移除玩家
    self:RemovePlayer(player);
    -- 发送玩家信息  通知玩家下线   player.state = "offline"
    self:SendPacketPlayerInfo(player);
end

-- 踢出玩家
function PlayerManager:Logout(player, reason)
    if (not player) then return end
    -- 置玩家登出状态
    player:Logout();
    -- 获取对应的当前玩家
    local username = player:GetUserName();
    local curPlayer = self.players[username];
    -- 玩家不存在或是最新玩家下线, 则需从在线列表中移除
    if (not curPlayer or curPlayer.entityId == player.entityId) then
        self.onlinePlayerList:removeByValue(username);        -- 从在线列表中移除
        self.onlineQuadtree:RemoveObject(username);
        self.worldQuadTree:RemoveObject(username);
        self.players[username] = nil;
    else 
        GGS.Debug.GetModuleDebug("PlayerLoginLogoutDebug").Format("存在同名在线玩家, 保留在线玩家信息: username = %s, entityId = %s", username, curPlayer.entityId);
    end
    -- 从离线列表中移除玩家
    self:RemoveOfflinePlayer(username);                   -- 从离线队列中移除
    self.offlineQuadtree:RemoveObject(username);
    -- 发送退出包
    self:SendPacketPlayerLogout(player, reason);
end

-- 发送玩家退出
function PlayerManager:SendPacketPlayerLogout(player, reason)
    if (not player) then return end

    -- 先发送后移除, 不然移除没法收到自己登出消息
    local packet = Packets.PacketPlayerLogout:new():Init({
        username = player:GetUserName(),
        entityId = player:GetEntityId(),
        reason = reason,
    });

    -- 发送退出包给其它玩家
    self:SendPacketToAllPlayers(packet, player);              -- 通知其它人退出

    -- 发送退出包给自己
    player:SendPacket(packet);                                -- 单独发, 确保自己一定知道自己退出
    
    -- 打印日志
    GGS.Debug.GetModuleDebug("PlayerLoginLogoutDebug")(string.format("发送玩家退出数据包, reason: %s username : %s, worldkey: %s, entityId: %s", tostring(reason), player:GetUserName(), self:GetWorld():GetWorldKey(), player:GetEntityId()));
end

-- 发送玩家信息
function PlayerManager:SendPacketPlayerInfo(player)
    self:SendPacketToAllPlayers(Packets.PacketPlayerInfo:new():Init(player:GetPlayerInfo()), player);  
    GGS.Debug.GetModuleDebug("PlayerLoginLogoutDebug")(string.format("发送玩家离线数据包, username : %s, worldkey: %s, entityId: %s", player:GetUserName(), self:GetWorld():GetWorldKey(), player:GetEntityId()));
end

-- 发数据给所有玩家 curPlayer 为 nil 就包含自己
function PlayerManager:SendPacketToAllPlayers(packet, curPlayer, filter)
    for i = 1, #(self.onlinePlayerList) do 
        local username = self.onlinePlayerList[i];
        local player = self.players[username];
        if (player and player ~= curPlayer and (not filter or filter(player))) then
            player:SendPacketToPlayer(packet);
        end
    end
end

-- 获取区域FIlter
function PlayerManager:GetPlayerAreaFilter(curPlayer, isCurPlayerCenter)
    return function(player)
        if (not curPlayer) then return true end
        if (curPlayer.entityId == player.entityId) then return false end
        if (isCurPlayerCenter and (not curPlayer:IsEnableArea())) then return true end
        if (not isCurPlayerCenter and (not player:IsEnableArea())) then return true end
        local areaSize = if_else(isCurPlayerCenter, curPlayer:GetAreaSize(), player:GetAreaSize());
        if (areaSize == 0) then return true end
        areaSize = math.floor(areaSize / 2) + WorldMarginSize;
        local curPlayerBX = curPlayer:GetEntityInfo().bx or 0;
        local curPlayerBZ = curPlayer:GetEntityInfo().bz or 0;
        local playerBX = player:GetEntityInfo().bx or 0;
        local playerBZ = player:GetEntityInfo().bz or 0;
        if (math.abs(curPlayerBX - playerBX) <= areaSize and math.abs(curPlayerBZ - playerBZ) <= areaSize) then
            return true;
        end
        return false;
    end
end

-- 发送给指定玩家所在的区域
function PlayerManager:SendPacketToAreaPlayers(packet, curPlayer, isCurPlayerCenter, filter)
    -- 玩家自己开启可视化, 世界不一定开启可视化, 所以self:IsEnableArea()必须放在player:IsEnableArea()后检测, 保证玩家和世界都没开启可视化
    if (not curPlayer or not curPlayer:IsEnableArea() or not self:IsEnableArea()) then
        return self:SendPacketToAllPlayers(packet, curPlayer, filter);
    end

    -- 最好使用四叉树, 效率会高很多
    if (not self:GetWorld():IsEnablePlayerSelfAreaSize() or isCurPlayerCenter) then
        local onlinePlayerList = self:GetOnlinePlayerList(curPlayer, isCurPlayerCenter);
        -- GGS.AreaSyncDebug("玩家:" .. curPlayer:GetUserName(), "区域玩家:", onlinePlayerList);
        for i = 1, #onlinePlayerList do
            local username = onlinePlayerList[i];
            local player = self.players[username];
            if (player and player ~= curPlayer and (not filter or filter(player))) then 
                player:SendPacketToPlayer(packet);
            end
        end
    else 
        local areaFilter = self:GetPlayerAreaFilter(curPlayer);
        for i = 1, #(self.onlinePlayerList) do 
            local username = self.onlinePlayerList[i];
            local player = self.players[username];
            if (player and player ~= curPlayer and areaFilter(player) and (not filter or filter(player))) then
                player:SendPacketToPlayer(packet);
            end
        end
    end
end

-- 发送给同步方块的玩家
function PlayerManager:SendPacketToSyncBlockPlayers(packet, curPlayer)
    self:SendPacketToAllPlayers(packet, curPlayer, function(player)
        return player:IsSyncBlock();
    end);
end

-- 发送给同步命令的玩家
function PlayerManager:SendPacketToSyncCmdPlayers(packet, curPlayer)
    self:SendPacketToAllPlayers(packet, curPlayer, function(player) 
        return player:IsSyncCmd();
    end);
end

-- 发送给指定玩家
function PlayerManager:SendPacketToPlayer(packet, player)
    player = self:IsPlayer(player) and player or self:GetPlayer(player);
    if (not player) then return end
    player:SendPacketToPlayer(packet);
end

-- 是否是玩家
function PlayerManager:IsPlayer(player)
    return type(player) == "table" and player.isa and player:isa(Player);
end

-- 是否是在线玩家
function PlayerManager:IsOnlinePlayer(player)
    player = self:GetPlayer(player);  -- 验证玩家有效性

    if (not player) then return false end  -- 不存在则不是

    return self.onlinePlayerList:contains(player:GetUserName());
end

-- 获取指定玩家
function PlayerManager:GetPlayer(id)
    -- 通过用户名查找玩家
    if (type == "string") then return self.players[id] end
    
    -- 玩家验证
    if (self:IsPlayer(id)) then 
        local username = id:GetUserName();
        local player = self.players[username];
        return player == id and player or nil;
    end

    -- 通过entityId查找玩家
    for key, player in pairs(self.players) do 
        if (type(id) == "number" and player.entityId == id) then
            return player;
        end
    end

    return nil;
end

-- 获取所有玩家实体信息列表
function PlayerManager:GetPlayerEntityInfoList(player)
    local playerEntityInfoList = {};
    -- 获取在线用户列表
    local onlinePlayerList = self:GetOnlinePlayerList(player, true);
    for i = 1, #onlinePlayerList do 
        local username = onlinePlayerList[i];
        local player = self.players[username];
        table.insert(playerEntityInfoList, player:GetPlayerEntityInfo());
    end

    -- 获取离线用户列表
    local offlinePlayerList = self:GetOfflinePlayerList(player, true);
    for i = 1, #offlinePlayerList do 
        local username = offlinePlayerList[i];
        local player = self.players[username];
        table.insert(playerEntityInfoList, player:GetPlayerEntityInfo());
    end

    return playerEntityInfoList;
end

-- 获取在线用户的用户名列表
function PlayerManager:GetOnlinePlayerList(player, isUsePlayerAreaSize, marginSize)
    marginSize = marginSize or WorldMarginSize;
    if (player and self:IsEnableArea()) then
        local areaSize = if_else(isUsePlayerAreaSize, player:GetAreaSize(), self:GetAreaSize()); 
        local bx, by, bz = player:GetBlockPos();
        areaSize = math.floor(areaSize / 2) + marginSize;
        -- GGS.AreaSyncDebug("区域大小: " .. tostring(areaSize));
        return self.onlineQuadtree:GetObjects(bx - areaSize, bz - areaSize, bx + areaSize, bz + areaSize);
    else 
        local onlines = {};
        for i = 1, #(self.onlinePlayerList) do
            table.insert(onlines, self.onlinePlayerList[i]);
        end
        return onlines;
    end
end

-- 获取离线用户的用户名列表
function PlayerManager:GetOfflinePlayerList(player, isUsePlayerAreaSize, marginSize)
    marginSize = marginSize or WorldMarginSize;
    if (player and self:IsEnableArea()) then
        local areaSize = if_else(isUsePlayerAreaSize, player:GetAreaSize(), self:GetAreaSize()); 
        local bx, by, bz = player:GetBlockPos();
        areaSize = math.floor(areaSize / 2) + marginSize;
        return self.offlineQuadtree:GetObjects(bx - areaSize, bz - areaSize, bx + areaSize, bz + areaSize);
    else 
        local offlines = {};
        for i = self.offlinePlayerQueue.first, self.offlinePlayerQueue.last do
            table.insert(offlines, self.offlinePlayerQueue[i]);
        end
        return offlines;
    end
end

-- 获取玩家数量
function PlayerManager:GetPlayerCount()
    return self.onlinePlayerList:size() + self.offlinePlayerQueue:size();
end

-- 获取在线玩家数量
function PlayerManager:GetOnlinePlayerCount()
    local count = 0;
    for i = 1, #(self.onlinePlayerList) do 
        local username = self.onlinePlayerList[i];
        local player = self.players[username];
        if (player:IsAlive()) then
            count = count + 1;
        end
    end
    return count;
end



-- 获取最旧的方块同步玩家
function PlayerManager:GetSyncBlockOldestPlayer()
    local oldestPlayer = nil
    for i = 1, #(self.onlinePlayerList) do 
        local username = self.onlinePlayerList[i];
        local player = self.players[username];
        if (player:IsSyncBlock() and player:IsSyncBlockFinish() and player:IsAlive()) then
            if (not oldestPlayer or oldestPlayer.syncBlockTime > player.syncBlockTime) then
                oldestPlayer = player;
            end
        end
    end
    return oldestPlayer;
end

-- Tick
function PlayerManager:Tick()
    self:RemoveInvalidPlayer();
    self:CleanOfflinePlayer();
end

-- 清理离线用户, 移除离线时间超过48小时的用户
function PlayerManager:CleanOfflinePlayer()
    local offlines = self:GetOfflinePlayerList();
    local curTime = ParaGlobal.timeGetTime();
    local maxOfflineTime = 1000 * 60 * 60 * 48; -- 48 hour
    for i = 1, #offlines do
        local username = offlines[i];
        local player = self.players[username];
        if (not player) then
            self:RemoveOfflinePlayer(username);
            self.offlineQuadtree:RemoveObject(username);
        else 
            if (player.logoutTick and (curTime - player.logoutTick) > maxOfflineTime) then
                self:Logout(player);
            end
        end
    end
end

-- 移除没有心跳的玩家
function PlayerManager:RemoveInvalidPlayer()
    local deleted = {};
    for i = 1, #(self.onlinePlayerList) do 
        local username = self.onlinePlayerList[i];
        local player = self.players[username];
        -- 玩家不活跃但链接还在则踢出玩家
        if (not player:IsAlive() and player:IsConnection()) then
            table.insert(deleted, player);
        end
    end

    -- 下线不活跃的用户
    for i = 1, #deleted do
        local invalidPlayer = deleted[i];
        -- 服务器最有在此情况主动关闭连接, 其它情况又客户端主动关闭
        invalidPlayer:CloseConnection();                       -- 主动关闭, 让其激活后自行重连
        self:Offline(deleted[i], "定时移除不活跃用户");          -- 走离线逻辑 
    end
end