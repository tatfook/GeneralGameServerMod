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

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local Connection = NPL.load("Mod/GeneralGameServerMod/CommonLib/Connection.lua", IsDevEnv);
local VirtualConnection = NPL.load("Mod/GeneralGameServerMod/CommonLib/VirtualConnection.lua", IsDevEnv);
local RPCVirtualConnection = NPL.load("Mod/GeneralGameServerMod/CommonLib/RPCVirtualConnection.lua", IsDevEnv);

local RPCAPI = NPL.export()

setmetatable(RPCAPI, {__call = function(_, CodeEnv)
    local __rpc_virtual_connection__ = RPCVirtualConnection:GetVirtualConnection({
        __remote_neuron_file__ = "Mod/GeneralGameServerMod/Server/Net/RPC.lua",
    });
    
    CodeEnv.__rpc_virtual_connection__ = __rpc_virtual_connection__;

    CodeEnv.RPC_Register = function(method, callback) 
        __rpc_virtual_connection__:Register(method, callback);
    end

    CodeEnv.RPC_Call = function(method, data, callback)
        __rpc_virtual_connection__:Call(method, data, callback);
    end

    CodeEnv.RPC_Broadcast = function(data)
        __rpc_virtual_connection__:Call("Broadcast", data);
    end

    CodeEnv.RPC_OnBroadcast = function(callback)
        __rpc_virtual_connection__:On("Broadcast", callback);
    end

    CodeEnv.RPC_Emit = function(...)
        __rpc_virtual_connection__:Emit(...);
    end

    CodeEnv.RPC_On = function(...)
        __rpc_virtual_connection__:On(...);
    end

    CodeEnv.RPC_OnDisconnected = function(...)
        __rpc_virtual_connection__:OnDisconnected(...);
    end

    CodeEnv.RPC_OnClosed = function(...)
        __rpc_virtual_connection__:OnClosed(...);
    end

    CodeEnv.RPC_OnConnectClosed = function(...)
        __rpc_virtual_connection__:On("ConnectClosed", ...);
    end
    
    CodeEnv.RegisterEventCallBack(CodeEnv.EventType.NID, function(nid)
        __rpc_virtual_connection__:SetNid(nid);
    end);

    CodeEnv.RegisterEventCallBack(CodeEnv.EventType.CLEAR, function() 
        __rpc_virtual_connection__:CloseConnection();
        RPCVirtualConnection:Clear();
    end);
end});
