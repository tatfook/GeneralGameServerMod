--[[
Title: GeneralGameWorld
Author(s):  wxa
Date: 2020-06-12
Desc: 多人世界客
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Client/GeneralGameWorld.lua");
local GeneralGameWorld = commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameWorld");
------------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/World/World.lua");
NPL.load("Mod/GeneralGameServerMod/Client/NetClientHandler.lua");

local NetClientHandler = commonlib.gettable("Mod.GeneralGameServerMod.Client.NetClientHandler");
local GeneralGameWorld = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.World"), commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameWorld"));

function GeneralGameWorld:ctor() 
end

function GeneralGameWorld:Init(name)  
	self._super.Init(self);
	
	return self;
end

function GeneralGameWorld:ReplaceWorld(oldWorld)
	if(oldWorld) then
		self:GetChunkProvider():GetGenerator():AddPendingChunksFrom(oldWorld:GetChunkProvider():GetGenerator());
		oldWorld:OnWeaklyDestroyWorld();
	end
end

function GeneralGameWorld:SetName(name)
	self.name = name;
end

function GeneralGameWorld:GetName(name)
	return self.name;
end

function GeneralGameWorld:Login(params) 
	local ip = params.ip or "127.0.0.1";
	local port = params.port or "9000";
	-- a random username
	local username = params.username;
	local password = params.password;
	local thread = params.thread or "gl";
	LOG.std(nil, "info", "GeneralGameWorld", "Start login %s %s as username:%s", ip, port, username);
	
	self.username = username;
	self.password = password;

	-- 清理旧连接
	if (self.net_handler) then
		 self.net_handler:Cleanup();
	end

	-- 连接服务器
	self.net_handler = NetClientHandler:new():Init(ip, port, username, password, self);
end

function GeneralGameWorld:OnExit()
	self._super.OnExit(self);

	if(self.net_handler) then
		self.net_handler:Cleanup();
	end

	return self;
end


function GeneralGameWorld:AddPlayerEntity(entity)
	
end

function GeneralGameWorld:RemovePlayerEntity(entity)
	
end
