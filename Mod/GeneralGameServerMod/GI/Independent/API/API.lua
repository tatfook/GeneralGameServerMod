--[[
Title: API
Author(s):  wxa
Date: 2021-06-01
Desc: API 模板文件
use the lib:
------------------------------------------------------------
local API = NPL.load("Mod/GeneralGameServerMod/GI/Independent/API/API.lua");
------------------------------------------------------------
]]
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local API = NPL.export()

setmetatable(API, {__call = function(_, CodeEnv)
    local __world_key__ = nil;
    CodeEnv.GetWorldId = function() return GameLogic.options:GetProjectId() end 
    CodeEnv.SetWorldKey = function(worldKey) __world_key__ = worldKey end 
    CodeEnv.GetWorldKey = function() return __world_key__ end 
    CodeEnv.AddNPLRuntimeAddress = CommonLib.AddNPLRuntimeAddress;
end});