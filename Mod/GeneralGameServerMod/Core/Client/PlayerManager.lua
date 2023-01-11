--[[
Title: PlayerManager
Author(s): wxa
Date: 2020/6/10
Desc: 管理所有世界玩家
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Client/PlayerManager.lua");
local PlayerManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.PlayerManager");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");
local Encoding = commonlib.gettable("System.Encoding");
local Packets = NPL.load("../Common/Packets.lua");

local PlayerManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.PlayerManager"));

PlayerManager:Property("World");            -- 玩家管理器所属世界
PlayerManager:Property("MainPlayer");       -- 主玩家
PlayerManager:Property("AreaSize");         -- 玩家可视区域
PlayerManager:Property("UserVisible", true, "IsUserVisible");              -- 玩家是否可见
PlayerManager:Property("PlayerVisible", true, "IsPlayerVisible");          -- 离线玩家是否可见   
PlayerManager:Property("CanClickPlayer", true, "IsCanClickPlayer");

function PlayerManager:ctor()
    self.players = {};   -- 玩家集
    self.spawn_offline_user_count = 0;
    self.spawn_players = {}
end

function PlayerManager:Init(world)
    self:SetWorld(world);
    self:SetCanClickPlayer(true);
    return self;
end

function PlayerManager:IsCanSpawnPlayer()
    local world = self:GetWorld();
    return world and world:IsWorldOwner();
end


function PlayerManager:AddPlayer(entityPlayer)
    if (not entityPlayer) then return end
    local username = entityPlayer:GetUserName();
    if (not username) then return end;
    
    -- 存在同名旧玩家且不为当前对象则先移除
    local oldplayer = self.players[username];
    if (oldplayer ~= entityPlayer) then self:RemovePlayer(oldplayer) end
    entityPlayer:Attach();
    self.players[username] = entityPlayer;
    entityPlayer:SetVisible(self:IsUserVisible());
    self:RemoveSpawnPlayer(username);
    self:SendSyncSpawnPlayer();
end

function PlayerManager:RemovePlayer(entityPlayer)
    if (type(entityPlayer) == "string") then entityPlayer = self.players[entityPlayer] end
    if (not entityPlayer) then return end
    local username = entityPlayer:GetUserName();
    entityPlayer:SetName(nil);
    entityPlayer:Destroy();

    self.players[username] = nil;
    self:RemoveSpawnPlayer(username);
end

function PlayerManager:SetMainEntityPlayer(entityPlayer)
    self:SetMainPlayer(entityPlayer);
    self:RemovePlayer(entityPlayer:GetUserName());
end

function PlayerManager:GetPlayerByUserName(username, bExcludeSpawnPlayer)
    local player = self.players[username or ""];
    if (player) then return player end 
    if (not bExcludeSpawnPlayer) then return self.spawn_players[username or ""] end 
    return nil;
end

function PlayerManager:GetPlayerByEntityId(entityId, bExcludeSpawnPlayer)
    for key, player in pairs(self.players) do 
        if (player.entityId == entityId) then
            return player;
        end
    end
    if (bExcludeSpawnPlayer) then return end 
    for key, player in pairs(self.spawn_players) do 
        if (player.entityId == entityId) then
            return player;
        end
    end
end

-- 离线玩家是否可见
function PlayerManager:IsOfflinePlayerVisible()
    return self:IsPlayerVisible();
end

-- 所有玩家是否可见 排除主玩家
function PlayerManager:IsAllPlayerVisible()
    return self:IsUserVisible();
end

-- 是否玩家是否可见
function PlayerManager:IsVisible(player)
    local playerBX, playerBY, playerBZ = player:GetBlockPos();
    return self:IsInnerVisibleArea(playerBX, playerBY, playerBZ);
end

-- 是否在可视区
function PlayerManager:IsInnerVisibleArea(bx, by, bz)
    if (not self:GetMainPlayer()) then return false end
    local areaSize = math.floor(self:GetAreaSize() or 0);
    if (not areaSize or areaSize == 0) then return true end
    local mainPlayerBX, mainPlayerBY, mainPlayerBZ = self:GetMainPlayer():GetBlockPos();
    return math.abs(bx - mainPlayerBX) <= areaSize and math.abs(bz - mainPlayerBZ) <= areaSize;
end

-- 获取所有玩家
function PlayerManager:GetPlayers()
    local players = {};
    for username, player in pairs(self.players) do
        players[username] = player;
    end
    for username, player in pairs(self.spawn_players) do
        players[username] = player;
    end
    return players;
end

-- 移除所有玩家
function PlayerManager:ClearPlayers()
    local players = self:GetPlayers();
    for key, player in pairs(players) do 
        player:Destroy();
    end
    self.players = {};
    self.spawn_players = {};
end

-- 隐藏离线用户
function PlayerManager:HideOfflinePlayers()
    local players = self:GetPlayers();
    self:SetPlayerVisible(false);
    for _, player in pairs(players) do 
        if (not player:IsOnline()) then
            player:SetVisible(false);
        end
    end
end

-- 显示离线用户
function PlayerManager:ShowOfflinePlayers()
    local players = self:GetPlayers();
    self:SetPlayerVisible(true);
    for _, player in pairs(players) do 
        player:SetVisible(true);
    end
end

-- 所有用户
function PlayerManager:HideAllPlayers()
    local players = self:GetPlayers();
    self:SetUserVisible(false);
    for _, player in pairs(players) do 
        player:SetVisible(false);
    end
end

-- 显示所有用户
function PlayerManager:ShowAllPlayers()
    local players = self:GetPlayers();
    self:SetUserVisible(true);
    for _, player in pairs(players) do 
        player:SetVisible(true);
    end
end


function PlayerManager:EnableClickPlayer()
    self:SetCanClickPlayer(true);
end

function PlayerManager:DisableClickPlayer()
    self:SetCanClickPlayer(false);
end

function PlayerManager:SpawnPlayers(usernames)
    if (not self:IsCanSpawnPlayer()) then return end 

    local main_player = self:GetMainPlayer();
    local main_player_username = main_player and main_player:GetUserName();
    for _, username in ipairs(usernames or {}) do
        if (username ~= main_player_username) then
            if (not self.spawn_players[username] and not self.players[username]) then
                self:CreateSpawnPlayer(username);
            end
        end
    end
end

function PlayerManager:RemoveSpawnPlayer(username)
    local entity = self.spawn_players[username];
    if (not entity) then return end
    entity:SetName(nil);
    entity:Destroy();
    self.spawn_players[username] = nil;
end

function PlayerManager:CreateSpawnPlayer(username)
    local id = "kp" .. Encoding.base64(commonlib.Json.Encode({username = username}));
    local __self__ = self;
    -- 获取用户信息
    keepwork.user.getinfo({
        cache_policy = "access plus 0",
        router_params = {id = id},
    }, function(status, msg, data) 
        local userinfo = {};
        local playerinfo = {};
        if (status == 200) then userinfo = data end
        __self__.spawn_offline_user_count = __self__.spawn_offline_user_count + 1;
        local ParacraftPlayerEntityInfo = (userinfo.extra or {}).ParacraftPlayerEntityInfo or {};
        local scale = ParacraftPlayerEntityInfo.scale or 1;
        local asset = ParacraftPlayerEntityInfo.asset or "character/CC/02human/paperman/boy01.x";
        local skin = ParacraftPlayerEntityInfo.skin;
        playerinfo.state = "spawn";
        playerinfo.userinfo = {
            username = username,
            id = userinfo.id,
            isVip = userinfo.vip == 1,
            nickname = userinfo.nickname,
            schoolId = userinfo.schoolId or 0,
            school = (userinfo.school or {}).name,
            worldCount = (userinfo.rank or {}).world or 0,
        };
        local world = __self__:GetWorld();
        local entityId = 1000000 + __self__.spawn_offline_user_count;
        local EntityOtherPlayerClass = world:GetClient():GetEntityOtherPlayerClass();
        local entity = EntityOtherPlayerClass:new():init(world, username, entityId);
        entity:SetScaling(scale);
        entity:SetSkin(skin);
        entity:SetMainAssetPath(asset);
        entity:SetPlayerInfo(playerinfo);
        __self__.spawn_players[username] = entity;
        __self__:SendSyncSpawnPlayer();
        
    end);
end

function PlayerManager:SendSyncSpawnPlayer(spawn_players)
    
    if (not self:IsCanSpawnPlayer()) then return end 

    local world = self:GetWorld();
    if (not world) then return end 
    local netHandler = world:GetNetHandler();
    if (not netHandler) then return end 
    local packets = {};
    for username, entity in pairs(spawn_players or self.spawn_players) do
        packets[username] = entity:GetPacketPlayerEntityInfo():WritePacket();
    end

    return netHandler:AddToSendQueue(Packets.PacketGeneral:new():Init({
        action = "SyncSpawnPlayer",
        data = packets,
    }));
end

function PlayerManager:RecvSyncSpawnPlayer(packets)
    local world = self:GetWorld();
    if (not world) then return end 
    local EntityOtherPlayerClass = world:GetClient():GetEntityOtherPlayerClass();
    for username, entity_info in pairs(packets) do
        local entity = self.spawn_players[username];
        if (not entity) then
            entity = EntityOtherPlayerClass:new():init(world, username, entity_info.entityId);
            self.spawn_players[username] = entity;
        end
        local packet = Packets.PacketPlayerEntityInfo:new();
        packet:ReadPacket(entity_info);
        entity:UpdatePlayerEntityInfo(packet);
    end
    local delete_players = {};
    for username in pairs(self.spawn_players) do
        if (not packets[username]) then
            delete_players[username] = true;
        end
    end
    for username in pairs(delete_players) do
        self:RemoveSpawnPlayer(username);
    end
end

function PlayerManager:Tick()
    self:SendSyncSpawnPlayer();
end

