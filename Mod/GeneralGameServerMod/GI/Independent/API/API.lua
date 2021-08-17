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

local function Tip(text, duration, color, id)
    BroadcastHelper.PushLabel(
        {
            id = id or "GI",
            label = text,
            max_duration = duration or 3000,
            color = color or "255 255 255",
            scaling = 1,
            bold = true,
            shadow = true
        }
    )
end

setmetatable(API, {__call = function(_, CodeEnv)
    local __world_key__ = nil;
    CodeEnv.Tip = Tip;
	CodeEnv.MessageBox = _guihelper.MessageBox;
    CodeEnv.GetLogTimeString = commonlib.log.GetLogTimeString;
    CodeEnv.MD5 = CommonLib.MD5;

    CodeEnv.GetWorldId = function() return GameLogic.options:GetProjectId() end 
    CodeEnv.SetWorldKey = function(worldKey) __world_key__ = worldKey end 
    CodeEnv.GetWorldKey = function() return __world_key__ end 
    CodeEnv.AddNPLRuntimeAddress = CommonLib.AddNPLRuntimeAddress;
    CodeEnv.LuaXML_ParseString = ParaXML.LuaXML_ParseString;
end});