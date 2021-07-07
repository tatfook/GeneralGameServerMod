--[[
Title: MySql
Author(s):  wxa
Date: 2021-06-30
Desc: MySql
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/CommonLib/Net/Server.lua");
------------------------------------------------------------
]]
local Server = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

function Server:ctor() 
end

function Server:LoadNetworkSettings()
	local att = NPL.GetAttributeObject();
	att:SetField("TCPKeepAlive", true);
	att:SetField("KeepAlive", true);
	att:SetField("IdleTimeout", false);
	att:SetField("IdleTimeoutPeriod", 1200000);

	NPL.SetUseCompression(true, true);
	att:SetField("CompressionLevel", -1);
	att:SetField("CompressionThreshold", 1024*4);
	
	att:SetField("UDPIdleTimeoutPeriod", 1200000);
	att:SetField("UDPCompressionLevel", -1);
	att:SetField("UDPCompressionThreshold", 1024*16);
	__rts__:SetMsgQueueSize(500);
end

-- 启动服务
function Server:Start(ip, port) 
	if (self.__is_start__) then return end 

    -- 设置系统属性
    self:LoadNetworkSettings();

	-- 启动服务
	if (NPL.GetAttributeObject():GetField("IsServerStarted", false)) then
		NPL.StartNetServer(ip or "0.0.0.0", tostring(port or "9000"));
	end

	-- 主循环
	commonlib.Timer:new({callbackFunc = function() GeneralGameServer:Tick() end}):Change(1000, 1000);

	self.__is_start__ = true;
end


function Server:Tick()
end

Server:InitSingleton();