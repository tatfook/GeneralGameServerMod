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

require("Net");

local NetState = module();

local __state__ = NewScope();

local SYNC_STATE = "NET_SYNC_STATE";
local AUTO_SYNC_STATE = "NET_AUTO_SYNC_STATE";

local __is_enable_auto_sync_state__ = true;
local __sync_key_val_list__ = {};
__state__:__set_newindex_callback__(function(scope, key, newval, oldval)
    if (not __is_enable_auto_sync_state__) then return end 

    local keys = scope:__get_keys__(key);
    keys.size = #keys;
    keys.value = newval;
    __sync_key_val_list__[#__sync_key_val_list__ + 1] = keys;
end);

local __cache_list__ = {size = 0};
RegisterTimerCallBack(function()
    if (not __is_enable_auto_sync_state__) then return end 
    
    local size = #__sync_key_val_list__;
    local cache_size = #__cache_list__;
    for i = 1, cache_size do __cache_list__[i] = nil end
    for i = 1, size do
        __cache_list__[i] = __sync_key_val_list__[i];
        __sync_key_val_list__[i] = nil;
    end

    __cache_list__.action = AUTO_SYNC_STATE;
    __cache_list__.size = size;
    
    if (size == 0) then return end 
    -- log("同步Net STATE", __cache_list__)
    
    local __NetSend__ = NetSend;
    RPC_Call("SetStateData", __cache_list__, function()
        __NetSend__(__cache_list__);
    end);
end);

local function AutoSyncState(msg)
    __is_enable_auto_sync_state__= false;
    local keys_list = msg;
    local keys_list_size = keys_list.size;
    for i = 1, keys_list_size do
        local keys = keys_list[i];
        local size, value = keys.size, keys.value;
        local state = __state__;
        for j = 1, size - 1 do
            local key = keys[j];
            if (not state:__is_scope__(state:Get(key))) then state:Set(key, NewScope()) end
            state = state:Get(key);
        end
        state:Set(keys[size], value);
    end
    __is_enable_auto_sync_state__= true;
end

local function RecvSyncState(key, value)
    __is_enable_auto_sync_state__= false;
    if (key) then
        __state__:Set(key, value);
    else
        for k, v in pairs(value) do
            __state__:Set(k, v);
        end
    end
    __is_enable_auto_sync_state__= true;
end

local function SendSyncState(key, value)
    key = key or UUID();
    value = value == nil and {} or value;

    RecvSyncState(key, value);

    local __NetSend__ = NetSend;
    RPC_Call("SetStateData", {
        size = 1,
        [1] = {
            [1] = key, 
            size = 1,
            value = value,
        }
    }, function()
        __NetSend__({
            action = SYNC_STATE,
            key = key, value = value,
        });
    end);
end

-- 收到数据
NetOnRecv(function(msg)
    local action = msg.action;
    if (action == SYNC_STATE) then return RecvSyncState(msg.key, msg.value) end
    if (action == AUTO_SYNC_STATE) then return AutoSyncState(msg) end
end);

NetConnect(function()
    local is_sleep = true;
    RPC_Call("StateData", nil, function(state)
        __is_enable_auto_sync_state__ = false;
        for key, val in pairs(state) do __state__:Set(key, val) end 
        __is_enable_auto_sync_state__ = true;
        is_sleep = false;
    end);

    while(is_sleep) do sleep() end 
end);

-- ==================================================API===============================================
function NetInitState(key, init_value)
    key = key or UUID();
    init_value = init_value == nil and {} or init_value;

    local value = __state__:Get(key);
    -- 已存在值, 表明已初始化
    if (value ~= nil) then return value end 
    
    local wait_time, wait_total_time = 300, nil;
    while (true) do
        -- 等待时间过长, 自己尝试上锁
        if (not wait_total_time or wait_total_time > 5000) then
            wait_total_time = 0;
            if (NetLock()) then 
                SendSyncState(key, init_value);
                NetUnlock(); 
            end
        end
        
        value = __state__:Get(key);
        if (value ~= nil) then return value end 

        sleep(wait_time);
        wait_total_time = wait_total_time + wait_time;
    end
    
    return value;
end
