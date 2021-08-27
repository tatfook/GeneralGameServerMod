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

local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local API = NPL.export()

Commands["gi"] = {
	mode_deny = "",
    name = "gi",
    quick_ref = "/gi restart|start|stop",
    desc = [[
/gi restart 重启GI环境
/gi start 启动GI环境
/gi stop 停止GI环境
    ]],
    handler = function(cmd_name, cmd_text, cmd_params)
        local strs = commonlib.split(cmd_text, " ");
        local subcmd = strs[1];
        local __code_env__ = GameLogic.GetCodeGlobal():GetSandboxAPI().API;

        if (subcmd == "restart") then return __code_env__.__restart__() end
        if (subcmd == "start") then return __code_env__.__start__() end
        if (subcmd == "stop") then return __code_env__.__stop__() end
    end
};

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
    CodeEnv.EncodeBase64 = CommonLib.EncodeBase64;
    CodeEnv.DecodeBase64 = CommonLib.DecodeBase64;

    CodeEnv.GetWorldId = function() return GameLogic.options:GetProjectId() end 
    CodeEnv.SetWorldKey = function(worldKey) __world_key__ = worldKey end 
    CodeEnv.GetWorldKey = function() return __world_key__ end 
    CodeEnv.AddNPLRuntimeAddress = CommonLib.AddNPLRuntimeAddress;
    CodeEnv.LuaXML_ParseString = ParaXML.LuaXML_ParseString;
end});