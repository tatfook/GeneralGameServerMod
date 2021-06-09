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

local __code_env__ = nil;

local function GetUserInfo()
    return KeepWorkItemManager.GetProfile();
end

local function GetUserId()
    return GetUserInfo().id or 0;
end

local function GetUserName()
    local username = GetUserInfo().username;
    if (not username or username == "") then
        username = string.format("User_%s", __code_env__.GetTime());  -- 可能重名
    end
    return username;
end

local function GetNickName()
    return GetUserInfo().nickname;
end

setmetatable(PlayerAPI, {__call = function(_, CodeEnv)
    __code_env__ = CodeEnv;

    CodeEnv.GetUserId = GetUserId;
    CodeEnv.GetUserName = GetUserName;
    CodeEnv.GetNickName = GetNickName;
    CodeEnv.GetPlayer = EntityManager.GetPlayer
    
    CodeEnv.GetPlayerEntityId = function() return EntityManager.GetPlayer().entityId end
    CodeEnv.IsInWater = function() return GameLogic.GetPlayerController():IsInWater() end
	CodeEnv.IsInAir = function() return GameLogic.GetPlayerController():IsInAir() end
    CodeEnv.SetPlayerVisible = function (visible) EntityManager.GetPlayer():SetVisible(visible) end
end});
