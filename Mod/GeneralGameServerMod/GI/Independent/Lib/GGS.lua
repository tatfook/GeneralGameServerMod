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
local GGS = inherit(ToolBase, module("GGS"));

GGS:Property("Connected", false, "IsConnected");    -- 是否连接成功
GGS:Property("Connecting", false, "IsConnecting");  -- 是否正在连接

local __username__ = GetUserName();
local __all_user_data__ = {};
local __share_data__ = {};
local __msg_event_emitter__ = EventEmitter:new();
local __share_data_event_emitter__ = EventEmitter:new();

GGS.EVENT_TYPE = {
    CONNECT = "GGS_CONNECT",
    DISCONNECT = "GGS_DISCONNECT",
    RECV = "GGS_RECV",
    USER_DATA = "GGS_USER_DATA",
    SHARE_DATA = "GGS_SHARE_DATA",
}

local function SetUserData(username, data)
    __all_user_data__[username] = __all_user_data__[username] or {};
    partialcopy(__all_user_data__[username], data);
    __all_user_data__[username].__username__ = username;
    TriggerEventCallBack(GGS.EVENT_TYPE.USER_DATA, __all_user_data__[username]);
end

local function SetAllUserData(data)
    if (not data) then return end
    for username, userdata in pairs(data) do
        SetUserData(username, userdata);
    end
end

local function PushUserData(data)
    SetUserData(__username__, data);
    GGS_Send(data, nil, "__push_user_data__");
end

local function SetShareData(data)
    if (type(data) ~= "table") then return end 
    for key, val in pairs(data) do
        local old_val = __share_data__[key];
        __share_data__[key] = val;
        -- 触发数据项更新
        __share_data_event_emitter__:TriggerEventCallBack(key, val, old_val);
    end
    -- 触发整体事件更新
    TriggerEventCallBack(GGS.EVENT_TYPE.SHARE_DATA, __share_data__);
end

local function PushShareData(data)
    SetShareData(data);
    GGS_Send(data, nil, "__push_share_data__");
end

local function PullAllUserData()
    GGS_Send(nil, nil, "__pull_all_user_data__");  -- __push_all_user_data__
end

function GGS:Init()
    GGS:SetConnected(false);

    return self;
end

function GGS:Connect(callback)
    if (self:IsConnected()) then return type(callback) == "function" and callback() end

    if (self:IsConnecting()) then
        -- 阻塞当前执行流程
        while(not GGS:IsConnected()) do sleep() end
        return type(callback) == "function" and callback();
    end

    -- 标记正在连接
    self:SetConnecting(true);
    
    -- 进行协议连接
    GGS_Connect(function()
        -- 发送逻辑连接消息
        GGS_Send(nil, nil, "__request_connect__");
    end);

    -- 阻塞当前执行流程
    while(not GGS:IsConnected()) do sleep() end
    return type(callback) == "function" and callback();
end

function GGS:Send(data)
    if (not GGS:IsConnected()) then return end 
    return GGS_Send(data);
end

function GGS:SendTo(username, data)
    if (not GGS:IsConnected()) then return end 
    return GGS_Send(data, username);
end

function GGS:SetUserData(data)
    PushUserData(data);
end

function GGS:GetUserData(username)
    username = username or __username__;
    __all_user_data__[username] = __all_user_data__[username] or {};
    return __all_user_data__[username];
end

function GGS:Emit(msgType, msgData)
    __msg_event_emitter__:TriggerEventCallBack(msgType, msgData); -- 触发自身事件回调
    GGS_Send({msgType = msgType, msgData = msgData}, nil, "__message__");
end

function GGS:On(msgType, callback)
    __msg_event_emitter__:RegisterEventCallBack(msgType, callback);
end

function GGS:Off(msgType, callback)
    __msg_event_emitter__:RemoveEventCallBack(msgType, callback);
end

function GGS:GetShareData()
    return __share_data__;
end

function GGS:SetShareData(data)
    PushShareData(data);
end

function GGS:GetAllUserData()
    return __all_user_data__;
end

function GGS:Disconnect()
    return GGS_Disconnect();
end

function GGS:OnConnect(callback)
    RegisterEventCallBack(GGS.EVENT_TYPE.CONNECT, callback);
end
function GGS:OnRecv(callback)
    RegisterEventCallBack(GGS.EVENT_TYPE.RECV, callback);
end
function GGS:OnUserData(callback)
    RegisterEventCallBack(GGS.EVENT_TYPE.USER_DATA, callback);
end
function GGS:OnShareData(callback)
    RegisterEventCallBack(GGS.EVENT_TYPE.SHARE_DATA, callback);
end
function GGS:OnShareDataItem(key, callback)
    __share_data_event_emitter__:RegisterEventCallBack(key, callback);
end
function GGS:OnDisconnect(callback)
    RegisterEventCallBack(GGS.EVENT_TYPE.DISCONNECT, callback);
end

GGS_Recv(function(msg)
    local __action__, __username__, __data__ = msg.__action__, msg.__username__, msg.__data__;

    if (__action__ == "__response_connect__") then 
        GGS:SetConnected(true);
        GGS:SetConnecting(false);
        SetAllUserData(__data__.__all_user_data__);
        SetShareData(__data__.__share_data__);
        TriggerEventCallBack(GGS.EVENT_TYPE.CONNECT);
    elseif (__action__ == "__push_share_data__") then 
        SetShareData(__data__);
    elseif (__action__ == "__push_user_data__") then 
        SetUserData(__username__, __data__);
    elseif (__action__ == "__push_all_user_data__") then 
        SetAllUserData(__data__);
    elseif (__action__ == "__message__") then
        __msg_event_emitter__:TriggerEventCallBack(__data__.msgType, __data__.msgData);
    else
        TriggerEventCallBack(GGS.EVENT_TYPE.RECV, __data__);
    end
end)

GGS_Disconnect(function(username)
    if (not username or username == __username__) then 
        GGS:SetConnected(false);
    else
        GGS:GetUserData(username).__is_online__ = false;
    end
    TriggerEventCallBack(GGS.EVENT_TYPE.DISCONNECT, username or __username__);
end)

GGS:InitSingleton():Init():Connect(function()
    -- print("=======================GGS Connect Success======================", GetUserName())
end);

