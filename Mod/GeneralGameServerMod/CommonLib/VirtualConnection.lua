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

VirtualConnection.RegisterDisconnectedCallBack = Connection.RegisterDisconnectedCallBack;
VirtualConnection.RemoveDisconnectedCallBack = Connection.RemoveDisconnectedCallBack;
VirtualConnection.RegisterConnectedCallBack = Connection.RegisterConnectedCallBack;
VirtualConnection.RemoveConnectedCallBack = Connection.RemoveConnectedCallBack;

function VirtualConnection:ctor()
end

function VirtualConnection:GetKey(address)
    local nid = address and address.__nid__ or self:GetNid();
    local localThreadName = address and address.__local_thread_name__ or self:GetLocalThreadName();
    local localNeuronFile = address and address.__local_neuron_file__ or self:GetLocalNeuronFile();
    local remoteThreadName = address and address.__remote_thread_name__ or self:GetRemoteThreadName();
    local remoteNeuronFile = address and address.__remote_neuron_file__ or self:GetRemoteNeuronFile();
    return string.format("%s_%s_%s_%s_%s", nid or "nil", localThreadName or "nil", localNeuronFile or "nil", remoteThreadName or "nil", remoteNeuronFile or "nil");
end

function VirtualConnection:New(address)
    return self.singletonInited and self:Init(address) or self:new():Init(address);
end

function VirtualConnection:Clear()
    __all_virtual_connection__ = {};
end

function VirtualConnection:IsExist(address)
    return __all_virtual_connection__[self:GetKey(address)] ~= nil;
end

function VirtualConnection:GetVirtualConnection(address)
    local key = self:GetKey(address);
    if (__all_virtual_connection__[key]) then return __all_virtual_connection__[key] end
    -- print("VirtualConnection:GetVirtualConnection", key);
    local virtual_connection = self:New(address);
    __all_virtual_connection__[self:GetKey()] = virtual_connection;
    return virtual_connection;
end

-- 获取网络地址
function VirtualConnection:GetVirtualAddress()
    return commonlib.serialize_compact({
        __local_neuron_file__ = self:GetLocalNeuronFile(),
        __local_thread_name__ = self:GetLocalThreadName(),
        __remote_neuron_file__ = self:GetRemoteNeuronFile(),
        __remote_thread_name__ = self:GetRemoteThreadName(),
        __nid__ = self:GetNid(),
    });
end

-- 设置网络地址
function VirtualConnection:SetVirtualAddress(address)
    address = type(address) == "string" and NPL.LoadTableFromString(address) or address;

    if (type(address) ~= "table") then 
        __all_virtual_connection__[self:GetKey()] = nil;
        return 
    end 

    self:SetNid(address and address.__nid__ or self:GetNid());
    __all_virtual_connection__[self:GetKey()] = nil;
    self:SetLocalNeuronFile(address and address.__local_neuron_file__ or self:GetLocalNeuronFile());
    self:SetLocalThreadName(address and address.__local_thread_name__ or self:GetLocalThreadName());
    self:SetRemoteNeuronFile(address and address.__remote_neuron_file__ or self:GetRemoteNeuronFile());
    self:SetRemoteThreadName(address and address.__remote_thread_name__ or self:GetRemoteThreadName());
    __all_virtual_connection__[self:GetKey()] = self;
end

function VirtualConnection:SetNid(nid)
    if (self.__nid__ == nid) then return end 
    local old_connection = self:GetConnection();
    if (old_connection) then 
        old_connection:OffDisconnected(self.__disconnected_callback__, self);
        old_connection:OffClosed(self.__closed_callback__, self);
        old_connection:RemoveVirtualConnection(self);
    end 
    __all_virtual_connection__[self:GetKey()] = nil;             -- 移除旧地址

    self.__nid__ = nid;
    local new_connection = self:GetConnection();
    if (new_connection) then 
        new_connection:OnDisconnected(self.__disconnected_callback__, self);
        new_connection:OnClosed(self.__closed_callback__, self);
        new_connection:AddVirtualConnection(self);
    end 
    __all_virtual_connection__[self:GetKey()] = self;            -- 设置新地址
end

function VirtualConnection:GetNid()
    return self.__nid__;
end

function VirtualConnection:GetConnection()
    if (not self:GetNid()) then return end
    return Connection:GetConnectionByNid(self:GetNid());
end

function VirtualConnection:ctor()
	self.__event_emitter__ = EventEmitter:new();       -- 事件触发器
    self.__disconnected_callback__ = function(msg)
        self:HandleDisconnected(msg);
	end
    self.__closed_callback__ = function()
        self:HandleClosed();
    end
