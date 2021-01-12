--[[
Title: Storage
Author(s): wxa
Date: 2020/6/30
Desc: Storage
use the lib:
-------------------------------------------------------
local Storage = NPL.load("Mod/GeneralGameServerMod/UI/Window/Storage.lua");
-------------------------------------------------------
]]

local Storage = NPL.export{};

local __session_storage__ = {};
local SessionStorage = {};

function SessionStorage.SetItem(key, val)
    __session_storage__[key] = val;
end

function SessionStorage.GetItem(key)
    return __session_storage__[key];
end

function SessionStorage.Clear()
    __session_storage__ = {};
end

Storage.SessionStorage = SessionStorage;

local LocalStorage = {};
function LocalStorage.SetItem(key, val)
    return GameLogic.GetPlayerController():SaveLocalData(key, val, true, false);
end

function LocalStorage.GetItem(key, defaultValue)
    return GameLogic.GetPlayerController():LoadLocalData(key, defaultValue, true);
end

function LocalStorage.Clear()

end

Storage.LocalStorage = LocalStorage;