
--[[
Title: API
Author(s):  wxa
Date: 2021-06-01
Desc: API 模板文件
use the lib:
------------------------------------------------------------
local CodeBlock = NPL.load("Mod/GeneralGameServerMod/GI/Independent/API/CodeBlock.lua");
------------------------------------------------------------
]]

local CodeBlockAPI = NPL.export();

setmetatable(CodeBlockAPI, {__call = function(_, CodeEnv)
    local __CodeGlobal__ = GameLogic.GetCodeGlobal()
    local __event_map__ = {};

    CodeEnv.__CodeGlobal__ = __CodeGlobal__;

    CodeEnv.RegisterCodeBlockBroadcastEvent = function(event_name, callback)
        __event_map__[event_name] = __event_map__[event_name] or {};
        __event_map__[event_name][callback] = function(_, msg)
            callback(msg.msg);
        end;
        __CodeGlobal__:RegisterTextEvent(event_name, __event_map__[event_name][callback]);
    end

    CodeEnv.RemoveCodeBlockBroadcastEvent = function(event_name, callback)
        __event_map__[event_name] = __event_map__[event_name] or {};
        __CodeGlobal__:UnregisterTextEvent(event_name,  __event_map__[event_name][callback]);
        __event_map__[event_name][callback] = nil;
    end

    CodeEnv.TriggerCodeBlockBroadcastEvent = function(event_name, event_data, callback)
        __CodeGlobal__:BroadcastTextEvent(event_name, event_data, callback);
    end

    CodeEnv.RegisterEventCallBack(CodeEnv.EventType.CLEAR, function()
        for event_name, event_callback_map in pairs(__event_map__) do
            for _, callback in pairs(event_callback_map) do
                __CodeGlobal__:UnregisterTextEvent(event_name, callback);
            end
        end
    end);
end});