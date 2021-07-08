--[[
Title: VirtualConnection
Author(s): wxa
Date: 2020/6/12
Desc: virtual connection
复用 Connection 方便不同文件之间通信只使用一条连接 
-------------------------------------------------------
local VirtualConnection = NPL.load("Mod/GeneralGameServerMod/CommonLib/VirtualConnection.lua");
-------------------------------------------------------
]]

local EventEmitter = NPL.load("Mod/GeneralGameServerMod/CommonLib/EventEmitter.lua");
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local Connection = NPL.load("Mod/GeneralGameServerMod/CommonLib/Connection.lua");

local VirtualConnection = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local __neuron_file__ = "Mod/GeneralGameServerMod/CommonLib/VirtualConnection.lua";

VirtualConnection:Property("RemoteThreadName", "main");                -- 对端线程
VirtualConnection:Property("LocalThreadName", "main");                 -- 本地线程
VirtualConnection:Property("RemoteNeuronFile", __neuron_file__);       -- 对端处理文件
VirtualConnection:Property("LocalNeuronFile", __neuron_file__);        -- 本地处理文件
VirtualConnection:Property("Connected", false, "IsConnected");         -- 是否链接
VirtualConnection:Property("Connecting", false, "IsConnecting");       -- 是否正在链接

CommonLib.AddPublicFile(__neuron_file__);

local __all_virtual_connection__ = {};

function VirtualConnection:GetKey(opts)
    local nid = opts and opts.__nid__ or self:GetNid();
    local localThreadName = opts and opts.__local_thread_name__ or self:GetLocalThreadName();
    local localNeuronFile = opts and opts.__local_neuron_file__ or self:GetLocalNeuronFile();
    local remoteThreadName = opts and opts.__remote_thread_name__ or self:GetRemoteThreadName();
    local remoteNeuronFile = opts and opts.__remote_neuron_file__ or self:GetRemoteNeuronFile();
    return string.format("%s_%s_%s_%s_%s", nid, localThreadName, localNeuronFile, remoteThreadName, remoteNeuronFile);
end

function VirtualConnection:GetVirtualConnection(msg)
    local key = self:GetKey(msg);
    if (__all_virtual_connection__[key]) then return __all_virtual_connection__[key] end
    local virtual_connection = self:new():Init(msg);
    __all_virtual_connection__[key] = virtual_connection;
    return virtual_connection;
end

function VirtualConnection:SetNid(nid)
    if (self.__nid__ == nid) then return end 
    local old_connection = self:GetConnection();
    if (old_connection) then old_connection:OffDisconnected(self.__disconnected_callback__, self) end 
    self.__nid__ = nid;
    local new_connection = self:GetConnection();
    if (new_connection) then new_connection:OnDisconnected(self.__disconnected_callback__, self) end 
end

function VirtualConnection:GetNid()
    return self.__nid__ ;
end

function VirtualConnection:GetConnection()
    if (not self:GetNid()) then return end
    return Connection:GetConnectionByNid(self:GetNid());
end

function VirtualConnection:ctor()
	self.__event_emitter__ = EventEmitter:new();       -- 事件触发器
end

function VirtualConnection:Init(opts)
    if (opts.__remote_neuron_file__) then self:SetRemoteNeuronFile(opts.__remote_neuron_file__) end
    if (opts.__local_neuron_file__) then self:SetLocalNeuronFile(opts.__local_neuron_file__) end
    if (opts.__remote_thread_name__) then self:SetRemoteThreadName(opts.__remote_thread_name__) end
    if (opts.__local_thread_name__) then self:SetRemoteThreadName(opts.__local_thread_name__) end

    self.__disconnected_callback__ = function(msg)
        self:HandleDisconnected(msg);
	end

    self:SetNid(opts.__nid__);

    return self;
end

function VirtualConnection:OnConnected(...)
    self.__event_emitter__:RegisterEventCallBack("__connect__", ...);
end

function VirtualConnection:OffConnected(...)
    self.__event_emitter__:RemoveEventCallBack("__connect__", ...);
end

function VirtualConnection:Connect(callback)
    -- 已经连接直接执行回调退出
    if (self:IsConnected()) then return type(callback) == "function" and callback() end 

    -- 如果正在连接则直接跳出
    if (self:IsConnecting()) then return self.__event_emitter__:RegisterOnceEventCallBack("__connect__", callback) end
    
    -- 标记正在连接
    self:SetConnecting(true);

    self:GetConnection():Send({
        __remote_thread_name__ = self:GetLocalThreadName(),
        __remote_neuron_file__ = self:GetLocalNeuronFile(),
    }, self:GetRemoteThreadName(), self:GetRemoteNeuronFile(), function()
        self:SetConnected(true);
        self:SetConnecting(false);
        -- 触发连接回调
        self.__event_emitter__:TriggerEventCallBack("__connect__");
        return type(callback) == "function" and callback();
    end);
end

function VirtualConnection:Send(msg, callback)
    if (not self:IsConnected()) then return end 
    self:GetConnection():Send(msg, self:GetRemoteThreadName(), self:GetRemoteNeuronFile(), callback);
end

function VirtualConnection:OnDisconnected(...)
    self.__event_emitter__:RegisterEventCallBack("__disconnected__", ...)
end

function VirtualConnection:OffDisconnected(...)
    self.__event_emitter__:RemoveEventCallBack("__disconnected__", ...)
end

function VirtualConnection:HandleDisconnected(...)
    self:SetConnected(false);
    self.__event_emitter__:TriggerEventCallBack("__disconnected__", ...);
end

function VirtualConnection:OnMsg(...)
    self.__event_emitter__:RegisterEventCallBack("__msg__", ...);
end

function VirtualConnection:OffMsg(...)
    self.__event_emitter__:RemoveEventCallBack("__msg__", ...);
end

function VirtualConnection:HandleMsg(...)
    self.__event_emitter__:TriggerEventCallBack("__msg__", ...);
end

function VirtualConnection:CloseConnection()
    self:GetConnection():Close();
end

function VirtualConnection:OnActivate(msg)
    msg.__nid__ = msg and (msg.nid or msg.tid);
    local virtual_connection = self:GetVirtualConnection(msg);
    virtual_connection:SetConnected(true);
    virtual_connection:HandleMsg(msg);
end

NPL.this(function()
	local nid = msg and (msg.nid or msg.tid);
    if (not nid) then return end
    VirtualConnection:OnActivate(msg);
end)