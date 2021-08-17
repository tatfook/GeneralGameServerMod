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

NPL.load("(gl)script/apps/Aries/SlashCommand/SlashCommand.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local EventEmitter = NPL.load("Mod/GeneralGameServerMod/CommonLib/EventEmitter.lua");

local UtilityAPI = NPL.export();
local __event_emitter__ = EventEmitter:new();

local function GetParticleSystem()
    return ParticleSystem.singleton();
end

local idx = 0;
local function CreateParticle(x,y,z, params)
    idx = idx + 1;
    local name = string.format("particle_%s", idx);
    return GetParticleSystem().createScene(name , x, y, z, params)
end



-- {name="hello", quick_ref="/hello text", desc="some description", handler = function(cmd_name, cmd_text, cmd_params) _guihelper.MessageBox("Hello World! "..cmd_text);end}
local function RegisterSlashCommand(cmd)
    -- SlashCommand.GetSingleton():RegisterSlashCommand(cmd);
    Commands[cmd.name] = cmd;
    CommandManager.slash_command:RegisterSlashCommand(cmd);
end

local __gi_cmd_event_type__ = "__gi_cmd__";
local __default_gi_cmd_handler__ = nil;
Commands["gi"] = {
	mode_deny = "",
    name = "gi",
    quick_ref = "/gi subcmd ...",
    desc = [[
/gi codeblock_blockly_editor 显示 GI 图块编辑器
    ]],
    handler = function(...)
        if (type(__default_gi_cmd_handler__) == "function") then __default_gi_cmd_handler__(...) end
        __event_emitter__:TriggerEventCallBack(__gi_cmd_event_type__, ...);
    end
};

if (IsDevEnv and CommandManager.slash_command) then
    CommandManager.slash_command:RegisterSlashCommand(Commands["gi"]);
end

setmetatable(
    UtilityAPI,
    {
        __call = function(_, CodeEnv)
            
            
            __default_gi_cmd_handler__ = function(cmd_name, cmd_text, cmd_params)
                local strs = CodeEnv.split(cmd_text, " ");
                local subcmd = strs[1];
                if (subcmd == "codeblock_blockly_editor") then return CodeEnv.ShowCodeBlockBlocklyEditorPage() end
                if (subcmd == "gi_blockly_editor") then return CodeEnv.ShowGIBlocklyEditorPage() end
            end

            local function OnGICmd(...)
                CodeEnv.TriggerEventCallBack(__gi_cmd_event_type__, ...);
            end

            CodeEnv.RegisterGICmdEvent = function(...)
                CodeEnv.RegisterEventCallBack(__gi_cmd_event_type__, ...);
            end

            __event_emitter__:RegisterEventCallBack(__gi_cmd_event_type__, OnGICmd, CodeEnv);
            CodeEnv.RegisterEventCallBack(CodeEnv.EventType.CLEAR, function() 
                __event_emitter__:RemoveEventCallBack(__gi_cmd_event_type__, OnGICmd, CodeEnv);
            end);
        end
    }
)
