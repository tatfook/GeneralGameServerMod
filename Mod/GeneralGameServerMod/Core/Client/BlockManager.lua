--[[
Title: BlockManager
Author(s):  wxa
Date: 2020-07-17
Desc: 方块管理
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Client/BlockManager.lua");
local BlockManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.BlockManager");
------------------------------------------------------------
]]
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");

local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local BlockManager = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.BlockManager"));

local MaxSyncBlockCountPerPacket = 4096;  -- 单个数据包最大同步块数
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

function BlockManager:ctor()
	self.allMarkForUpdateBlockMap = {};                                   -- 所有标记更新块 
	-- self.allMarkForUpdateBlockEntiryMap = {};                          -- 所有标记的块实体
	self.markBlockIndexList = commonlib.UnorderedArraySet:new();          -- 待同步的标记更新块索引
	self.needSyncBlockIndexList = commonlib.UnorderedArraySet:new();      -- 需要同步的块索引列表
end

function BlockManager:Init(world)
	self.world = world;

	-- 注册实体编辑事件
	GameLogic.GetEvents():AddEventListener("OnEditEntity", BlockManager.OnEditEntity, self, "BlockManager");

	return self;
end

function BlockManager:CleanUp()
	GameLogic.GetEvents():RemoveEventListener("OnEditEntity", BlockManager.OnEditEntity, self);
end

function BlockManager:GetWorld()
	return self.world;
end

function BlockManager:GetPlayerId()
	return self:GetWorld():GetNetHandler():GetPlayerId();
end

function BlockManager:OnEditEntity(event)
	local entity = event.entity;
	local isBegin = event.isBegin;
	local x,y,z = entity:GetBlockPos();
	local blockIndex = BlockEngine:GetSparseIndex(x, y, z);

	if (not self.allMarkForUpdateBlockMap[blockIndex]) then
		self.allMarkForUpdateBlockMap[blockIndex] = {blockIndex = blockIndex};
	end

	local block = self.allMarkForUpdateBlockMap[blockIndex];
	local blockEntityPacket = entity:GetDescriptionPacket();

	if (isBegin) then
		block.blockEntityPacket = blockEntityPacket;
	else 
		block.isBlockEntityChange = commonlib.serialize_compact(blockEntityPacket) ~= commonlib.serialize_compact(block.blockEntityPacket);
		if (block.isBlockEntityChange) then
			block.blockEntityPacket = blockEntityPacket;
			local packet = Packets.PacketBlock:new():Init({blockIndex = blockIndex, blockEntityPacket = blockEntityPacket});
			self:AddToSendQueue(Packets.PacketMultiple:new():Init({packet}, "SyncBlock"));
		end
	end
end

-- 标记更新方块
function BlockManager:MarkBlockForUpdate(x, y, z)
	-- 次函数可能再同步前调用多次, 无法正确识别创建,删除
	local blockIndex = BlockEngine:GetSparseIndex(x, y, z);
	local blockId = BlockEngine:GetBlockId(x,y,z);
	local blockData = BlockEngine:GetBlockData(x,y,z);
	-- allMarkForUpdateBlockMap 记录最后一次同步的状态  首次记录当前修改前的数据
	if (not self.allMarkForUpdateBlockMap[blockIndex]) then
		self.allMarkForUpdateBlockMap[blockIndex] = {blockIndex = blockIndex, blockId = blockId, lastBlockId = blockId, blockData, isForceSyncAll = blockId == 0};  -- blockId = 0 当前为新增
	end
	-- 创建方块 则填充初始数据并设置强制同步标志
	if (self.allMarkForUpdateBlockMap[blockIndex].lastBlockId == 0 and blockId ~= 0) then
		self.allMarkForUpdateBlockMap[blockIndex].blockData = blockData;
		self.allMarkForUpdateBlockMap[blockIndex].isForceSyncAll = true;
	end
	-- 在同步前, 此函数可能调用多次, blockId记录上次同步的blockId, lastBlockId记录当前位置的上次BlockId
	self.allMarkForUpdateBlockMap[blockIndex].lastBlockId = blockId;

	-- 添加到标记列表
	self.markBlockIndexList:add(blockIndex);
end

-- 是否同步方块的BlockData
function BlockManager:IsSyncBlockData(blockId)
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
	return not notSyncBlockIdMap[blockId];
end

