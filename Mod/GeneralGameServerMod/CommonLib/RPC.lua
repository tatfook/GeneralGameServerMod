--[[
Title: RPC
Author(s): wxa
Date: 2020/6/12
Desc: RPC connection
-------------------------------------------------------
local RPC = NPL.load("Mod/GeneralGameServerMod/CommonLib/RPC.lua");
-------------------------------------------------------
]]

local CommonLib = NPL.load("./CommonLib.lua");
local VirtualConnection = NPL.load("./VirtualConnection.lua");

local RPCVirtualConnection = commonlib.inherit(VirtualConnection, {});
local __neuron_file__ = "Mod/GeneralGameServerMod/CommonLib/RPC.lua";
RPCVirtualConnection:Property("RemoteNeuronFile", __neuron_file__);       -- 对端处理文件
RPCVirtualConnection:Property("LocalNeuronFile", __neuron_file__);        -- 本地处理文件
CommonLib.AddPublicFile(__neuron_file__);

function RPCVirtualConnection:GetVirtualConnection(msg)
    return self;
end

local __request_id__ = 0;
function RPCVirtualConnection:Request(action, data, callback)
    __request_id__ = __request_id__ + 1;
    local __request_event_type__ = stirng.format("__rpc_%s_%s__", __request_id__, action);
    local __response_event_type__ = stirng.format("__rpc_%s__", action);
    self:SendMsg({
        __cmd__ = "__rpc__",
        __request_event_type__ = __request_event_type__,
        __response_event_type__ = __response_event_type__,
        __data__ = data,
    }, function()
        self.__event_emitter__:RegisterOnceEventCallBack(__event_type__, callback);
    end);
end

function RPCVirtualConnection:Response(action, callback)
    if (type(callback) ~= "function") then return end

    local __response_event_type__ = stirng.format("__rpc_%s__", action);
    self.__event_emitter__:RegisterEventCallBack(__response_event_type__, function(msg)
        local __request_event_type__ = msg.__request_event_type__;
        local __data__ = callback(msg.__data__);
        self:SendMsg({
            __cmd__ = "__rpc__",
            __request_event_type__ = __response_event_type__,
            __response_event_type__ = __request_event_type__,
            __data__ = __data__,
        });
    end);
end

function RPCVirtualConnection:HandleMsg(msg)
    local __cmd__ = msg.__cmd__;

    if (__cmd__ == "__rpc__") then
        self.__event_emitter__:TriggerEventCallBack(msg.__response_event_type__, msg);
    else
        RPCVirtualConnection._super.HandleMsg(msg);
    end
end

RPCVirtualConnection:InitSingleton();

NPL.this(function()
    RPCVirtualConnection:OnActivate(msg);
end);

local RPC = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

RPC:Property("Nid");

function RPC:ctor()
end

function RPC:Init(ip, port)
    self:SetNid(CommonLib.AddNPLRuntimeAddress(ip, port));
    return self;
end

function RPC:GetAction(method)
    return string.format("%s_%s", tostring(self), tostring(method));
end

function RPC:Register(method, callback)
    RPCVirtualConnection:Response(self:GetAction(method), callback);
end

function RPC:Call(method, data, callback)
    RPCVirtualConnection:SetNid(self:GetNid());
    RPCVirtualConnection:Request(self:GetAction(method), data, callback);
end
