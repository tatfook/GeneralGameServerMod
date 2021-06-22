--[[
Title: ServerConnection
Author(s): wxa
Date: 2020/6/10
Desc: 线程辅助类
use the lib: 
-------------------------------------------------------
local AppServerDataHandler = NPL.load("Mod/GeneralGameServerMod/App/Server/AppServerDataHandler.lua");
-------------------------------------------------------
]]

-- 数据处理基类
local ServerDataHandler = NPL.load("Mod/GeneralGameServerMod/Core/Server/ServerDataHandler.lua");
-- GI 数据处理类
local GIServerDataHandler = NPL.load("Mod/GeneralGameServerMod/GI/Game/GGS/GIServerDataHandler.lua");
-- 数据处理导出类
local AppServerDataHandler = commonlib.inherit(ServerDataHandler, NPL.export());

AppServerDataHandler:Property("GIServerDataHandler");

function AppServerDataHandler:Init(netHandler)
	AppServerDataHandler._super.Init(self, netHandler);
	self:SetGIServerDataHandler(GIServerDataHandler:new():Init(netHandler));

	return self;
end

-- 收到数据处理函数
function AppServerDataHandler:RecvData(data)
	local handler = type(data) == "table" and data.__handler__;

	if (handler == self:GetGIServerDataHandler():GetHandlerName()) then
		return self:GetGIServerDataHandler():RecvData(data);
	end

	self:SendDataToAllPlayer(data);
end

-- 掉线处理
function AppServerDataHandler:OnDisconnect()
	self:GetGIServerDataHandler():OnDisconnect();
end