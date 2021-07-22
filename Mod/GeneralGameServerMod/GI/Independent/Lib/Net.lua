--[[
Title: Net
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local Net = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/Net.lua");
------------------------------------------------------------
]]
local RPC = require("RPC");

local Net = inherit(ToolBase, module("Net"));

Net:Property("Connected", false, "IsConnected");    -- 是否连接成功
Net:Property("Connecting", false, "IsConnecting");  -- 是否正在连接

local __username__ = GetUserName();
local __connection__ = RPC;

Net.EVENT_TYPE = {
    CONNECTED = "NET_CONNECTED",
    CONNECT_CLOSED = "NET_CONNECT_CLOSED",
}

-- 构造函数
function Net:ctor()
end

-- 连接
function Net:Connect(callback)
    -- 注册连接事件
    self:OnConnect(callback);

    -- 已经连接直接执行返回
    if (self:IsConnected()) then return type(callback) == "function" and callback() end

    -- 连接中则等待
    if (self:IsConnecting()) then
        -- 阻塞当前执行流程
        while(not self:IsConnected()) do sleep() end
        return;   
    end

    -- 标记正在连接
    self:SetConnecting(true);

    -- 进行登录连接
    __connection__:Connect(function(data)
        self:SetConnected(true);
        self:SetConnecting(false);
        TriggerEventCallBack(Net.EVENT_TYPE.CONNECTED, data);
    end);

    -- 阻塞当前执行流程
    while(not self:IsConnected()) do sleep() end

    return;
end

-- 发送
function Net:Send(data)
    __connection__:Send(data);
end

-- 发送指定用户
function Net:SendTo(username, data)
    __connection__:SendTo(username, data);
end

-- 接收
function Net:OnRecv(callback)
    __connection__:OnRecv(callback);
end

-- 断开
function Net:OnDisconnect(callback)
    __connection__:OnDisconnect(callback)
end

-- 连接
function Net:OnConnect(callback)
    RegisterEventCallBack(Net.EVENT_TYPE.CONNECTED, callback);
end

function Net:OnClosed(callback)
    __connection__:OnClosed(callback);
end

function Net:OnNetClosed(callback)
    __connection__:OnNetClosed(callback);
end

function Net:SetUserData(userdata)
    __connection__:SetUserData(userdata);
end

function Net:GetUserData()
    return __connection__:GetUserData();
end

function Net:GetAllUserData()
    return __connection__:GetAllUserData();
end

function Net:OnUserData(...)
    __connection__:OnUserData(...);
end

function Net:SetShareData(sharedata)
    __connection__:SetShareData(sharedata);
end

function Net:GetShareData()
    return __connection__:GetShareData();
end

function Net:OnShareDataItem(key, callback)
    __connection__:OnShareDataItem(key, callback);
end

function Net:OnShareData(...)
    __connection__:OnShareData(...);
end

Net:InitSingleton():Connect(function(data)
    log("=================net connect success=============", data)
end);


