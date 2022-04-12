--[[
Title: Broadcast
Author(s): wxa
Date: 2020/6/12
Desc: 局域网广播
use the lib:
-------------------------------------------------------
local Broadcast = NPL.load("Mod/GeneralGameServerMod/CommonLib/Broadcast.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/System.lua");

local EventEmitter = NPL.load("Mod/GeneralGameServerMod/CommonLib/EventEmitter.lua");
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");

local Broadcast = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
Broadcast:Property("UDPServerStarted", false, "IsUDPServerStarted");
Broadcast:Property("DefaultPort", 8099);  -- 默认端口
Broadcast:Property("UUID");

function Broadcast:StartUDPServer()
    if (self:IsUDPServerStarted()) then return end

	local att = NPL.GetAttributeObject();

	-- start udp server
	local port = self:GetDefaultPort();
	local i = 0;
	while (not att:GetField("IsUDPServerStarted") and i <= 20) do
		att:SetField("EnableUDPServer", port + i);
		i = i + 1;
	end

    self:SetUUID(System.Encoding.guid.uuid());
	self:SetUDPServerStarted(true)
end

function Broadcast:ctor()
    self.__event_emitter__ = EventEmitter:new();
end

function Broadcast:Init()
end

function Broadcast:SendBroadcaseMsg(eventName,msg)
    if eventName==nil or eventName=="" then 
        return
    end
    if (not self:IsUDPServerStarted()) then self:StartUDPServer() end 

    local att = NPL.GetAttributeObject();
	local broadcastAddressList = att:GetField("BroadcastAddressList");
	broadcastAddressList = commonlib.split(broadcastAddressList, ",");

	local defaultPort = self:GetDefaultPort();

	for i = 0, 20 do
		local port = defaultPort + i
		-- broadcast all host
		local serverAddrList = { "(gl)*" .. port .. ":Mod/GeneralGameServerMod/CommonLib/Broadcast.lua" };

        for key, value in pairs(broadcastAddressList) do
			table.insert(serverAddrList, string.format("(gl)\\\\%s %d:Mod/GeneralGameServerMod/CommonLib/Broadcast.lua", value, port));
		end

		for key, value in pairs(serverAddrList) do
			NPL.activate(value, { 
                __uuid__ = self:GetUUID(),
                __GGS_UDP_BROADCAST__ = true,  -- 防止其它广播消息干扰
                __data__ = {eventName=eventName,msg=msg},
            }, 1, 2, 0);
		end
	end
end

function Broadcast:SendMsg(eventName,msg, ip, port)
    if eventName==nil or eventName=="" then 
        return
    end
    if (not ip or not port) then return end
    local url = string.format("(gl)\\\\%s %d:Mod/GeneralGameServerMod/CommonLib/Broadcast.lua", ip, port)
	NPL.activate(url, {
        __uuid__ = self:GetUUID(),
        __GGS_UDP_BROADCAST__ = true, 
        __data__ = {eventName=eventName,msg=msg},
    } , 1, 2, 0);
end

function Broadcast:RecvBroadcaseMsg(msg)
    if (type(msg) ~= "table" or not msg.__GGS_UDP_BROADCAST__ or msg.__uuid__ == self:GetUUID()) then return end --
    local ip, port = string.match(msg.nid, "~udp(.+)_(%d+)");
    if msg.__data__.eventName then
        msg.ip = ip
        msg.port = port
        self:TriggerBroadcaseEvent(msg.__data__.eventName, msg);
    end
end

function Broadcast:TriggerBroadcaseEvent(...)
    self.__event_emitter__:TriggerEventCallBack(...)
end

function Broadcast:RegisterBroadcaseEvent(...)
    self.__event_emitter__:RegisterEventCallBack(...);
end

function Broadcast:RemoveBroadcaseEvent(...)
    self.__event_emitter__:RemoveEventCallBack(...);
end

Broadcast:InitSingleton():Init();

NPL.this(function()
    Broadcast:RecvBroadcaseMsg(msg);
end);