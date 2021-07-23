--[[
Title: UtilityAPI
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local UtilityAPI = NPL.load("Mod/GeneralGameServerMod/GI/Independent/API/UtilityAPI.lua");
------------------------------------------------------------
]]
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local UtilityAPI = NPL.export()
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");

local function GetParticleSystem()
    return ParticleSystem.singleton();
end

local idx = 0;
local function CreateParticle(x,y,z, params)
    idx = idx + 1;
    local name = string.format("particle_%s", idx);
    return GetParticleSystem().createScene(name , x, y, z, params)
end

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

setmetatable(
    UtilityAPI,
    {
        __call = function(_, CodeEnv)
            CodeEnv.Tip = Tip;
	        CodeEnv.MessageBox = _guihelper.MessageBox;
            CodeEnv.GetLogTimeString = commonlib.log.GetLogTimeString;
            CodeEnv.MD5 = CommonLib.MD5;
        end
    }
)
