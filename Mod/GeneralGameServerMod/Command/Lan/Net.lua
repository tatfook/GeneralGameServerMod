--[[
Title: Net
Author(s):  wxa
Date: 2020-06-12
Desc: Net
use the lib:
------------------------------------------------------------
local Net = NPL.load("Mod/GeneralGameServerMod/Command/Lan/Net.lua");
------------------------------------------------------------
]]


local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local RPC = NPL.load("Mod/GeneralGameServerMod/CommonLib/RPC.lua", IsDevEnv);

local Net =  commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Net:Property("Lan");                                    -- 局域网对象
Net:Property("ConnectionCount", 0);                     -- 链接数
Net:Property("EnableServer", false, "IsEnableServer");  -- 是否开启服务端功能
Net:Property("EnableClient", false, "IsEnableClient");  -- 是否开启客户端功能
Net:Property("ClientNid");                              -- 客户端NID
Net:Property("ServerKey");                              -- 客户端存贮服务器KEY
Net:Property("Connected", false, "IsConnected");        -- 是否已连接

local __rpc__ = RPC:GetModule("Net");           -- Net RPC
local __all_connections__ = {};                 -- 服务器保存的所有客户端连接

-----------------------------------------server----------------------------------
-- 用户登录
__rpc__:Register("Login", function(data)
    local connection = Net:GetCurrentConnection();
    connection.last_tick_at = CommonLib.GetTimeStamp();

    -- Net:ServerTick();
    -- print("=============login===========")
    connection.userinfo = data or {};
    connection.userinfo.ip = Net:GetIP();
    -- print("-------------------------------", connection.key, connection.nid)
    return connection.key;
end);

-- 心跳
__rpc__:Register("Tick", function(data)
    local connection = Net:GetCurrentConnection();
    connection.last_tick_at = CommonLib.GetTimeStamp();
    commonlib.partialcopy(connection.userinfo, data.userinfo);
    connection.appHasFocus = data.appHasFocus;
end);

-- 写文件
__rpc__:Register("WriteFile", function(data)
    CommonLib.WriteFile(data.filename, data.text);
end);

-- 用于判断服务器是否可用
__rpc__:Register("isAlive", function(data)
    return true
end);

----------------------------------------client-------------------------------------
function Net:Broadcast(action, data, callback)
    for _, connection in pairs(self:GetAllConnection()) do
        __rpc__:SetVirtualAddress(connection.virtual_address);
        __rpc__:Call(action, data, callback);
    end
end

function Net:Login(data, callback)
    -- print("============================user:login===============================");
    self:SetConnected(false);
    __rpc__:Call("Login", self:GetClientUserInfo(), function(key)
        self:SetServerKey(key);
        self:SetConnected(true);
        if (type(callback) == "function") then callback() end 
        print("====================login success=======================", key);
    end);
end

function Net:IsServer()
    if self:GetLan() then 
        return self:GetLan():IsServer();
    else
        return self._isServer
    end
end

function Net:ServerTick()
    local cur_timestamp = CommonLib.GetTimeStamp();
    local offline_timestamp = cur_timestamp - 1000 * 60 * 2;
    local offline_list = {};
    local all_connections = self:GetAllConnection();
    local connection_count = 0;
    for key, connection in pairs(all_connections) do
        if (connection.last_tick_at < offline_timestamp) then
            table.insert(offline_list, key);
        else 
            connection_count = connection_count + 1;
        end
    end

    for _, key in ipairs(offline_list) do
        all_connections[key] = nil;
    end

    self:SetConnectionCount(connection_count);
    -- print('---------------------------', connection_count);
end

function Net:GetClientUserInfo()
    -- return self:GetLan():GetUserInfo();
    local Keepwork = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua");
    return {
        username = Keepwork:GetUserName() or (IsDevEnv and tostring(ParaGlobal.timeGetTime()) or nil),
        nickname = Keepwork:GetNickName(),
        classname = Keepwork:GetGradeClassName(),
        worldId = Keepwork:GetCurrentWorldID(),
        worldName = Keepwork:GetCurrentWorldName();
    };
end

function Net:ClientTick()
    self:ClientCall("Tick", {
        userinfo = self:GetClientUserInfo(),
        appHasFocus = ParaEngine.GetAttributeObject():GetField("AppHasFocus", true),
    });    
end

function Net:CopyFile(src_file, dst_file, calback)
    __rpc__:Call("WriteFile", {
        filename = dst_file,
        text = CommonLib.GetFileText(src_file),
    }, callback);
end

function Net:SetServerIpAndPort(ip, port)
    local nid = CommonLib.AddNPLRuntimeAddress(ip, port)
    if __rpc__:GetNid()~=nid then
        __rpc__:SetNid(nid);
    end
end

function Net:IsValidVirtualAddress()
end

function Net:GetUserInfo(key)
    local connection = key and __all_connections__[key] or self:GetCurrentConnection();
    return connection.userinfo;
end

