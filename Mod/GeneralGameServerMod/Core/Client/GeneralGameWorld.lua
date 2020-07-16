--[[
Title: GeneralGameWorld
Author(s):  wxa
Date: 2020-06-12
Desc: 多人世界客
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Client/GeneralGameWorld.lua");
local GeneralGameWorld = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameWorld");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/World.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/NetClientHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Config");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local NetClientHandler = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.NetClientHandler");
local GeneralGameWorld = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.World"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameWorld"));

local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local notSyncBlockIdMap = {
	[228] = true, -- 电影方块
	[219] = true, -- 代码方块
	[189] = true, -- 导线
	[199] = true, -- 电灯
	[103] = true, -- 铁轨
	[250] = true, -- 动力铁轨
	[251] = true, -- 探测铁轨
	[192] = true, -- 反向电灯
	[197] = true, -- 中继器
	[105] = true, -- 按钮
	[190] = true, -- 拉杆
	[201] = true, -- 木压力板
	[200] = true, -- 石压力板
	[221] = true, -- 含羞草
	[227] = true, -- 含羞草石
}

function GeneralGameWorld:ctor() 
end

function GeneralGameWorld:Init(client)  
	GeneralGameWorld._super.Init(self);
	
	self.client = client;

	self.markBlockIndexList = commonlib.UnorderedArraySet:new();          -- 待同步的标记更新块索引
	self.allMarkForUpdateBlocks = {};                                     -- 所有标记更新块 
	self.entityList = commonlib.UnorderedArraySet:new();
	self.enableBlockMark = true;                                          -- 默认为true 由 IsSyncBlock 控制
	-- 定时器
	local tickDuration = 1000 * 60 * 2;  -- 2 min
	-- local tickDuration = 1000 * 20;   -- debug
	self.timer = commonlib.Timer:new({callbackFunc = function(timer)
		self:Tick();
	end});
	self.timer:Change(tickDuration, tickDuration); -- 两分钟触发一次

	return self;
end

function GeneralGameWorld:GetClient()
	return self.client;
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

function GeneralGameWorld:SetEnableBlockMark(enable)
	self.enableBlockMark = enable;
end

function GeneralGameWorld:GetEnableBlockMark()
	return self.enableBlockMark;
end

-- 标记更新方块
function GeneralGameWorld:MarkBlockForUpdate(x, y, z)
	if (not self:GetEnableBlockMark() or not self:GetClient():IsSyncBlock()) then return end

	self.markBlockIndexList:add(BlockEngine:GetSparseIndex(x, y, z));
end

-- 是否同步方块的BlockData
function GeneralGameWorld:IsSyncBlockData(blockId)
	local block = blockId and block_types.get(blockId);

	-- 忽略含有 toggle_blockId
	if (block and block.toggle_blockid) then 
		return false; 
	end

	-- 忽略含有 hasAction
	if (block and block.hasAction) then
		return false;
	end

	-- 忽略指定 blockId
	return notSyncBlockIdMap[blockId];
end

