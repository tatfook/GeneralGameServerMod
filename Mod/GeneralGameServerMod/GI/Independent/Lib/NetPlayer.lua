--[[
Title: NetPlayer
Author(s):  wxa
Date: 2021-06-01
Desc: Net 玩家管理
use the lib:
------------------------------------------------------------
local NetPlayer = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/NetPlayer.lua");
------------------------------------------------------------
]]

local Net = require("Net");
local NetPlayer = inherit(ToolBase, module("NetPlayer"));

local __scope__ = NewScope();
local __username__ = GetUserName();
local __players__ = {};

Net.EVENT_TYPE.PLAYER_LOGIN = "NET_PLAYER_LOGIN";
Net.EVENT_TYPE.PLAYER_LOGOUT = "NET_PLAYER_LOGOUT";
Net.EVENT_TYPE.MAIN_PLAYER_LOGIN = "NET_MAIN_PLAYER_LOGIN";
Net.EVENT_TYPE.MAIN_PLAYER_LOGOUT = "NET_MAIN_PLAYER_LOGOUT";
Net.EVENT_TYPE.PLAYER_INFO = "NET_PLAYER_INFO";

function NetPlayer:PlayerLogin(player)
    -- Tip(string.format("玩家[%s]加入", username));
    local username = player.username;
    __players__[username] = player;

    self:RefreshPlayerListUI();

    TriggerEventCallBack(Net.EVENT_TYPE.PLAYER_LOGIN, __players__[username]);

    Net:SendTo(username, {
        action = Net.EVENT_TYPE.PLAYER_INFO, 
        player = self:GetPlayer(),
    });
end

function NetPlayer:PlayerLogout(username)
    -- Tip(string.format("玩家[%s]退出", username));
    if (not __players__[username]) then return end 

    TriggerEventCallBack(Net.EVENT_TYPE.PLAYER_LOGOUT, __players__[username]);

    __players__[username] = nil;

    self:RefreshPlayerListUI();
end

function NetPlayer:MainPlayerLogin()
    __players__[__username__] = {
        username = __username__, 
        nickname = GetNickName(),
        school = GetSchoolName(),
        loginAt = GetTime(),
    };
    
    self:RefreshPlayerListUI();

    TriggerEventCallBack(Net.EVENT_TYPE.MAIN_PLAYER_LOGIN, __players__[__username__]);
    TriggerEventCallBack(Net.EVENT_TYPE.PLAYER_LOGIN, __players__[__username__]);
end

function NetPlayer:MainPlayerLogout()
    TriggerEventCallBack(Net.EVENT_TYPE.MAIN_PLAYER_LOGOUT, __players__[__username__]);
    TriggerEventCallBack(Net.EVENT_TYPE.PLAYER_LOGOUT, __players__[__username__]);

    self:RefreshPlayerListUI();
end

function NetPlayer:OnPlayerInfoChange(callback)
    RegisterEventCallBack(Net.EVENT_TYPE.PLAYER_INFO, callback);
end

function NetPlayer:SetMainPlayerInfo(player)
    player.username = __username__;
    __players__[__username__] = __players__[__username__] or {};
    partialcopy(__players__[__username__], player);
    self:RefreshPlayerListUI();
    Net:Send({action = Net.EVENT_TYPE.PLAYER_INFO, player = __players__[__username__]});
end

function NetPlayer:SetOtherPlayerInfo(player)
    local username = player and player.username;
    if (not username) then return end
    __players__[username] = __players__[username] or {};
    partialcopy(__players__[username], player);
    self:RefreshPlayerListUI();
    TriggerEventCallBack(Net.EVENT_TYPE.PLAYER_INFO, __players__[username]);
end

function NetPlayer:Init()
    return self;
end

function NetPlayer:GetAllPlayer()
    return __players__;
end

function NetPlayer:GetPlayer(username)
    return __players__[username or __username__];
end

function NetPlayer:OnMainPlayerLogin(callback)
    RegisterEventCallBack(Net.EVENT_TYPE.MAIN_PLAYER_LOGIN, callback);

    if (__players__[__username__]) then callback(__players__[__username__]) end  
end

function NetPlayer:OnMainPlayerLogout(callback)
    RegisterEventCallBack(Net.EVENT_TYPE.MAIN_PLAYER_LOGOUT, callback);
end

function NetPlayer:OnPlayerLogin(callback)
    RegisterEventCallBack(Net.EVENT_TYPE.PLAYER_LOGIN, callback);
end

function NetPlayer:OnPlayerLogout(callback)
    RegisterEventCallBack(Net.EVENT_TYPE.PLAYER_LOGOUT, callback);
end

function NetPlayer:RefreshPlayerListUI()
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

function NetPlayer:ShowPlayerListUI(G, params)
    G = G or {};
    params = params or {};

    G.GlobalScope = __scope__;
    params.url = params.url or "%gi%/Independent/UI/NetPlayerList.html";
    params.alignment = params.alignment or "_rt";
    params.width = params.width or 350;
    params.height = params.height or 500;
    -- params.isClickThrough = true;
    params.zorder = params.zorder or -100;

    self.__player_list_ui__ = ShowWindow(G, params);
    self:RefreshPlayerListUI();

    return self.__player_list_ui__; 
end

function NetPlayer:ClosePlayerListUI()
    if (not self.__player_list_ui__) then return end
    self.__player_list_ui__:CloseWindow();
    self.__player_list_ui__ = nil;
end

function NetPlayer:TriggerPlayerListUI(...)
    if (self.__player_list_ui__) then
        self:ClosePlayerListUI(...);
    else
        self:ShowPlayerListUI(...);
    end
end

NetPlayer:InitSingleton():Init();

-- 连接
Net:Connect(function()
    -- 处理主玩家登录
    NetPlayer:MainPlayerLogin();
    -- 通知其它玩家新玩家加入
    Net:Send({
        action = Net.EVENT_TYPE.PLAYER_LOGIN, 
        player = NetPlayer:GetPlayer(),
    });
end);

-- 收到数据
Net:OnRecv(function(msg)
    local action = msg.action;
    if (action == Net.EVENT_TYPE.PLAYER_LOGIN) then return NetPlayer:PlayerLogin(msg.player) end
    if (action == Net.EVENT_TYPE.PLAYER_INFO) then return NetPlayer:SetOtherPlayerInfo(msg.player) end
end);

-- 主玩家连接关闭
Net:OnClosed(function()
    NetPlayer:MainPlayerLogout();
end);

-- 其它玩家连接关闭
Net:OnNetClosed(function(username)
    NetPlayer:PlayerLogout(username);
end)