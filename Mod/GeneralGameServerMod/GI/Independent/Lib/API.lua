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

function GetSharedData(key, defaule_val)
    return GetGGSModule():GetShareData()[key] or defaule_val;
end

function OnSharedData(key, callback)
    return GetGGSModule():OnShareDataItem(key, callback);
end

function GetGGSStateModule()
    return require("GGSState");
end

function GetUserData(key, defaule_val)
    return GetGGSStateModule():GetUserState()[key] or defaule_val;
end

function SetUserData(key, val)
    GetGGSStateModule():GetUserState()[key] = val;
end