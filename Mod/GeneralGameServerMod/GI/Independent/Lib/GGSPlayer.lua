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

local __scope__ = NewScope();
local __username__ = GetUserName();
local __players__ = {};

GGS.EVENT_TYPE.PLAYER_LOGIN = "GGS_PLAYER_LOGIN";
GGS.EVENT_TYPE.PLAYER_LOGOUT = "GGS_PLAYER_LOGOUT";
GGS.EVENT_TYPE.MAIN_PLAYER_LOGIN = "GGS_MAIN_PLAYER_LOGIN";
GGS.EVENT_TYPE.MAIN_PLAYER_LOGOUT = "GGS_MAIN_PLAYER_LOGOUT";
GGS.EVENT_TYPE.PLAYER_INFO = "GGS_PLAYER_INFO";

function GGSPlayer:PlayerLogin(player)
    -- Tip(string.format("玩家[%s]加入", username));
    local username = player.username;
    __players__[username] = player;

    self:RefreshPlayerListUI();

    TriggerEventCallBack(GGS.EVENT_TYPE.PLAYER_LOGIN, __players__[username]);

    GGS:SendTo(username, {
        action = GGS.EVENT_TYPE.PLAYER_INFO, 
        player = self:GetPlayer(),
    });
end

function GGSPlayer:PlayerLogout(username)
    -- Tip(string.format("玩家[%s]退出", username));
    if (not __players__[username]) then return end 

    TriggerEventCallBack(GGS.EVENT_TYPE.PLAYER_LOGOUT, __players__[username]);

    __players__[username] = nil;

    self:RefreshPlayerListUI();
end

function GGSPlayer:MainPlayerLogin()
    __players__[__username__] = {
        username = __username__, 
        nickname = GetNickName(),
        school = GetSchoolName(),
        loginAt = GetTime(),
    };
    
    self:RefreshPlayerListUI();

    TriggerEventCallBack(GGS.EVENT_TYPE.MAIN_PLAYER_LOGIN, __players__[__username__]);
    TriggerEventCallBack(GGS.EVENT_TYPE.PLAYER_LOGIN, __players__[__username__]);
end

function GGSPlayer:MainPlayerLogout()
    TriggerEventCallBack(GGS.EVENT_TYPE.MAIN_PLAYER_LOGOUT, __players__[__username__]);
    TriggerEventCallBack(GGS.EVENT_TYPE.PLAYER_LOGOUT, __players__[__username__]);

    self:RefreshPlayerListUI();
end

function GGSPlayer:OnPlayer(callback)
    RegisterEventCallBack(GGS.EVENT_TYPE.PLAYER_INFO, callback);
end

function GGSPlayer:SetPlayerInfo(player)
    local username = player and player.username;
    if (not username) then return end
    __players__[username] = __players__[username] or {};
    partialcopy(__players__[username], player);

    self:RefreshPlayerListUI();

    TriggerEventCallBack(GGS.EVENT_TYPE.PLAYER_INFO, __players__[username]);
end

function GGSPlayer:Init()
    return self;
end

function GGSPlayer:GetAllPlayer()
    return __players__;
end

function GGSPlayer:GetPlayer(username)
    return __players__[username or __username__];
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

function GGSPlayer:RefreshPlayerListUI()
    if (not self.__player_list_ui__) then return end

    local players = __scope__:Get("players", {});
    local size, index = #players, 1;
    local exists = {};

    local function add_player(player, curplayer)
        if (not player or exists[player.username]) then return end
        curplayer = curplayer or NewScope();
        curplayer.username = player.username;
        curplayer.nickname = player.nickname;
        exists[player.username] = true;
        players[index] = curplayer;
        index = index + 1;
    end

    for i = 1, size do
        local curplayer = players[i];
        local player = __players__[curplayer.username];
        players[i] = nil;
        add_player(player, curplayer);
    end

    for username, player in pairs(__players__) do
        add_player(player);
    end
end

function GGSPlayer:ShowPlayerListUI(G, params)
    G = G or {};
    params = params or {};

    G.GlobalScope = __scope__;
    params.url = params.url or "%gi%/Independent/UI/GGSPlayerList.html";
    params.alignment = params.alignment or "_rt";
    params.width = params.width or 350;
    params.height = params.height or 500;

    self.__player_list_ui__ = ShowWindow(G, params);
    self:RefreshPlayerListUI();

    return self.__player_list_ui__; 
end

function GGSPlayer:ClosePlayerListUI(G, params)
    if (not self.__player_list_ui__) then return end
    self.__player_list_ui__:CloseWindow();
    self.__player_list_ui__ = nil;
end

GGSPlayer:InitSingleton():Init();

-- 连接
GGS:Connect(function()
    -- 处理主玩家登录
    GGSPlayer:MainPlayerLogin();
    -- 通知其它玩家新玩家加入
    GGS:Send({
        action = GGS.EVENT_TYPE.PLAYER_LOGIN, 
        player = GGSPlayer:GetPlayer(),
    });
end);

-- 收到数据
GGS:OnRecv(function(msg)
    local action = msg.action;
    if (action == GGS.EVENT_TYPE.PLAYER_LOGIN) then return GGSPlayer:PlayerLogin(msg.player) end
    if (action == GGS.EVENT_TYPE.PLAYER_INFO) then return GGSPlayer:SetPlayerInfo(msg.player) end
end);

-- 断开
GGS:OnDisconnect(function(username)
    if (username == __username__) then
        GGSPlayer:MainPlayerLogout();
    else
        GGSPlayer:PlayerLogout(username);
    end
end)
