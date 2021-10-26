--[[
Title: RPC
Author(s):  wxa
Date: 2020-06-12
Desc: 单例 RPC 只是适用于客户端主动请求, 不适用服务端主动推送事件
use the lib:
------------------------------------------------------------
local RPC = NPL.load("Mod/GeneralGameServerMod/CommonLib/RPC.lua");
------------------------------------------------------------
]]

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local RPCVirtualConnection = NPL.load("Mod/GeneralGameServerMod/CommonLib/RPCVirtualConnection.lua");

local RPC =  commonlib.inherit(RPCVirtualConnection, NPL.export());

local __neuron_file__ = "Mod/GeneralGameServerMod/CommonLib/RPC.lua";
RPC:Property("RemoteNeuronFile", __neuron_file__);       -- 对端处理文件
RPC:Property("LocalNeuronFile", __neuron_file__);        -- 本地处理文件

-- RPC 方法与实现
local RPCModule = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), {});
RPCModule:Property("Module");
RPCModule:Property("RPC");

function RPCModule:GetAction(action)
    return string.format("%s_%s", self:GetModule(), action);
end

function RPCModule:Register(action, callback)
    return RPC:Register(self:GetAction(action), callback);
end

function RPCModule:Call(action, data, callback)
    return RPC:Call(self:GetAction(action), data, callback);
end

function RPCModule:GetNid()
    return RPC:GetNid();
end

function RPCModule:SetNid(...)
    return RPC:SetNid(...);
end

function RPCModule:GetKey()
    return RPC:GetKey();
end

function RPCModule:GetVirtualAddress(...)
    return RPC:GetVirtualAddress(...);
end

function RPCModule:SetVirtualAddress(...)
    return RPC:SetVirtualAddress(...);
end

function RPCModule:Init(rpc, module)
    self:SetRPC(rpc);
    self:SetModule(module);
    
    return self;
end

local __all_modules__ = {};
function RPC:GetModule(module)
    __all_modules__[module] = __all_modules__[module] or RPCModule:new():Init(self, module);
    return __all_modules__[module];
end

RPC:InitSingleton();
NPL.this(function()
    RPC:OnActivate(msg);
end);