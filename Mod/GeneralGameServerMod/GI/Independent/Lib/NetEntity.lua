--[[
Title: NetEntity
Author(s):  wxa
Date: 2021-06-01
Desc: Net 玩家实体类
use the lib:
------------------------------------------------------------
local NetEntity = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/NetEntity.lua");
------------------------------------------------------------
]]

local Net = require("Net");
local NetPlayer = require("NetPlayer");
local KeyBoard = require("KeyBoard");

local NetEntity = inherit(ToolBase, module("NetEntity"));

NetEntity:InitSingleton();

local __username__ = GetUserName();
local __player_entity_map__ = {};
local __cur_main_player_entity__ = GetPlayer();
local __main_player_entity__ = nil;

Net.EVENT_TYPE.SET_PLAYER_ENTITY_INFO = "__set_player_entity_info__";
Net.EVENT_TYPE.SET_PLAYER_ENTITY_DATA_INFO = "__set_player_entity_data_info__";

local function GetPlayerEntity(username)
    username = username or __username__;
    local entity_player = __player_entity_map__[username];
    if (entity_player) then return entity_player end 

    local create_player_entity = CreatePlayerEntity;
    if (type(__create_player_entity__) == "function") then create_player_entity = __create_player_entity__ end 

    entity_player = create_player_entity(username);  
    __player_entity_map__[username] = entity_player;
    return entity_player;
end

local function RemovePlayerEntity(username)
    username = username or __username__;
    local entity_player = GetPlayerEntity(username);
    entity_player:Destroy();
    __player_entity_map__[username] = nil;
end

local function GetPlayerEntityInfo(username)
    local entity_player = GetPlayerEntity(username);
    local info = {};

    info.x, info.y, info.z = entity_player:GetPosition();
    info.watcher_data = entity_player:GetWatcherData();

    return info;
end

local function SetPlayerEntityInfo(msg)
    local username, info = msg.username, msg.data;
    if (not username or not info) then return end 
    local entity_player = GetPlayerEntity(username);
    if (info.x) then entity_player:SetPosition(info.x, info.y, info.z) end
    entity_player:LoadWatcherData(info.watcher_data);
end

local function SetPlayerEntityDataInfo(msg)
    local username, data = msg.username, msg.data;
    if (not username or not data) then return end
    local entity_player = GetPlayerEntity(username);
    entity_player:LoadWatcherData(data);
end

local function SyncPlayerEntityDataInfo(data)
    Net:Send({
        action = Net.EVENT_TYPE.SET_PLAYER_ENTITY_DATA_INFO,
        username = __username__,
        data = data,
    });
end

NetPlayer:OnMainPlayerLogin(function(player)
    if (__main_player_entity__) then return end 

    __main_player_entity__ = GetPlayerEntity(player.username);
    __main_player_entity__:SetFocus();
    __main_player_entity__:OnWatcherDataChange(SyncPlayerEntityDataInfo);
    __cur_main_player_entity__:SetVisible(false);
    DisableDefaultWASDKey();

    -- 主玩家登录给所有其它玩家发送自己的所有信息
    Net:Send({
        action = Net.EVENT_TYPE.SET_PLAYER_ENTITY_INFO,
        username = __username__,
        data = GetPlayerEntityInfo();
    })
end);

NetPlayer:OnPlayerLogin(function(player)
    -- 玩家登录给其发送完整的当前玩家信息
    Net:SendTo(player.username, {
        action = Net.EVENT_TYPE.SET_PLAYER_ENTITY_INFO,
        username = __username__,
        data = GetPlayerEntityInfo(),
    });
end);

NetPlayer:OnPlayerLogout(function(player)
    RemovePlayerEntity(player.username);
end);

NetPlayer:OnMainPlayerLogout(function(player)
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
Net:OnRecv(function(msg)
    local action = msg.action;
    if (action == Net.EVENT_TYPE.SET_PLAYER_ENTITY_INFO) then return SetPlayerEntityInfo(msg) end
    if (action == Net.EVENT_TYPE.SET_PLAYER_ENTITY_DATA_INFO) then return SetPlayerEntityDataInfo(msg) end 
end);

Net:OnClosed(function()
    for _, entity in pairs(__player_entity_map__) do
        entity:Destroy();
    end
    __player_entity_map__ = {};
end);