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
local AllEntityLiveModelMap = {};

function AppServerDataHandler:Init(netHandler)
	AppServerDataHandler._super.Init(self, netHandler);

	return self;
end

-- 收到数据处理函数
function AppServerDataHandler:RecvData(data)
	if (type(data) == "table" and data.cmd == "SyncEntityLiveModel") then
		local worldKey = self:GetWorldKey();
		AllEntityLiveModelMap[worldKey] = AllEntityLiveModelMap[worldKey] or {};
		local EntityLiveModelMap = AllEntityLiveModelMap[worldKey];
		if (data.action == "delete") then 
			EntityLiveModelMap[data.key] = nil; 
		elseif (data.action == "pull_all") then
			data.packet = EntityLiveModelMap;
			return self:SendDataToPlayer(data);
		else 
			EntityLiveModelMap[data.key] = data.packet;
		end 
	end

	self:SendDataToAllPlayer(data);
end

-- 掉线处理
function AppServerDataHandler:OnDisconnect()
	local onlinePlayerCount = self:GetWorld():GetOnlineClientCount();
	print("-------AppServerDataHandler:OnDisconnect---", onlinePlayerCount);
	if (onlinePlayerCount == 0) then
		local worldKey = self:GetWorldKey();
		AllEntityLiveModelMap[worldKey] = nil;
	end
end