function Net:GetCurrentConnection()
    local virtual_address = __rpc__:GetVirtualAddress();
    local nid = __rpc__:GetNid();
    local key = CommonLib.MD5(virtual_address);
    if (__all_connections__[key]) then return __all_connections__[key] end 

    local connection = {
        key = key,
        virtual_address = virtual_address,
        ip = nid and NPL.GetIP(nid),
        nid = nid,
        appHasFocus = true,
        userinfo = {},
    };
    
    if (nid) then __all_connections__[key] = connection end 

    return connection;
end

--作为服务器主动给某个客户端发消息
function Net:CallClientByKey(key,...)
    local connection = __all_connections__[key];
    -- print("----CallClientByKey,key:",key,"connection",connection)
    -- echo(connection,true)
    if connection then
        local __rpc_ = self:GetRPC();
        local old_nid = __rpc__:GetNid();
        if old_nid~=connection.nid then
            __rpc__:SetNid(connection.nid);
            __rpc_:Call(...);
            __rpc__:SetNid(old_nid);
        else
            __rpc_:Call(...);
        end
        return true 
    else
        return false
    end
end

function Net:GetAllConnection()
    return __all_connections__;
end

function Net:GetKey()
    return CommonLib.MD5(__rpc__:GetVirtualAddress());
end

function Net:GetRPC()
    return __rpc__;
end

function Net:GetIP()
    return NPL.GetIP(self:GetRPC():GetNid());
end

function Net:Register(...)
    return self:GetRPC():Register(...);
end

function Net:Call(...)
    return self:GetRPC():Call(...);
end

function Net:ClientCall(...)
    if (not self:IsConnected()) then return end 
    local __rpc_ = self:GetRPC();
    local old_nid = __rpc__:GetNid();
    __rpc__:SetNid(self:GetClientNid());
    __rpc_:Call(...);
    __rpc__:SetNid(old_nid);
end

function Net:ctor()
end

function Net:Init()
end

function Net:StartServer()
    self._isServer = true
    if (not self.__server_tick_timer__) then
        self.__server_tick_timer__ = CommonLib.SetInterval(1000 * 60, function()
            self:ServerTick();
        end);
    end
end

function Net:StopServer()
    self._isServer = nil
    -- self.__server_tick_timer__:Change();
end

function Net:StartClient(ip, port, callback)
    self._isClient = true
    if (not ip) then return self:SetConnected(false) end 
    
    -- -- 禁止自己连自己
    -- local att = NPL.GetAttributeObject();
    -- local ips = att:GetField("ExternalIPList", "");
    -- local isExist = string.find(ips, ip, 1, true);
    -- if (isExist ~= nil) then return end

    self:SetClientNid(CommonLib.AddNPLRuntimeAddress(ip, port));
    __rpc__:SetNid(self:GetClientNid());

    self:Login(nil,callback);

    if (not self.__client_tick_timer__) then
        self.__client_tick_timer__ = CommonLib.SetInterval(1000 * 60, function()
            self:ClientTick();
        end);
    end
end

function Net:StopClient()
    self._isClient = nil
end

function Net:CheckServerAlive(callback,second)
    second = second or 5
    local timer = commonlib.TimerManager.SetTimeout(function()
        if callback then 
            callback(false)
        end
    end,second*1000)
    __rpc__:Call("isAlive", nil, function(bool)
        print("--------server isAlive?",bool)
        callback(true)
        callback = nil
        timer:Change()
    end);
end

function Net:CheckClientAlive(key,callback,second)
    second = second or 30
    local timer = commonlib.TimerManager.SetTimeout(function()
        LOG.std(nil, "waring", "UpdateSyncer.s.Net", "2 CheckClientAlive timeout,second:%s", second);
        if callback then 
            callback(false)
        end
    end,second*1000)
    LOG.std(nil, "waring", "UpdateSyncer.s.Net", "1 CheckClientAlive timeout,second:%s", second);
    self:CallClientByKey(key,"isAlive", nil, function(bool)
        LOG.std(nil, "waring", "UpdateSyncer.s.Net", "3 CheckClientAlive isAlive:%s", bool and "true" or "false");
        callback(true)
        callback = nil
        timer:Change()
    end);
end

RPC.RegisterDisconnectedCallBack(function(msg)
    local __nid__ = msg.__nid__;
    -- print("==========================RegisterDisconnectedCallBack==============================", Net:IsServer(), Net)
    if (Net:IsServer()) then
        local list = {};
        for key, connection in pairs(__all_connections__) do
            if (connection.nid == __nid__) then
                table.insert(list, key);
            end
        end
        for _, key in ipairs(list) do
            __all_connections__[key] = nil;
        end
    else 
        if (__nid__ == Net:GetClientNid()) then
            -- client offline
            -- print("============================client offline===========================", Net, __nid__);
            Net:SetEnableClient(false);
            Net:SetConnected(false);
        end
    end

end);

Net:InitSingleton():Init();