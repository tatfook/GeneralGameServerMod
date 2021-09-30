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
local __msg_event_emitter__ = EventEmitter:new();
local __connection__ = RPC;
local __control_server_ip__ = IsDevEnv and "127.0.0.1" or "ggs.keepwork.com";
local __control_server_port = IsDevEnv and "9000" or "9000";
local __worker_server_ip__, __worker_server_ip__ = nil, nil;

Net.EVENT_TYPE = {
    CONNECTED = "NET_CONNECTED",
    CONNECT_CLOSED = "NET_CONNECT_CLOSED",
    MSG = "NET_MSG",
}

local function SelectWorldServer(callback, try_wait_time)
    -- print("========================SelectWorldServer=============================", __coroutine_running__());

    try_wait_time = try_wait_time or 10000;
    local function error_handle()
        fatal("Unable to get server address");
        sleep(try_wait_time);
        try_wait_time = try_wait_time + try_wait_time;
        SelectWorldServer(callback, try_wait_time);
    end

    GetNetAPI():Get("__server_manager__/__select_world_server__", {
        worldId = GetWorldId(),
    }):Then(function(msg)
        if (msg.status ~= 200) then return error_handle() end
        -- print("==================================server address============================", msg.data.ip, msg.data.port);
        return type(callback) == "function" and callback(msg.data);
    end):Catch(function()
        error_handle();
    end);
end


-- 构造函数
function Net:ctor()
end

-- 连接
function Net:Connect(callback)
    -- 注册连接事件
    self:OnConnected(callback);

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
    SelectWorldServer(function(opts)
        __connection__:Init(opts):Connect(function(data)
            print("==========================net connect success=========================")
            self:SetConnected(true);
            self:SetConnecting(false);
            TriggerEventCallBack(Net.EVENT_TYPE.CONNECTED, data);
        end);
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
    __connection__:OnRecv(__safe_callback__(callback));
end

function Net:On(msgname, callback)
    __msg_event_emitter__:RegisterEventCallBack(msgname, callback);
end

function Net:Emit(msgname, msgdata, username)
    local data = {
        __action__ = Net.EVENT_TYPE.MSG,
        __msgname__ = msgname,
        __msgdata__ = msgdata,
    }

    if (username) then
        self:SendTo(username, data);
    else
        self:Send(data);
    end
end

function Net:Off(msgname, callback)
    __msg_event_emitter__:RemoveEventCallBack(msgname, callback);
end

-- 断开
function Net:OnDisconnected(callback)
    __connection__:OnDisconnected(__safe_callback__(callback))
end

-- 连接
function Net:OnConnected(callback)
    RegisterEventCallBack(Net.EVENT_TYPE.CONNECTED, __safe_callback__(callback));
end

function Net:OnClosed(callback)
    __connection__:OnClosed(__safe_callback__(callback));
end

function Net:OnNetClosed(callback)
    __connection__:OnNetClosed(__safe_callback__(callback));
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
    __connection__:OnShareDataItem(key, __safe_callback__(callback));
end

function Net:OnShareData(...)
    __connection__:OnShareData(...);
end

Net:InitSingleton():Connect(function()
end);

Net:OnDisconnected(function() 
    print("========================Net:OnDisconnected========================")
    Net:SetConnected(false);
    if (not Net:IsConnecting()) then
        Net:Connect() 
    end
end);

Net:OnClosed(function()
    print("========================Net:OnClosed========================")
end);

Net:OnRecv(function(data)
    if (data.__action__ == Net.EVENT_TYPE.MSG) then
        __msg_event_emitter__:TriggerEventCallBack(data.__msgname__, data.__msgdata__);
    end
end);