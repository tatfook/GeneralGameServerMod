--[[
Title: GGSPlayerManager
Author(s):  wxa
Date: 2021-06-01
Desc: GGS 玩家管理
use the lib:
------------------------------------------------------------
local GGSPlayerManager = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/GGSPlayerManager.lua");
------------------------------------------------------------
]]

local GGS = require("GGS");
local GGSPlayer = require("GGSPlayer");
local KeyBoard = require("KeyBoard");

local GGSPlayerManager = inherit(ToolBase, module("GGSPlayerManager"));

local __username__ = GetUserName();
local __player_entity_map__ = {};
local __cur_main_player_entity__ = GetPlayer();
local __main_player_entity__ = nil;

GGS.EVENT_TYPE.SET_PLAYER_ENTITY_INFO = "__set_player_entity_info__";
GGS.EVENT_TYPE.SET_PLAYER_ENTITY_DATA_INFO = "__set_player_entity_data_info__";


local function GetPlayerEntity(username, isCreateNotExist)
    username = username or __username__;
    local entity_player = __player_entity_map__[username];
    if (entity_player) then return entity_player end 

    if (not isCreateNotExist) then return nil end
    entity_player = CreatePlayer(username);  
    __player_entity_map__[username] = entity_player;
    return entity_player;
end

local function CreatePlayerEntity(username)
    return GetPlayerEntity(username, true);
end

local function RemovePlayerEntity(username)
    username = username or __username__;
    local entity_player = __player_entity_map__[username];
    if (not entity_player) then return end
    __player_entity_map__[username] = nil;
    entity_player:Destroy();
end

local function GetPlayerEntityInfo(username)
    local entity_player = GetPlayerEntity(username, true);
    local info = {};

    info.x, info.y, info.z = entity_player:GetPosition();
    info.watcher_data = entity_player:GetWatcherData();

    return info;
end

local function SetPlayerEntityInfo(msg)
    local username, info = msg.username, msg.data;
    if (not username or not info) then return end 

    local entity_player = GetPlayerEntity(username, true);

    if (info.x) then entity_player:SetPosition(info.x, info.y, info.z) end
    entity_player:LoadWatcherData(info.watcher_data);
end

local function SetPlayerEntityDataInfo(msg)
    local username, data = msg.username, msg.data;
    echo(msg, true)
    if (not username or not data) then return end
    local entity_player = GetPlayerEntity(username);
    entity_player:LoadWatcherData(data);
end

local function SyncPlayerEntityDataInfo(data)
    GGS:Send({
        action = GGS.EVENT_TYPE.SET_PLAYER_ENTITY_DATA_INFO,
        username = __username__,
        data = data,
    });
end

GGSPlayer:OnMainPlayerLogin(function(player)
    if (__main_player_entity__) then return end 

    __main_player_entity__ = CreatePlayerEntity(player.username);
    __main_player_entity__:SetFocus();
    __main_player_entity__:OnWatcherDataChange(SyncPlayerEntityDataInfo);
    __cur_main_player_entity__:SetVisible(false);
    DisableDefaultWASDKey();

    -- 主玩家登录给所有其它玩家发送自己的所有信息
    GGS:Send({
        action = GGS.EVENT_TYPE.SET_PLAYER_ENTITY_INFO,
        username = __username__,
        data = GetPlayerEntityInfo();
    })
end);

GGSPlayer:OnPlayerLogin(function(player)
    local username = player.username;
    CreatePlayerEntity(username);

    -- 玩家登录给其发送完整的当前玩家信息
    GGS:SendTo(username, {
        action = GGS.EVENT_TYPE.SET_PLAYER_ENTITY_INFO,
        username = __username__,
        data = GetPlayerEntityInfo(),
    });
end);

GGSPlayer:OnPlayerLogout(function(player)
    RemovePlayerEntity(player.username);
end);

GGSPlayer:OnMainPlayerLogout(function(player)
    RemovePlayerEntity(player.username);
    __main_player_entity__ = nil;
    __cur_main_player_entity__:SetVisible(true);
    __cur_main_player_entity__:SetFocus();
    EnableDefaultWASDKey();
end);

-- 玩家移动控制
KeyBoard:OnKeyDown("w", function()
    if (not __main_player_entity__) then return end 
    __main_player_entity__:SetWKeyPressed(true);
end);

KeyBoard:OnKeyUp("w", function()
    if (not __main_player_entity__) then return end 
    __main_player_entity__:SetWKeyPressed(false);
end);

KeyBoard:OnKeyDown("a", function()
    if (not __main_player_entity__) then return end 
    __main_player_entity__:SetAKeyPressed(true);
end);

KeyBoard:OnKeyUp("a", function()
    if (not __main_player_entity__) then return end 
    __main_player_entity__:SetAKeyPressed(false);
end);

KeyBoard:OnKeyDown("s", function()
    if (not __main_player_entity__) then return end 
    __main_player_entity__:SetSKeyPressed(true);
end);

KeyBoard:OnKeyUp("s", function()
    if (not __main_player_entity__) then return end 
    __main_player_entity__:SetSKeyPressed(false);
end);

KeyBoard:OnKeyDown("d", function()
    if (not __main_player_entity__) then return end 
    __main_player_entity__:SetDKeyPressed(true);
end);

KeyBoard:OnKeyUp("d", function()
    if (not __main_player_entity__) then return end 
    __main_player_entity__:SetDKeyPressed(false);
end);

-- 收到数据
GGS:OnRecv(function(msg)
    local action = msg.action;
    if (action == GGS.EVENT_TYPE.SET_PLAYER_ENTITY_INFO) then return SetPlayerEntityInfo(msg) end
    if (action == GGS.EVENT_TYPE.SET_PLAYER_ENTITY_DATA_INFO) then return SetPlayerEntityDataInfo(msg) end 
end);