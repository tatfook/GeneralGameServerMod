--[[
Title: RPCVirtualConnection
Author(s): wxa
Date: 2020/6/12
Desc: virtual connection
复用 Connection 方便不同文件之间通信只使用一条连接 
-------------------------------------------------------
local RPCVirtualConnection = NPL.load("Mod/GeneralGameServerMod/CommonLib/RPCVirtualConnection.lua");
-------------------------------------------------------
]]
local CommonLib = NPL.load("./CommonLib.lua");
local VirtualConnection = NPL.load("./VirtualConnection.lua");
local RPCVirtualConnection = commonlib.inherit(VirtualConnection, NPL.export());

local __neuron_file__ = "Mod/GeneralGameServerMod/CommonLib/RPCVirtualConnection.lua";
RPCVirtualConnection:Property("RemoteNeuronFile", __neuron_file__);       -- 对端处理文件
RPCVirtualConnection:Property("LocalNeuronFile", __neuron_file__);        -- 本地处理文件

CommonLib.AddPublicFile(__neuron_file__);

local __request_id__ = 0;
function RPCVirtualConnection:Request(action, data, callback)
    __request_id__ = __request_id__ + 1;
    local __request_event_type__ = string.format("__rpc_%s_%s__", __request_id__, action);
    local __response_event_type__ = string.format("__rpc_%s__", action);
    self:SendMsg({
        __cmd__ = "__rpc__",
        __action__ = action,
        __request_event_type__ = __request_event_type__,
        __response_event_type__ = __response_event_type__,
        __data__ = data,
    }, function()
        self.__event_emitter__:RegisterOnceEventCallBack(__request_event_type__, function(msg)
            return type(callback) == "function" and callback(msg.__data__);
        end);
    end);
end

function RPCVirtualConnection:Response(action, callback)
    if (type(callback) ~= "function") then return end
    local __response_event_type__ = string.format("__rpc_%s__", action);
    self.__event_emitter__:RegisterEventCallBack(__response_event_type__, function(msg)
        local __request_event_type__, __action__ = msg.__request_event_type__, msg.__action__;
        local __data__ = callback(msg.__data__);
        self:SendMsg({
            __cmd__ = "__rpc__",
            __action__ = __action__,
            __request_event_type__ = __response_event_type__,
            __response_event_type__ = __request_event_type__,
            __data__ = __data__,
        });
    end);
end

function RPCVirtualConnection:GetActionEventType(action)
    return string.format("__msg_%s__", action);
end

function RPCVirtualConnection:Emit(action, data)
    self:SendMsg({__cmd__ = "__msg__", __event_type__ = self:GetActionEventType(action), __data__ = data});
end

function RPCVirtualConnection:On(action, callback)
    self.__event_emitter__:RegisterEventCallBack(self:GetActionEventType(action), callback);
end

function RPCVirtualConnection:Register(action, callback)
    self:Response(action, callback);
end

function RPCVirtualConnection:Call(action, data, callback)
    self:Request(action, data, callback);
end

function RPCVirtualConnection:HandleRPC(msg)
    -- 触发事件
    if (msg.__response_event_type__) then self.__event_emitter__:TriggerEventCallBack(msg.__response_event_type__, msg) end
    -- 触发方法
    if (type(self[msg.__action__]) == "function") then 
        local __data__ = (self[msg.__action__])(self, msg.__data__);
        self:SendMsg({
            __cmd__ = "__rpc__",
            __action__ = msg.__action__,
            __request_event_type__ = msg.__response_event_type__,
            __response_event_type__ = msg.__request_event_type__,
            __data__ = __data__,
        });
    end
end

function RPCVirtualConnection:HandleMsg(msg)
    local __cmd__ = msg.__cmd__;
    if (__cmd__ == "__rpc__") then
        self:HandleRPC(msg);
    elseif (__cmd__ == "__msg__") then
        self.__event_emitter__:TriggerEventCallBack(msg.__event_type__, msg.__data__);
    else
        RPCVirtualConnection._super.HandleMsg(self, msg);
    end
end

NPL.this(function()
    RPCVirtualConnection:OnActivate(msg);
end);