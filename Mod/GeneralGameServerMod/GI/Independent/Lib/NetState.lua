--[[
Title: NetState
Author(s):  wxa
Date: 2021-06-01
Desc: 排行榜
use the lib:
------------------------------------------------------------
local NetState = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/NetState.lua");
------------------------------------------------------------
]]

local Net = require("Net");
local NetState = inherit(ToolBase, module("NetState"));

NetState:Property("AutoSyncState", true, "IsAutoSyncState");

local __username__ = GetUserName();
local __states__ = NewScope();
local __state__ = __states__:Get(__username__, {});            -- 用户独立数据 

Net.EVENT_TYPE.REQUEST_SYNC_STATE = "Net_REQUEST_SYNC_STATE";
Net.EVENT_TYPE.RESPONSE_SYNC_STATE = "Net_RESPONSE_SYNC_STATE";
Net.EVENT_TYPE.AUTO_SYNC_STATE = "Net_AUTO_SYNC_STATE";

local __sync_key_val_list__ = {};
__states__:__set_newindex_callback__(function(scope, key, newval, oldval)
    if (not Net:IsConnected() or not NetState:IsAutoSyncState()) then return end 

    local keys = scope:__get_keys__(key);
    keys.size = #keys;
    keys.value = newval;
    __sync_key_val_list__[#__sync_key_val_list__ + 1] = keys;
end);

local __cache_list__ = {size = 0};
RegisterTimerCallBack(function()
    if (not Net:IsConnected() or not NetState:IsAutoSyncState()) then return end 
    
    local size = #__sync_key_val_list__;
    local cache_size = #__cache_list__;
    for i = 1, cache_size do __cache_list__[i] = nil end
    for i = 1, size do
        __cache_list__[i] = __sync_key_val_list__[i];
        __sync_key_val_list__[i] = nil;
    end

    __cache_list__.action = Net.EVENT_TYPE.AUTO_SYNC_STATE;
    __cache_list__.size = size;
    
    if (size == 0) then return end 
    -- log("同步Net STATE", __cache_list__)
    Net:Send(__cache_list__);
end);

local function AutoSyncState(msg)
    NetState:SetAutoSyncState(false);
    local keys_list = msg;
    local keys_list_size = keys_list.size;
    for i = 1, keys_list_size do
        local keys = keys_list[i];
        local size, value = keys.size, keys.value;
        local state = __states__;
        for j = 1, size - 1 do
            local key = keys[j];
            if (not state:__is_scope__(state:Get(key))) then state:Set(key, NewScope()) end
            state = state:Get(key);
        end
        state:Set(keys[size], value);
    end
    NetState:SetAutoSyncState(true);
end

local function RequestSyncState(msg)
    local username, state = msg.username, msg.state;

    NetState:SetAutoSyncState(false);
    __states__:Set(username, state);
    NetState:SetAutoSyncState(true);

    Net:SendTo(username, {
        action = Net.EVENT_TYPE.RESPONSE_SYNC_STATE,
        username = __username__,
        state = __state__:ToPlainObject(),
    });
end

local function ResponseSyncState(msg)
    local username, state = msg.username, msg.state;

    NetState:SetAutoSyncState(false);
    __states__:Set(username, state);
    NetState:SetAutoSyncState(true);
end

function NetState:Init()
    return self;
end

function NetState:GetUserState(username)
    return (not username or username == __username__) and __state__ or __states__:Get(username, {});
end

function NetState:GetAllUserState()
    return __states__;
end

function NetState:Get(key, default_value)
    return __state__:Get(key, default_value)
end

function NetState:Set(key, value)
    return __state__:Set(key, value)
end

NetState:InitSingleton():Init();

-- 收到数据
Net:OnRecv(function(msg)
    local action = msg.action;
    if (action == Net.EVENT_TYPE.REQUEST_SYNC_STATE) then return RequestSyncState(msg) end
    if (action == Net.EVENT_TYPE.RESPONSE_SYNC_STATE) then return ResponseSyncState(msg) end
    if (action == Net.EVENT_TYPE.AUTO_SYNC_STATE) then return AutoSyncState(msg) end
end);

-- 连接
Net:Connect(function()
    -- 发送状态
    Net:Send({
        action = Net.EVENT_TYPE.REQUEST_SYNC_STATE, 
        username = __username__,
        state = __state__:ToPlainObject(),
    });
end); 

