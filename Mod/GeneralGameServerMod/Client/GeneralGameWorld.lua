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
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/World.lua");
NPL.load("Mod/GeneralGameServerMod/Client/NetClientHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Common.Config");
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

	self.enableBlockMark = Config.isSyncBlock;

	self.entityList = commonlib.UnorderedArraySet:new();

	-- 定时器
	local tickDuration = 1000 * 60 * 2;  -- 2 min
	-- local tickDuration = 1000 * 20;   -- debug
	self.timer = commonlib.Timer:new({callbackFunc = function(timer)
		self:Tick();
	end});
	self.timer:Change(tickDuration, tickDuration); -- 两分钟触发一次

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

	self.netHandler:AddToSendQueue(Packets.PacketBlockInfoList:new():Init(blockInfoList));

	self.markBlockIndexList:clear();
	-- self.tickBlockInfoUpdateCount = 0;
end

-- 维持用户在线
function GeneralGameWorld:Tick() 
	self.netHandler:SendTick();
end

function GeneralGameWorld:Login(params) 
	local ip = params.ip or "127.0.0.1";
	local port = params.port or "9000";
	local worldId = params.worldId;
	local parallelWorldName = params.parallelWorldName;
	local username = params.username or System.User.keepworkUsername;  -- 若不存在使用 keepwork 的用户名
	local password = params.password;
	local thread = params.thread or "gl";

	self.username = username;
	self.password = password;

	-- 清理旧连接
	if (self.netHandler) then
		 self.netHandler:Cleanup();
	end

	-- 连接服务器
	self.netHandler = NetClientHandler:new():Init({
		ip = ip, 
		port = port, 
		worldId = worldId, 
		username = username, 
		password = password,
		parallelWorldName = parallelWorldName,
	}, self);
	
	GameLogic:Connect("frameMoved", self, self.OnFrameMove, "UniqueConnection");

	self.isLogin = true;
end

function GeneralGameWorld:Logout() 
	Log:Info("logout world");

	if(self.netHandler) then
		self.netHandler:Cleanup();
	end

	-- 清空并删除实体
	for i = 1, #self.entityList do
		Log:Debug("destroy entiry:", self.entityList[i].entityId);
		self.entityList[i]:Destroy();
	end
	self.entityList:clear();

	-- 解除链接关系
	GameLogic:Disconnect("frameMoved", self, self.OnFrameMove, "DisconnectOne");
	
	-- 清除定时任务
	self.timer:Change();

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

function GeneralGameWorld:AddEntity(entity)
	self.entityList:add(entity);
end

function GeneralGameWorld:RemoveEntity(entity)
	self.entityList:removeByValue(entity);
end
