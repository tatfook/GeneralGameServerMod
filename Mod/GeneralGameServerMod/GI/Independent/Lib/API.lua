--[[
Title: API
Author(s):  wxa
Date: 2021-06-01
Desc: 模块API的简化
use the lib:
------------------------------------------------------------
local API = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/API.lua");
------------------------------------------------------------
]]

local API = module("API");

-- 定义快捷方式接口
function GetGGSModule()
    return require("GGS");
end

function SetSharedData(key, val)
    GetGGSModule():SetShareData({[key] = val})
end

function GetSharedData(key, default_val)
    return GetGGSModule():GetShareData()[key] or default_val;
end

function OnSharedDataChanged(key, callback)
    return GetGGSModule():OnShareDataItem(key, callback);
end

function GetGGSStateModule()
    return require("GGSState");
end

function GetUserData(key, default_val)
    return GetGGSStateModule():GetUserState()[key] or default_val;
end

function SetUserData(key, val)
    GetGGSStateModule():GetUserState()[key] = val;
end

function GetAllUserData()
    return GetGGSStateModule():GetAllUserState();
end

function RegisterNetworkEvent(msgname, callback)
    GetGGSModule():On(msgname, callback);
end

function TriggerNetworkEvent(msgname, msgdata)
    GetGGSModule():Emit(msgname, msgdata);
end

function RegisterGGSConnectEvent(callback)
    GetGGSModule():Connect(callback);
end

function GetGGSPlayerModule()
    return require("GGSPlayer");
end

function GetGGSRankModule()
    return require("GGSRank");
end
