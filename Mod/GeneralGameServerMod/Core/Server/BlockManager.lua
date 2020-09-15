--[[
Title: BlockManager
Author(s):  wxa
Date: 2020-07-17
Desc: 方块管理
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/BlockManager.lua");
local BlockManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.BlockManager");
------------------------------------------------------------
]]

local BlockManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.BlockManager"));

BlockManager:Property("World");   -- 方块管理器所属世界
BlockManager:Property("DB");      -- DB
BlockManager:Property("AreaSize"); -- 区域大小

local BlockSyncDebug = GGS.BlockSyncDebug;

local function FromSparseIndex(index)
	local x, y, z;
	y = math.floor(index / (900000000));
	index = index - y*900000000;
	x = math.floor(index / (30000));
	z = index - x*30000;
	return x,y,z;
end

local function GetAreaIndexFromBlockIndex(blockIndex, areaSize)
    local bx, by, bz = FromSparseIndex(blockIndex);
    local max = math.ceil(30000 / areaSize);
    local x, y, z = math.floor(bx / areaSize), math.floor(by / areaSize), math.floor(bz / areaSize);
    return y * max * max + bx * max + bz;
end

function BlockManager:ctor()
end

-- 初始化
function BlockManager:Init(world)
    self:SetWorld(world);
    self:SetDB(self:GetWorld():GetDB());
    self:SetAreaSize(64);

    if (not self:GetDB()) then return self end
    
    self:GetDB():exec([[
        drop table if exists block;
        create table if not exists block (
            blockIndex	  UNSIGNED INTEGER PRIMARY KEY,
            areaIndex     UNSIGNED INTEGER,
            blockId       UNSIGNED INTEGER,
            blockFlag     INTEGER,
            blockEntity   BLOB
        );
    ]]);

    return self;
end

-- 保存块
function BlockManager:SetBlocks(blocks)
    if (not self:GetDB() or type(blocks) ~= "table") then return end

    local sql = [[replace into block(blockIndex, areaIndex, blockId, blockFlag, blockEntity) values]];
    local areaSize, blockCount = self:GetAreaSize(), #blocks;
    for i = 1, blockCount do 
        local block = blocks[i];
        local blockIndex = block.blockIndex or 0;
        local areaIndex = GetAreaIndexFromBlockIndex(block.blockIndex, areaSize);
        local blockId = block.blockId or 0;
        local blockFlag = block.blockFlag or 0;
        local blockEntity = block.blockEntity and commonlib.serialize_compact(block.blockEntity) or "null";
        sql = sql + string.format("(%s, %s, %s, %s, %s)%s", blockIndex, areaIndex, blockId, blockFlag, blockEntity, i == blockCount and ";" or ",");
    end

    local isOk = self:GetDB():exec(sql);
    if (not isOk) then BlockSyncDebug("-------------------------------store blocks failed------------------") end

    return ;
end

-- 获取块
function BlockManager:GetBlocks()
end