-- 同步块
function BlockManager:SyncBlock()
	if (self.markBlockIndexList:empty()) then return end

	local packets, syncedBlockIndexList = {}, {};
	local markBlockIndexCount = #(self.markBlockIndexList);
	local maxSyncBlockCount = markBlockIndexCount > MaxSyncBlockCountPerPacket and MaxSyncBlockCountPerPacket or markBlockIndexCount;
	for i = 1, maxSyncBlockCount do 
	-- for i = 1,  #(self.markBlockIndexList) do 
		local blockIndex = self.markBlockIndexList[i];
		local x, y, z = BlockEngine:FromSparseIndex(blockIndex);
		local blockId = BlockEngine:GetBlockId(x,y,z);
		local blockData = BlockEngine:GetBlockData(x,y,z);
		local block = blockId and block_types.get(blockId);
		local oldBlock = self.allMarkForUpdateBlockMap[blockIndex];
		local isBlockIdChange = if_else((block and block:IsAssociatedBlockID(oldBlock.blockId)), false, oldBlock.blockId ~= blockId);
		local isBlockDataChange = self:IsSyncBlockData(blockId) and oldBlock.blockData ~= blockData;
		local isForceSyncAll = oldBlock.isForceSyncAll;
		local blockEntityPacket = nil;

		syncedBlockIndexList[#syncedBlockIndexList + 1] = blockIndex;

		-- 强制同步所有
		if (isForceSyncAll) then 
			local blockEntity = BlockEngine:GetBlockEntity(x,y,z);
			blockEntityPacket = blockEntity and blockEntity:GetDescriptionPacket();
		end

		-- 块数据出现不同 
		if (isForceSyncAll or isBlockIdChange or isBlockDataChange) then
			oldBlock.blockData = if_else(isBlockIdChange and oldBlock.blockId == 0 or isBlockDataChange, blockData, oldBlock.blockData);
			oldBlock.blockId = if_else(isBlockIdChange, blockId, oldBlock.blockId);
			oldBlock.blockEntityPacket = if_else(isForceSyncAll, blockEntityPacket, oldBlock.blockEntityPacket);
			oldBlock.isForceSyncAll = false;
			packets[#packets + 1] = Packets.PacketBlock:new():Init({
				blockIndex = blockIndex,
				blockId = oldBlock.blockId,
				blockData = oldBlock.blockData,
				blockEntityPacket = blockEntityPacket,
			});
			-- Log:Debug(packets[#packets]);
		end
	end

	-- 发送方块更新
	if (#packets > 0) then self:AddToSendQueue(Packets.PacketMultiple:new():Init(packets, "SyncBlock")); end
	
	-- 从标记列表中移除
	for i = 1, #syncedBlockIndexList do
		self.markBlockIndexList:removeByValue(syncedBlockIndexList[i]);
	end

	-- self.markBlockIndexList:clear();
end

-- 处理请求同步块索引列表数
function BlockManager:handleSyncBlock_RequestBlockIndexList(packetGeneral)
	local blockIndexList = {};
	for key, val in pairs(self.allMarkForUpdateBlockMap) do
		blockIndexList[#blockIndexList + 1] = val.blockIndex;
	end
	self:AddToSendQueue(Packets.PacketGeneral:new():Init({
		action = "SyncBlock",
		data = {
			state = "SyncBlock_ResponseBlockIndexList",
			playerId = packetGeneral.data.playerId,
			blockIndexList = blockIndexList,
		},
	}));
end

-- 处理响应同步块索引列表数
function BlockManager:handleSyncBlock_ResponseBlockIndexList(packetGeneral)
	local blockIndexList = packetGeneral.data.blockIndexList;
	-- 设置需要同步的块
	if (blockIndexList) then
		for i = 1, #blockIndexList do
			self.needSyncBlockIndexList:add(blockIndexList[i]);
		end
	end

	-- 发送请求块
	local list = {};
	for i = 1, #(self.needSyncBlockIndexList) do
		list[#list + 1] = self.needSyncBlockIndexList[i];
		if (i == MaxSyncBlockCountPerPacket or i == #(self.needSyncBlockIndexList)) then
			self:AddToSendQueue(Packets.PacketGeneral:new():Init({
				action = "SyncBlock",
				data = {
					state = "SyncBlock_RequestSyncBlock",
					blockIndexList = list,
					playerId = self:GetPlayerId(),
				},
			}));
			list = {};
		end
	end
end

-- 处理块请求
function BlockManager:handleSyncBlock_RequestSyncBlock(packetGeneral)
	local blockIndexList = packetGeneral.data.blockIndexList;
	local blockList = {};
	for i = 1, #blockIndexList do
		local blockIndex = blockIndexList[i];
		local block = self.allMarkForUpdateBlockMap[blockIndex];
		if (block) then
			blockList[#blockList + 1] = Packets.PacketBlock:new():Init({
				blockIndex = blockIndex,
				blockId = block.blockId,
				blockData = block.blockData,
				blockEntityPacket = block.blockEntityPacket,
			}):WritePacket();
		end
	end
	self:AddToSendQueue(Packets.PacketGeneral:new():Init({
		action = "SyncBlock", 
		data = {
			state = "SyncBlock_ResponseSyncBlock", 
			playerId = packetGeneral.data.playerId,
			blockList = blockList,
		},
	}));
end

-- 处理块响应
function BlockManager:handleSyncBlock_ResponseSyncBlock(packetGeneral)
	local blockList = packetGeneral.data.blockList;
	for i = 1, #blockList do
		local block = blockList[i];
		local packet = Packets.PacketBlock:new();
		packet:ReadPacket(block);
		self:GetWorld():GetNetHandler():handleBlock(packet);
	end
end

-- 处理同步开始
function BlockManager:handleSyncBlock_Begin()
	-- 请求获取块同步列表
	self:AddToSendQueue(Packets.PacketGeneral:new():Init({
		action = "SyncBlock",
		data = {
			state = "SyncBlock_RequestBlockIndexList",
			playerId = self:GetPlayerId(),
		},
	}));
end

-- 处理同步完成
function BlockManager:handleSyncBlock_Finish()
	self.needSyncBlockIndexList:clear();
	self:AddToSendQueue(Packets.PacketGeneral:new():Init({action = "SyncBlock", data = {state = "SyncBlock_Finish", playerId = self:GetPlayerId()}}));  -- 服务器确认完成
end

-- 发送数据包
function BlockManager:AddToSendQueue(packet)
	return self:GetWorld():GetNetHandler():AddToSendQueue(packet);
end
