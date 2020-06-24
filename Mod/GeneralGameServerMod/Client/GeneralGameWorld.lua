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
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Common.Packets");
local NetClientHandler = commonlib.gettable("Mod.GeneralGameServerMod.Client.NetClientHandler");
local GeneralGameWorld = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.World"), commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameWorld"));

local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

function GeneralGameWorld:ctor() 
end

function GeneralGameWorld:Init(worldId)  
	self._super.Init(self);
	
	self.worldId = worldId;

	self.markBlockIndexList = commonlib.UnorderedArraySet:new();

	self.enableBlockMark = true;
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

function GeneralGameWorld:MarkBlockForUpdate(x, y, z)
	if (not self.enableBlockMark) then return end

	self.markBlockIndexList:add(BlockEngine:GetSparseIndex(x, y, z));
end

function GeneralGameWorld:SetEnableBlockMark(enable)
	self.enableBlockMark = enable;
end

function GeneralGameWorld:OnFrameMove() 
	if (self.markBlockIndexList:empty()) then
		return;
	end
	-- 30 fps
	-- self.tickBlockInfoUpdateCount = (self.tickBlockInfoUpdateCount or 0) + 1;
	-- if (self.tickBlockInfoUpdateCount < 30) then
	-- 	return;
	-- end

	-- 发送方块更新
	local blockInfoList = {};
	for i = 1, #(self.markBlockIndexList) do 
		local blockIndex = self.markBlockIndexList[i];
		local x, y, z = BlockEngine:FromSparseIndex(blockIndex);
		local blockId = BlockEngine:GetBlockId(x,y,z);
		local blockData = BlockEngine:GetBlockData(x,y,z);
		blockInfoList[i] = {blockIndex = blockIndex, blockId = blockId, blockData = blockData}; 
	end

	self.net_handler:AddToSendQueue(Packets.PacketBlockInfoList:new():Init(blockInfoList));

	self.markBlockIndexList:clear();
	-- self.tickBlockInfoUpdateCount = 0;
end


function GeneralGameWorld:Login(params) 
	local ip = params.ip or "127.0.0.1";
	local port = params.port or "9000";
	local worldId = params.worldId;
	local username = params.username or System.User.keepworkUsername;  -- 若不存在使用 keepwork 的用户名
	local password = params.password;
	local thread = params.thread or "gl";

	self.username = username;
	self.password = password;

	-- 清理旧连接
	if (self.net_handler) then
		 self.net_handler:Cleanup();
	end

	-- 连接服务器
	self.net_handler = NetClientHandler:new():Init(ip, port, worldId, username, password, self);
	
	GameLogic:Connect("frameMoved", self, self.OnFrameMove, "UniqueConnection");

	self.isLogin = true;
end

function GeneralGameWorld:Logout() 
	if(self.net_handler) then
		self.net_handler:Cleanup();
	end

	GameLogic:Disconnect("frameMoved", self, self.OnFrameMove, "DisconnectOne");

	self.worldId = nil;
	self.isLogin = false;
end

function GeneralGameWorld:OnExit()
	self._super.OnExit(self);

	self:Logout();
end

function GeneralGameWorld:IsLogin()
	return self.isLogin;
end