end

function VirtualConnection:Init(opts)
    self:SetVirtualAddress(opts);
    return self;
end

function VirtualConnection:OnConnected(...)
    self.__event_emitter__:RegisterEventCallBack("__connected__", ...);
end

function VirtualConnection:OffConnected(...)
    self.__event_emitter__:RemoveEventCallBack("__connected__", ...);
end

function VirtualConnection:HandleConnected()
    self.__event_emitter__:TriggerEventCallBack("__connected__");
end

function VirtualConnection:OnClosed(...)
    self.__event_emitter__:RegisterEventCallBack("__closed__", ...);
end

function VirtualConnection:OffClosed(...)
    self.__event_emitter__:RemoveEventCallBack("__closed__", ...);
end

function VirtualConnection:HandleClosed()
    self:SetVirtualAddress(nil); 
    self.__event_emitter__:TriggerEventCallBack("__closed__");
end

function VirtualConnection:Close()
    self:SendMsg({__cmd__ = "__close_connect__"});
    self:SetNid(nil);
    self:HandleClosed();
end

function VirtualConnection:CloseConnection()
    if (self:GetConnection()) then self:GetConnection():Close() end 
    -- 由底层触发调用
    -- self:Close();
end

function VirtualConnection:Connect(callback)
    -- 已经连接直接执行回调退出
    if (self:IsConnected()) then return type(callback) == "function" and callback() end 

    -- 注册事件回调
    self.__event_emitter__:RegisterEventCallBack("__connected__", callback);
    
    -- 如果正在连接则直接跳出
    if (self:IsConnecting()) then return end
    
    -- 标记正在连接
    self:SetConnecting(true);

    -- 发送消息
    self:SendMsg({__cmd__ = "__request_connect__"}, function()
        self:SetConnected(true);
        self:SetConnecting(false);
        self:HandleConnected();
    end);
end

-- 发送消息无视是否连接
function VirtualConnection:SendMsg(msg, callback)
    -- 发送前确保当前地址信息
    msg.__local_neuron_file__ = self:GetLocalNeuronFile();
    msg.__local_thread_name__ = self:GetLocalThreadName();
    msg.__remote_neuron_file__ = self:GetRemoteNeuronFile();
    msg.__remote_thread_name__ = self:GetRemoteThreadName();
    msg.__nid__ = self:GetNid();
    -- print("VirtualConnection:SendMsg", self:GetRemoteAddress());
    local connection = self:GetConnection();
    if (connection) then connection:Send(msg, self:GetRemoteThreadName(), self:GetRemoteNeuronFile(), callback) end
end

function VirtualConnection:Send(data, callback)
    if (not self:IsConnected()) then return end 
    self:SendMsg({__data__ = data, __cmd__ = "__msg__"}, callback);
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

function VirtualConnection:HandleMsg(msg)
    self.__event_emitter__:TriggerEventCallBack("__msg__", msg.__data__);
end

function VirtualConnection:RegisterEventCallBack(...)
	self.__event_emitter__:RegisterEventCallBack(...);
end

function VirtualConnection:TriggerEventCallBack(...)
	self.__event_emitter__:TriggerEventCallBack(...);
end

function VirtualConnection:OnActivate(msg)
    local __nid__ = msg and (msg.nid or msg.tid);
    if (not __nid__) then return end
    -- 根据对端地址信息, 构建对应的地址信息
    local __local_neuron_file__ = msg.__remote_neuron_file__;
    local __local_thread_name__ = msg.__remote_thread_name__;
    local __remote_neuron_file__ = msg.__local_neuron_file__;
    local __remote_thread_name__ = msg.__local_thread_name__;
    msg.__nid__ = __nid__;
    msg.__local_neuron_file__ = __local_neuron_file__;
    msg.__local_thread_name__ = __local_thread_name__;
    msg.__remote_neuron_file__ = __remote_neuron_file__;
    msg.__remote_thread_name__ = __remote_thread_name__;

    local virtual_connection = self:GetVirtualConnection(msg);
    if (not virtual_connection:IsConnected()) then
        virtual_connection:SetConnected(true);
        virtual_connection:HandleConnected();
        -- virtual_connection:SendMsg({__cmd__ = "__response_connect__"});
    end

    local __cmd__ = msg.__cmd__;
    if (__cmd__ == "__request_connect__") then
    elseif (__cmd__ == "__response_connect__") then
    elseif (__cmd__ == "__close_connect__") then
        virtual_connection:HandleClosed();
    else
        virtual_connection:HandleMsg(msg);
    end

    return virtual_connection;
end

NPL.this(function()
    VirtualConnection:OnActivate(msg);
end)