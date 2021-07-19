--[[
Title: KeyBoard
Author(s):  wxa
Date: 2021-06-01
Desc: 记录按键信息
use the lib:
------------------------------------------------------------
local KeyBoard = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/KeyBoard.lua");
------------------------------------------------------------
]]

local KeyBoard = inherit(ToolBase, module("KeyBoard"));

local __event_emitter__ = EventEmitter:new();

local __key_info__ = {};
local __key_map__ = {
    W = DIK_SCANCODE.DIK_W,
    A = DIK_SCANCODE.DIK_A,
    S = DIK_SCANCODE.DIK_S,
    D = DIK_SCANCODE.DIK_D,
    F = DIK_SCANCODE.DIK_F,
    SPACE = DIK_SCANCODE.DIK_SPACE,
}; -- event_mapping

function GetKeyInfo(key)
    key = string.upper(key);
    if (not __key_map__[key]) then return nil end

    __key_info__[key] = __key_info__[key] or {
        key = key,
        scancode = __key_map__[key], 
        count = 0, 
        is_pressed = false,
    };
    return __key_info__[key];
end

function UpdateKeyInfo(key)
    local info = GetKeyInfo(key);
    if (not info) then return end 

    if (IsKeyPressed(info.scancode)) then
        if (not info.is_pressed) then 
            __event_emitter__:TriggerEventCallBack(string.format("%s_key_down", info.key), info);
        else 
            -- __event_emitter__:TriggerEventCallBack(string.format("%s_key_change", info.key), info);
        end
        info.count = info.count + 1;
        info.is_pressed = true;
    else 
        if (info.is_pressed) then
            __event_emitter__:TriggerEventCallBack(string.format("%s_key_up", info.key), info);
        end
        info.is_pressed = false;
        info.count = 0;
    end
end

function KeyBoard:OnKeyDown(key, callback)
    local info = GetKeyInfo(key);
    __event_emitter__:RegisterEventCallBack(string.format("%s_key_down", info.key), callback);
end

function KeyBoard:OnKeyUp(key, callback)
    local info = GetKeyInfo(key);
    __event_emitter__:RegisterEventCallBack(string.format("%s_key_up", info.key), callback);
end

function KeyBoard:OnKeyChange(key, callback)
end

local function Tick()
    for key in pairs(__key_map__) do
        UpdateKeyInfo(key); 
    end
end

RegisterTimerCallBack(Tick);