--[[
Title: Listener
Author(s):  wxa
Date: 2021-06-01
Desc: 事件监听触发器只负责事件触发, 顺序处理问题交由Promise解决
use the lib:
------------------------------------------------------------
local Listener = NPL.load("Mod/GeneralGameServerMod/GI/Utility/Listener.lua");
------------------------------------------------------------
]]

local Listener = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Listener:Property("EventObject"); -- 事件对象

function Listener:ctor()
    self.listener = {};
end

function Listener:Init(object)
    self:SetEventObject(object);

    return self;
end

function Listener:GetEventListeners(eventName)
    self.listener[eventName] = self.listener[eventName] or {};
    return self.listener[eventName];
end

function Listener:AddListener(eventName, listener)
    if (type(eventName) ~= "string" or type(listener) ~= "function") then return end
    
    local listeners = self:GetEventListeners(eventName);
    listeners[listener] = listener;
end

function Listener:RemoveListener(eventName, listener)
    if (type(eventName) ~= "string" or type(listener) ~= "function") then return end

    local listeners = self:GetEventListeners(eventName);
    listeners[listener] = nil;
end

function Listener:Notify(eventName, ...)
    if (type(eventName) ~= "string") then return end

    local listeners = self:GetEventListeners(eventName);
    for _, listener in pairs(listeners) do
        listener(self, ...);
    end
end

