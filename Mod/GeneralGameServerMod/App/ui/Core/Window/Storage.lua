--[[
Title: Storage
Author(s): wxa
Date: 2020/6/30
Desc: Storage
use the lib:
-------------------------------------------------------
local Storage = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Storage.lua");
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