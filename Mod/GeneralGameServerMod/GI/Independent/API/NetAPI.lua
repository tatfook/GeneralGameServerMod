--[[
Title: Net
Author(s):  wxa
Date: 2021-06-01
Desc: Net
use the lib:
------------------------------------------------------------
local Net = NPL.load("Mod/GeneralGameServerMod/GI/Independent/API/Net.lua");
------------------------------------------------------------
]]

local EventEmitter = NPL.load("Mod/GeneralGameServerMod/CommonLib/EventEmitter.lua");
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local VirtualConnection = NPL.load("Mod/GeneralGameServerMod/CommonLib/VirtualConnection.lua");

local __event_emitter__ = EventEmitter:new();
local EventType = {
    __NET_CONNECT__ = "__NET_CONNECT__",
    __NET_MSG__ = "__NET_MSG__",
    __NET_DISCONNECT__ = "__NET_DISCONNECT__",
}

local __virtual_connection__ = VirtualConnection:GetVirtualConnection({
    __remote_neuron_file__ = "Mod/GeneralGameServerMod/Server/Net/Handler.lua",
});

local NetAPI = NPL.export()

setmetatable(NetAPI, {__call = function(_, CodeEnv)
    CodeEnv.NetSend = function(...)
        __virtual_connection__:Send(...);
    end

    CodeEnv.NetConnect = function(callback)
        -- 设置连接ID
        __virtual_connection__:SetNid(CommonLib.AddNPLRuntimeAddress(CodeEnv.__ip__ or "127.0.0.1", CodeEnv.__port__ or "9000"));
        -- 连接
        __virtual_connection__:Connect(callback);
    end

    CodeEnv.NetClose = function()
        __virtual_connection__:CloseConnection();
    end

    CodeEnv.NetOnConnected = function(...)
        CodeEnv.RegisterEventCallBack(EventType.__NET_CONNECT__, ...);
    end
    
    CodeEnv.NetOnMsg = function(...) 
        CodeEnv.RegisterEventCallBack(EventType.__NET_MSG__, ...);
    end
    
    CodeEnv.NetOnDisconnected = function(...) 
        CodeEnv.RegisterEventCallBack(EventType.__NET_DISCONNECT__, ...);
    end

    local function Net_OnConnected(...)
        CodeEnv.TriggerEventCallBack(EventType.__NET_CONNECT__, ...);
    end

    local function Net_OnMsg(...)
        CodeEnv.TriggerEventCallBack(EventType.__NET_MSG__, ...);
    end

    local function Net_OnDisconnected(...)
        CodeEnv.TriggerEventCallBack(EventType.__NET_DISCONNECT__, ...);
    end

    __virtual_connection__:OnMsg(Net_OnMsg, CodeEnv);
    __virtual_connection__:OnConnected(Net_OnConnected, CodeEnv);
    __virtual_connection__:OnDisconnected(Net_OnDisconnected, CodeEnv);

    CodeEnv.RegisterEventCallBack(CodeEnv.EventType.CLEAR, function() 
        __virtual_connection__:OffMsg(Net_OnMsg, CodeEnv);
        __virtual_connection__:OffConnected(Net_OnConnected, CodeEnv);
        __virtual_connection__:OffDisconnected(Net_OnDisconnected, CodeEnv);
    end);
end});
