--[[
Title: State
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local State = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/State.lua");
------------------------------------------------------------
]]

local State = inherit(ToolBase, module("State"));

local __state__ = NewScope();
local IndexCallback = {};
local NewIndexCallBack = {};

function set(key, val)
    __state__:Set(key, val);
end

function get(key, default_value)
    return __state__:Get(key, default_value);
end

function watch(key, callback)
    __state__:Watch(key, callback);
end

function notify(key)
    __state__:Notify(key);
end

function dump()
    echo(__state__:ToPlainObject(), true);
end

function RegisterStateIndexCallBack(callback)
    if (type(callback) ~= "function") then return end
    IndexCallback[callback] = callback;
end

function RegisterStateNewIndexCallBack(callback)
    if (type(callback) ~= "function") then return end
    NewIndexCallBack[callback] = callback;
end

local function StateIndexCallBack(scope, key)
    for _, callback in pairs(IndexCallback) do
        callback(scope, key);
    end
end

local function StateNewIndexCallBack(scope, key, newval, oldval)
    for _, callback in pairs(NewIndexCallBack) do
        callback(scope, key, newval, oldval);
    end
end

__state__:__set_index_callback__(StateIndexCallBack);
__state__:__set_newindex_callback__(StateNewIndexCallBack);

function State:GetScope()
    return __state__;
end

function State:IsScope(scope)
    return __state__:__is_scope__(scope);
end

function State:Set(key, val)
    set(key, val);
end

function State:Get(key, default_value)
    return get(key, default_value);
end

function State:Watch(key, callback)
    watch(key, callback);
end

function State:Notify(key)
    notify(key);
end

function State:RegisterIndexCallBack(callback)
    RegisterStateIndexCallBack(callback);
end

function State:RegisterNewIndexCallBack(callback)
    RegisterStateNewIndexCallBack(callback);
end

State:InitSingleton();
