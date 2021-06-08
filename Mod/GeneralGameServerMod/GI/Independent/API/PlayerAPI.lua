--[[
Title: PlayerAPI
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local PlayerAPI = NPL.load("Mod/GeneralGameServerMod/GI/Independent/API/PlayerAPI.lua");
------------------------------------------------------------
]]

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local PlayerAPI = NPL.export();

local function GetUserInfo()
    return KeepWorkItemManager.GetProfile();
end

local function GetUserId()
    return GetUserInfo().id;
end

local function GetUserName()
    return GetUserInfo().username;
end

local function GetNickName()
    return GetUserInfo().nickname;
end

setmetatable(PlayerAPI, {__call = function(_, CodeEnv)
    CodeEnv.GetUserId = GetUserId;
    CodeEnv.GetUserName = GetUserName;
    CodeEnv.GetNickName = GetNickName;
    
    CodeEnv.GetPlayerEntityId = function() return EntityManager.GetPlayer().entityId end
    CodeEnv.IsInWater = function() return GameLogic.GetPlayerController():IsInWater() end
	CodeEnv.IsInAir = function() return GameLogic.GetPlayerController():IsInAir() end
    CodeEnv.SetPlayerVisible = function (visible) EntityManager.GetPlayer():SetVisible(visible) end
end});