-- 定时发送
function GeneralGameWorld:OnFrameMove() 
	if (self.markBlockIndexList:empty()) then return end

	-- 30 fps  0.3s 同步一次
	self.tickBlockInfoUpdateCount = (self.tickBlockInfoUpdateCount or 0) + 1;
	if (self.tickBlockInfoUpdateCount < 10) then return end

	-- 发送方块更新
	local packets = {};
	for i = 1, #(self.markBlockIndexList) do 
		local blockIndex = self.markBlockIndexList[i];
		local x, y, z = BlockEngine:FromSparseIndex(blockIndex);
		local blockId = BlockEngine:GetBlockId(x,y,z);
		local blockData = BlockEngine:GetBlockData(x,y,z);
		local blockEntity = BlockEngine:GetBlockEntity(x,y,z);
		local blockEntityPacket = (blockEntity and blockEntity:IsBlockEntity()) and blockEntity:GetDescriptionPacket();
		local block = blockId and block_types.get(blockId);
		-- 不存在则先构建
		if (not self.allMarkForUpdateBlocks[blockIndex]) then self.allMarkForUpdateBlocks[blockIndex] = {} end
		local oldBlock = self.allMarkForUpdateBlocks[blockIndex];
		local isBlockIdChange = if_else((block and block:IsAssociatedBlockID(oldBlock.blockId)), false, oldBlock.blockId ~= blockId);
		local isBlockDataChange = self:IsSyncBlockData(blockId) and oldBlock.blockData ~= blockData;
		local isBlockEntityPacketChange = commonlib.serialize_compact(oldBlock.blockEntityPacket) ~= commonlib.serialize_compact(blockEntityPacket);

		-- 块数据出现不同 
		if (isBlockIdChange or isBlockDataChange or isBlockEntityPacketChange) then
			oldBlock.blockId = blockId;
			oldBlock.blockData = blockData;
			oldBlock.blockEntityPacket = if_else(isBlockEntityPacketChange, blockEntityPacket, oldBlock.blockEntityPacket);  -- 暂时忽略新旧公用的数据导致不能正确比对的问题
			oldBlock.mark = true;

			packets[#packets + 1] = Packets.PacketBlock:new():Init({
				blockIndex = blockIndex, 
				blockId = blockId, 
				blockData = blockData, 
				blockEntityPacket = if_else(isBlockEntityPacketChange, blockEntityPacket, nil),
			});
		end
	end

	if (#packets > 0) then self.netHandler:AddToSendQueue(Packets.PacketMultiple:new():Init(packets, "SyncBlock")); end

	self.markBlockIndexList:clear();
	self.tickBlockInfoUpdateCount = 0;
end

-- 世界中的方块被点击
function GeneralGameWorld:OnClickBlock(blockId, bx, by, bz, mouseButton, entity, side)
	local blockIndex = BlockEngine:GetSparseIndex(bx, by, bz);
	if (not self.allMarkForUpdateBlocks[blockIndex]) then
		local blockEntity = BlockEngine:GetBlockEntity(bx, by, bz);
		local blockEntityPacket = (blockEntity and blockEntity:IsBlockEntity()) and blockEntity:GetDescriptionPacket();
		self.allMarkForUpdateBlocks[blockIndex] = {
			mark = false,
			blockIndex = blockIndex,
			blockId = BlockEngine:GetBlockId(bx, by, bz),
			blockData = BlockEngine:GetBlockData(bx, by, bz),
			blockEntityPacket = blockEntityPacket,
		}
	end
end

-- 维持用户在线
function GeneralGameWorld:Tick() 
	if (self.netHandler) then
		self.netHandler:SendTick();
	end
end

function GeneralGameWorld:Login(params) 
	local ip = params.ip or "127.0.0.1";
	local port = params.port or "9000";
	local worldId = params.worldId;
	local parallelWorldName = params.parallelWorldName;
	local username = params.username;  -- 若不存在使用 keepwork 的用户名
	local password = params.password;
	local thread = params.thread or "gl";

	self.username = username;
	self.password = password;

	-- 清理旧连接
	if (self.netHandler) then
		 self.netHandler:Cleanup();
	end

	-- 连接服务器
	local NetClientHandlerClass = self:GetClient():GetNetClientHandlerClass() or NetClientHandler;
	self.netHandler = NetClientHandlerClass:new():Init({
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
		-- Log:Debug("destroy entity:", self.entityList[i].entityId);
		self.entityList[i]:Destroy();
	end
	self.entityList:clear();

	-- 解除链接关系
	GameLogic:Disconnect("frameMoved", self, self.OnFrameMove, "DisconnectOne");
	
	-- 清除定时任务
	self.timer:Change();

	self.isLogin = false;
end

function GeneralGameWorld:OnExit()
	GeneralGameWorld._super.OnExit(self);

	self:Logout();
end

function GeneralGameWorld:GetNetHandler()
	return self.netHandler;
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

function GeneralGameWorld:GetEntityList()
	return self.entityList;
end
