--[[
Title: GGS
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local GGS = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/GGS.lua");
------------------------------------------------------------
]]
local State = require("State");

local GGS = inherit(ToolBase, module("GGS"));

GGS:Property("ConnectCallBack");
GGS:Property("DisconnectCallBack");
GGS:Property("RecvCallBack");
GGS:Property("AutoSyncState", false, "IsAutoSyncState");

local GGS_STATE_KEY = "__GGS_STATE__";  -- 
local username = GetUserName();
local players = {};
local isConnecting = false;

State:Set(GGS_STATE_KEY, {});
local GGS_State = State:Get(GGS_STATE_KEY);

local __sync_key_val_list__ = {};

GGS_State:__set_newindex_callback__(function(scope, key, newval, oldval)
    if (not GGS:IsAutoSyncState()) then return end 

    local keys = scope:__get_keys__(key);
    keys.size = #keys;
    keys.value = newval;
    __sync_key_val_list__[#__sync_key_val_list__ + 1] = keys;
end);

local __cache_list__ = {size = 0};
RegisterTimerCallBack(function()
    local size = #__sync_key_val_list__;
    for i = 1, __cache_list__.size do __cache_list__[i] = nil end
    for i = 1, size do
        __cache_list__[i] = __sync_key_val_list__[i];
        __sync_key_val_list__[i] = nil;
    end

    __cache_list__.action = "sync_state";
    __cache_list__.size = size;
    
    if (size == 0) then return end 

    GGS:Send(__cache_list__);
end);

function GGS:GetState()
    return GGS_State;
end

function GGS:Connect(callback)
    GGS_Connect(function()
        isConnecting = true;
        GGS_Send({action = "join", username = username});

        callback = callback or self:GetConnectCallBack();
        if (type(callback) == "function") then callback() end
    end);
end

function GGS:IsConnecting()
    return isConnecting;
end

function GGS:Send(data)
    return GGS_Send(data);
end

function GGS:Disconnect()
    return GGS_Disconnect();
end

function GGS:OnRecv(callback)
    self:SetRecvCallBack(callback);
end

function GGS:GetAllPlayer()
    return players;
end

function GGS:GetPlayer(username)
    return players[username or ""];
end

local function SyncState(data)
    echo(data, true);
    local IsAutoSyncState = GGS:IsAutoSyncState();
    GGS:SetAutoSyncState(false);
    local size = data.size;
    for i = 1, size do
        local key_val_item = data[i];
        local item_size, value = key_val_item.size, key_val_item.value;
        local state = State:GetScope();
        for j = 1, item_size - 1 do
            local key = key_val_item[j];
            if (not State:IsScope(state:Get(key))) then state:Set(key, NewScope()) end
            state = state:Get(key);
        end
        state:Set(key_val_item[item_size], value);
    end
    GGS:SetAutoSyncState(IsAutoSyncState);
end

local function PlayerJoin(msg)
    local username = msg.username;
    Tip(string.format("玩家[%s]加入", username));
    players[username] = {
        username = username,
    }
end

local function PlayerExit(username)
    Tip(string.format("玩家[%s]退出", username));

    players[username] = username;
end

local function MainPlayerExit()
    isConnecting = false;
    GetPlayer():UpdateDisplayName();   -- 清除用户名
end

GGS_Recv(function(msg)
    local action = msg.action;
    if (action == "join") then return PlayerJoin(msg) end

    if (action == "sync_state") then return SyncState(msg) end 

    local callback = self:GetRecvCallBack();
    if (type(callback) == "function") then callback(msg) end
end)

GGS_Disconnect(function(username)
    if (not username) then
        -- 主玩家断开
        MainPlayerExit();
    else
        -- 其它玩家断开
        PlayerExit(username);
    end

    local callback = GGS:GetDisconnectCallBack();
    if (type(callback) == "function") then callback(username) end
end);

GGS:InitSingleton();