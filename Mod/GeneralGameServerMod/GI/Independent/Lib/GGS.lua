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

GGS:Property("AutoSyncState", true, "IsAutoSyncState");

local __username__ = GetUserName();
local __players__ = {};

local GGS_STATE_KEY = "__GGS_STATE__";  -- 
local isConnecting = false;

local GGS_EVENT_TYPE = {
    CONNECT = "GGS_CONNECT",
    DISCONNECT = "GGS_DISCONNECT",
    RECV = "GGS_RECV",

    PLAYER_JOIN = "GGS_PLAYER_JOIN",
    PLAYER_EXIT = "GGS_PLAYER_EXIT",

    JOIN = "GGS_JOIN",
    SYNC_STATE = "GGS_SYNC_STATE",
    AUTO_SYNC_STATE = "GGS_AUTO_SYNC_STATE",
}

local GGS_State = State:Get(GGS_STATE_KEY, {});
local GGS_UserState = GGS_State:Get(__username__, {});

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

    __cache_list__.action = GGS_EVENT_TYPE.AUTO_SYNC_STATE;
    __cache_list__.size = size;
    
    if (size == 0) then return end 
    -- log("同步GGS STATE", __cache_list__)
    GGS:Send(__cache_list__);
end);

local function AutoSyncState(data)
    if (not isConnecting) then return end
    -- log("收到状态同步: ", data)
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
    -- Tip(string.format("玩家[%s]加入", username));
    __players__[username] = {
        username = username,
        join_time = GetTime(),
    }
    local state = msg.state or {};
    local IsAutoSyncState = GGS:IsAutoSyncState();

    -- 用户加入同步
    GGS:SetAutoSyncState(false);
    GGS_State:Set(username, state);
    GGS:SetAutoSyncState(IsAutoSyncState);

    TriggerEventCallBack(GGS_EVENT_TYPE.PLAYER_JOIN, __players__[username]);
end

local function PlayerExit(username)
    if (not __players__[username]) then return end 
    TriggerEventCallBack(GGS_EVENT_TYPE.PLAYER_EXIT, __players__[username]);

    -- Tip(string.format("玩家[%s]退出", username));
    __players__[username] = nil;
end

local function MainPlayerJoin()
    __players__[__username__] = {username = __username__, join_time = GetTime()};
end

local function MainPlayerExit()
    isConnecting = false;
    -- GetPlayer():UpdateDisplayName();   -- 清除用户名
end

GGS_Recv(function(msg)
    -- log(msg)
    local action = msg.action;
    if (action == GGS_EVENT_TYPE.JOIN) then return PlayerJoin(msg) end
    if (action == GGS_EVENT_TYPE.AUTO_SYNC_STATE) then return AutoSyncState(msg) end 
    if (action == GGS_EVENT_TYPE.SYNC_STATE) then GGS:RecvSyncState(msg) end

    TriggerEventCallBack(GGS_EVENT_TYPE.RECV, msg);
end)

GGS_Disconnect(function(username)
    if (not username or username == __username__) then
        -- 主玩家断开
        MainPlayerExit();
    else
        -- 其它玩家断开
        PlayerExit(username);
    end

    TriggerEventCallBack(GGS_EVENT_TYPE.DISCONNECT, username);
end);


function GGS:GetState()
    return GGS_State;
end

function GGS:Get(key, default_value)
    return GGS_State:Get(key, default_value)
end

function GGS:Set(key, value)
    return GGS_State:Set(key, value)
end

function GGS:OnSyncState(callback)
    RegisterEventCallBack(GGS_EVENT_TYPE.SYNC_STATE, callback);
end

function GGS:SendSyncState(state)
    local keys = state:__get_keys__();
    keys.size = #keys;
    keys.value = state:ToPlainObject();
    keys.action = GGS_EVENT_TYPE.SYNC_STATE;
    self:Send(keys);
end

function GGS:SyncState(keys, value)
    local IsAutoSyncState = GGS:IsAutoSyncState();
    GGS:SetAutoSyncState(false);
    value = value or keys.value;
    local state = State:GetScope();
    local size = keys.size or #keys;
    for i = 1, size - 1 do
        state = state:Get(keys[i]);
    end
    state:Set(keys[size], value);
    GGS:SetAutoSyncState(IsAutoSyncState);
end

function GGS:RecvSyncState(msg)
    if (msg.action ~= GGS_EVENT_TYPE.SYNC_STATE) then return end
    self:SyncState(msg, msg.value);
    TriggerEventCallBack(GGS_EVENT_TYPE.SYNC_STATE, msg, 1, 2,3);
end

function GGS:Connect(callback)
    if (isConnecting) then return type(callback) == "function" and callback() end

    GGS_Connect(function()
        isConnecting = true;
        GGS_Send({
            action = GGS_EVENT_TYPE.JOIN, 
            username = __username__,
            state = GGS_UserState:ToPlainObject(),
        });
        MainPlayerJoin();
        if (type(callback) == "function") then callback() end
        TriggerEventCallBack(GGS_EVENT_TYPE.CONNECT);
    end);
end

function GGS:IsConnecting()
    return isConnecting;
end

function GGS:Send(data)
    if (not isConnecting) then return end 
    return GGS_Send(data);
end

function GGS:SendTo(username, data)
    if (not isConnecting) then return end 
    return GGS_SendTo(username, data);
end

function GGS:Disconnect()
    return GGS_Disconnect();
end

function GGS:OnConnect(callback)
    RegisterEventCallBack(GGS_EVENT_TYPE.CONNECT, callback);
end
function GGS:OnRecv(callback)
    RegisterEventCallBack(GGS_EVENT_TYPE.RECV, callback);
end
function GGS:OnDisconnect(callback)
    RegisterEventCallBack(GGS_EVENT_TYPE.DISCONNECT, callback);
end

function GGS:GetAllPlayer()
    return __players__;
end

function GGS:GetPlayer(username)
    return __players__[username or ""];
end

GGS:InitSingleton();