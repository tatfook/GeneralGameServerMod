--[[
Title: Player
Author(s):  wxa
Date: 2021-06-30
Desc: 网络API
use the lib:
------------------------------------------------------------
local Player = NPL.load("Mod/GeneralGameServerMod/Server/Net/Player.lua");
------------------------------------------------------------
]]

local Player = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Player:Property("UserName");
Player:Property("World");
Player:Property("Connection");

local __all_player__ = {};

function Player:ctor()
    self.__entity_data__ = {};
end

function Player:GetEntityData()
    return self.__entity_data__;
end

function Player:Init(username)
    self:SetUserName(username);

    __all_player__[username] = self;

    return self;
end

function Player:GetPlayer(username, isNewNoExist)
    local player = __all_player__[username];
    if (player) then return player end
    if (not isNewNoExist) then return end
    return Player:new():Init(username);
end

function Player:Send(...)
    local connection = self:GetConnection();
    if (not connection) then return end 
    connection:Emit(...);
end
