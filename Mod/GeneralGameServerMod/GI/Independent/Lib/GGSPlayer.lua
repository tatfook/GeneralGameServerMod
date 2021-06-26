--[[
Title: GGSPlayer
Author(s):  wxa
Date: 2021-06-01
Desc: GGS 玩家管理
use the lib:
------------------------------------------------------------
local GGSPlayer = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/GGSPlayer.lua");
------------------------------------------------------------
]]

local GGS = require("GGS");
local GGSPlayer = inherit(ToolBase, module("GGSPlayer"));

local __username__ = GetUserName();
local __players__ = {};

GGS.EVENT_TYPE.PLAYER_LOGIN = "GGS_PLAYER_LOGIN";
GGS.EVENT_TYPE.PLAYER_LOGOUT = "GGS_PLAYER_LOGOUT";
GGS.EVENT_TYPE.MAIN_PLAYER_LOGIN = "GGS_MAIN_PLAYER_LOGIN";
GGS.EVENT_TYPE.MAIN_PLAYER_LOGOUT = "GGS_MAIN_PLAYER_LOGOUT";

local function PlayerLogin(username)
    -- Tip(string.format("玩家[%s]加入", username));
    __players__[username] = {
        username = username,
        loginAt = GetTime(),
    }
    -- local state = msg.state or {};
    -- local IsAutoSyncState = GGS:IsAutoSyncState();

    -- -- 用户加入同步
    -- GGS:SetAutoSyncState(false);
    -- GGS_State:Set(username, state);
    -- GGS:SetAutoSyncState(IsAutoSyncState);

    TriggerEventCallBack(GGS.EVENT_TYPE.PLAYER_LOGIN, __players__[username]);
end

local function PlayerLogout(username)
    if (not __players__[username]) then return end 
    TriggerEventCallBack(GGS.EVENT_TYPE.PLAYER_LOGOUT, __players__[username]);

    -- Tip(string.format("玩家[%s]退出", username));
    __players__[username] = nil;
end

local function MainPlayerLogin()
    __players__[__username__] = {username = __username__, loginAt = GetTime()};
    TriggerEventCallBack(GGS.EVENT_TYPE.MAIN_PLAYER_LOGIN, __players__[__username__]);
    TriggerEventCallBack(GGS.EVENT_TYPE.PLAYER_LOGIN, __players__[__username__]);
end

local function MainPlayerLogout()
    TriggerEventCallBack(GGS.EVENT_TYPE.MAIN_PLAYER_LOGOUT, __players__[__username__]);
    TriggerEventCallBack(GGS.EVENT_TYPE.PLAYER_LOGOUT, __players__[__username__]);
end

function GGSPlayer:Init()
    return self;
end

function GGSPlayer:GetAllPlayer()
    return __players__;
end

function GGSPlayer:GetPlayer(username)
    return __players__[username or ""];
end

function GGSPlayer:OnMainPlayerLogin(callback)
    RegisterEventCallBack(GGS.EVENT_TYPE.MAIN_PLAYER_LOGIN, callback);
end

function GGSPlayer:OnMainPlayerLogout(callback)
    RegisterEventCallBack(GGS.EVENT_TYPE.MAIN_PLAYER_LOGOUT, callback);
end

function GGSPlayer:OnPlayerLogin(callback)
    RegisterEventCallBack(GGS.EVENT_TYPE.PLAYER_LOGIN, callback);
end

function GGSPlayer:OnPlayerLogout(callback)
    RegisterEventCallBack(GGS.EVENT_TYPE.PLAYER_LOGOUT, callback);
end

GGSPlayer:InitSingleton():Init();

-- 连接
GGS:OnConnect(function()
    -- 处理主玩家登录
    MainPlayerLogin();
    -- 通知其它玩家新玩家加入
    GGS:Send({
        action = GGS.EVENT_TYPE.PLAYER_LOGIN, 
        username = __username__,
    });
end);

-- 收到数据
GGS:OnRecv(function(msg)
    local action = msg.action;
    if (action == GGS.EVENT_TYPE.PLAYER_LOGIN) then return PlayerLogin(msg.username) end
end);

-- 断开
GGS:OnDisconnect(function(username)
    if (username == __username__) then
        MainPlayerLogout();
    else
        PlayerLogout(username);
    end
end)
