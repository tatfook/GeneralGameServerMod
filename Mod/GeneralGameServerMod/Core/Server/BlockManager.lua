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
NPL.load("Mod/GeneralGameServerMod/Core/Common/Packets/PacketBlock.lua");
local PacketBlock = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets.PacketBlock");
local BlockManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.BlockManager"));

BlockManager:Property("World");   -- 方块管理器所属世界
BlockManager:Property("DB");      -- DB
BlockManager:Property("AreaSize"); -- 区域大小

-- ParaWorld.GetWorldDirectory()

local BlockSyncDebug = GGS.BlockSyncDebug;

local function FromSparseIndex(index)
	local x, y, z;
	y = math.floor(index / (900000000));
	index = index - y * 900000000;
	x = math.floor(index / (30000));
	z = index - x*30000;
	return x,y,z;
end

local function GetAreaIndexFromBlockIndex(blockIndex, areaSize)
    local bx, by, bz = FromSparseIndex(blockIndex);
    local max = math.ceil(30000 / areaSize);
    local x, y, z = math.floor(bx / areaSize), math.floor(by / areaSize), math.floor(bz / areaSize);
    return y * max * max + x * max + z;
end

local function BlockToRow(block, areaSize)
    return {
        blockIndex = block.blockIndex or 0,
        areaIndex = GetAreaIndexFromBlockIndex(block.blockIndex, areaSize),
        packet = commonlib.serialize_compact(block:WritePacket()),
    }
end

local function RowToBlock(row)
    return {
        blockIndex = tonumber(row.blockIndex),
        areaIndex = tonumber(row.areaIndex),
        packet = PacketBlock:new():ReadPacket(NPL.LoadTableFromString(row.packet)), 
    }
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
            blockIndex	        VARCHAR(24) PRIMARY KEY,
            areaIndex           VARCHAR(24),
            packet              BLOB
        );
    ]]);

    return self;
end

-- 保存块
function BlockManager:SetBlocks(blocks)
    if (not self:GetDB() or type(blocks) ~= "table") then return end

    local sql = [[replace into block(blockIndex, areaIndex, packet) values]];
    local areaSize, blockCount = self:GetAreaSize(), #blocks;
    local args = {};
    for i = 1, blockCount do 
        local block = blocks[i];
        local row = BlockToRow(block, areaSize);
        table.insert(args, row.blockIndex);
        table.insert(args, row.areaIndex);
        table.insert(args, row.packet);
        
        BlockSyncDebug.Format("blockIndex = %s, areaIndex = %s", row.blockIndex, row.areaIndex);

        sql = sql .. string.format('(?, ?, ?)%s', i == blockCount and ";" or ",");
    end
    local ok, errmsg = self:GetDB():prepare(sql):bind(table.unpack(args)):exec(); 
    
    if (not ok) then 
        BlockSyncDebug("SetBlocks Failed: " .. errmsg);
        return false;
    end

    return true;
end

-- 获取块
function BlockManager:GetBlocksByAreaIndex(areaIndex)
    if (not self:GetDB()) then return end

    local list = {};
    for row in self:GetDB():prepare("select * from block where areaIndex = ?;"):bind(areaIndex or 0):rows() do
        table.insert(list, RowToBlock(row).packet);
    end

    return list;
end


