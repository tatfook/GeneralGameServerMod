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

local Connection = NPL.load("Mod/GeneralGameServerMod/CommonLib/Connection.lua", IsDevEnv);
local EventEmitter = NPL.load("Mod/GeneralGameServerMod/CommonLib/EventEmitter.lua", IsDevEnv);

local __event_emitter__ = EventEmitter:new();
local EventType = {
    __NET_CONNECT__ = "__NET_CONNECT__",
    __NET_DATA__ = "__NET_DATA__",
    __NET_DISCONNECT__ = "__NET_DISCONNECT__",
}

local NetConnection = commonlib.inherit(Connection, {});
NetConnection:Property("RemoteNeuronFile", "Mod/GeneralGameServerMod/Server/Net/Net.lua");


function NetConnection:OnConnected()
    __event_emitter__:TriggerEventCallBack(EventType.__NET_CONNECT__);
end

function NetConnection:OnDisconnected()

end

function NetConnection:OnReceive(msg)
end


NetConnection:InitSingleton();


local function NetConnect(ip, port)
    NetConnection:SetIpAndPort(ip, port);

    NetConnection:Connect(function()
    end)
end

local function NetSend(msg)
    NetConnection:Send(msg);
end

local NetAPI = NPL.export()

setmetatable(NetAPI, {__call = function(_, CodeEnv)
    CodeEnv.NetSend = NetSend;

    CodeEnv.NetConnect = function(callback)
        CodeEnv.RegisterEventCallBack(EventType.__NET_CONNECT__, callback);
        NetConnect(CodeEnv.__ip__ or "127.0.0.1", CodeEnv.__port__ or "9000")
    end;
    
    CodeEnv.NetRecv = function(callback) 
        CodeEnv.RegisterEventCallBack(EventType.__NET_DATA__, callback);
    end
    
    CodeEnv.NetDisconnect = function(callback) 
        if (callback == nil) then NetConnection:Close() end 
        
        CodeEnv.RegisterEventCallBack(EventType.__NET_DISCONNECT__, callback);
    end

    local function Net_OnConnected(...)
        CodeEnv.TriggerEventCallBack(EventType.__NET_CONNECT__, ...);
    end

    local function Net_OnData(...)
        CodeEnv.TriggerEventCallBack(EventType.__NET_DATA__, ...);
    end

    local function Net_OnDisconnected(...)
        CodeEnv.TriggerEventCallBack(EventType.__NET_DISCONNECT__, ...);
    end

    __event_emitter__:RegisterEventCallBack(EventType.__NET_DATA__, Net_OnData, CodeEnv);
    __event_emitter__:RegisterEventCallBack(EventType.__NET_CONNECT__, Net_OnConnected, CodeEnv);
    __event_emitter__:RegisterEventCallBack(EventType.__NET_DISCONNECT__, Net_OnDisconnected, CodeEnv);

    CodeEnv.RegisterEventCallBack(CodeEnv.EventType.CLEAR, function() 
        NetConnection:Close();

        __event_emitter__:RemoveEventCallBack(EventType.__NET_DATA__, Net_OnData, CodeEnv);
        __event_emitter__:RemoveEventCallBack(EventType.__NET_CONNECT__, Net_OnConnected, CodeEnv);
        __event_emitter__:RemoveEventCallBack(EventType.__NET_DISCONNECT__, Net_OnDisconnected, CodeEnv);
    end);
end});
