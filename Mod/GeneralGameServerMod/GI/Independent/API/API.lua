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
local API = NPL.export()

setmetatable(
    API,
    {
        __call = function(_, CodeEnv)
            CodeEnv.GetWorldId = function() return GameLogic.options:GetProjectId() end 
        end
    }
)
