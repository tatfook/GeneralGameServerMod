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

GGS:Property("ConnectCallBack");
GGS:Property("DisconnectCallBack");
GGS:Property("RecvCallBack");

local username = GetUserName();
local players = {};
local isConnecting = false;

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

function GGS:Set(key, value)
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