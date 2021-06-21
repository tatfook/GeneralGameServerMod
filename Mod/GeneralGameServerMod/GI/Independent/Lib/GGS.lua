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
GGS:Property("Connected", false, "IsConnected");    -- 是否连接成功
GGS:Property("Connecting", false, "IsConnecting");  -- 是否正在连接
local __username__ = GetUserName();

GGS.EVENT_TYPE = {
    CONNECT = "GGS_CONNECT",
    DISCONNECT = "GGS_DISCONNECT",
    RECV = "GGS_RECV",
    USER_DATA = "GGS_USER_DATA",
}

function GGS:Init()
    GGS:SetConnected(false);
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
    GGS_Connect(function()
        self:SetConnected(true);
        self:SetConnecting(false);
        TriggerEventCallBack(GGS.EVENT_TYPE.CONNECT);
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
    return GGS_SendTo(username, data);
end

function GGS:SetUserData(data)
    GGS_SendUserData(data);
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
function GGS:OnDisconnect(callback)
    RegisterEventCallBack(GGS.EVENT_TYPE.DISCONNECT, callback);
end

GGS:InitSingleton():Init();

GGS_Recv(function(msg)
    TriggerEventCallBack(GGS.EVENT_TYPE.RECV, msg);
end)

GGS_RecvUserData(function(data)
    TriggerEventCallBack(GGS.EVENT_TYPE.USER_DATA, data);
end)

GGS_Disconnect(function(username)
    if (not username or username == __username__) then GGS:SetConnected(false) end
    TriggerEventCallBack(GGS.EVENT_TYPE.DISCONNECT, username or __username__);
end);