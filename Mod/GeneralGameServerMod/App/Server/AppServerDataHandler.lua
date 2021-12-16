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

-- 数据处理导出类
local AppServerDataHandler = commonlib.inherit(ServerDataHandler, NPL.export());

-- 实体包
local AllWorldEntityMap = {};

function AppServerDataHandler:Init(netHandler)
	AppServerDataHandler._super.Init(self, netHandler);

	return self;
end

function AppServerDataHandler:GetAllEntityMap(worldKey)
	worldKey = worldKey or self:GetWorldKey();
	AllWorldEntityMap[worldKey] = AllWorldEntityMap[worldKey] or {};
	return AllWorldEntityMap[worldKey];
end

-- 收到数据处理函数
function AppServerDataHandler:RecvData(data)
	if (type(data) == "table" and data.cmd == "SyncEntityLiveModel") then
		if (data.action == "delete") then 
			self:GetAllEntityMap()[data.key] = nil; 
		elseif (data.action == "pull_all") then
			local worldKey = self:GetWorldKey();
			data.packet = AllWorldEntityMap[worldKey];
			return self:SendDataToPlayer(data);
		else 
			self:GetAllEntityMap()[data.key] = data.packet;
		end 
	end

	self:SendDataToAllPlayer(data);
end

-- 掉线处理
function AppServerDataHandler:OnDisconnect()
	local onlinePlayerCount = self:GetWorld():GetOnlineClientCount();
	if (onlinePlayerCount == 0) then
		local worldKey = self:GetWorldKey();
		AllWorldEntityMap[worldKey] = nil;
	end
end