--[[
Title: DiffWorld
Author(s):  wxa
Date: 2020-06-12
Desc: DiffWorld
use the lib:
------------------------------------------------------------
local DiffWorld = NPL.load("Mod/GeneralGameServerMod/Command/DiffWorld.lua");
------------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local RPC = NPL.load("Mod/GeneralGameServerMod/CommonLib/RPC.lua", IsDevEnv);

local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local lfs = commonlib.Files.GetLuaFileSystem();

local function DownloadWorldById(pid, callback)
    pid = pid or GameLogic.options:GetProjectId();
    KeepworkServiceProject:GetProject(pid, function(data, err)
        if not data or type(data) ~= 'table' or not data.name or not data.username or not data.world or not data.world.commitId then return callback() end
        GitService:DownloadZIP(data.name, data.username, data.world.commitId, function(bSuccess, downloadPath)
            if (not bSuccess) then return callback() end
            local temp_diff_world_directory = "temp/diff_world/";
            LocalService:MoveZipToFolder(temp_diff_world_directory, downloadPath, function()
                -- 次函数无出错处理 可能产生未知情况 
                for filename in lfs.dir(temp_diff_world_directory) do
                    if (filename ~= "." and filename ~= "..") then
                        return callback(temp_diff_world_directory .. filename);
                    end
                end
            end);
        end)
    end)
end

local DiffWorld = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local __rpc__ = RPC:new():Init("127.0.0.1", 9000);
local RegionSize = 512;
local ChunkSize = 16;

function DiffWorld:ctor()
    self:Reset();
end

function DiffWorld:New()
    return self;
end

function DiffWorld:Reset()
    self.__regions__ = {};
    self.__diffs__ = {};
end

function DiffWorld:GetRegion(key)
    self.__regions__[key] = self.__regions__[key] or {};
    return self.__regions__[key];
end

function DiffWorld:IsExistRegion(key)
    return self.__regions__[key] ~= nil;
end

function DiffWorld:SyncLoadWorld()
    CommandManager:RunCommand("/property AsyncChunkMode false");
    CommandManager:RunCommand("/property UseAsyncLoadWorld false");
end

function DiffWorld:LoadRegion(x, y, z)
    ParaBlockWorld.LoadRegion(GameLogic.GetBlockWorld(), x, y or 4, z);
end

-- 获取所有区域信息
function DiffWorld:LoadAllRegionInfo()
    local directory = CommonLib.ToCanonicalFilePath(ParaWorld.GetWorldDirectory() .. "/blockWorld.lastsave");
    local entities = {};
    ParaIO.CreateDirectory(directory);
    for filename in lfs.dir(directory) do
        if (string.match(filename, "%d+_%d+%.raw")) then
            local region_x, region_z = string.match(filename, "(%d+)_(%d+)%.raw");
            local region_key = string.format("%s_%s", region_x, region_z);
            local region = self:GetRegion(region_key);
            region.region_key = region_key;
            region.region_x, region.region_z = tonumber(region_x), tonumber(region_z);
            region.block_x, region.block_z = region.region_x * RegionSize, region.region_z * RegionSize;
            region.rawpath = CommonLib.ToCanonicalFilePath(directory .. "/" .. filename);
        elseif (string.match(filename, "%d+_%d+%.region%.xml")) then 
            local region_key = string.match(filename, "(%d+_%d+)%.region%.xml");
            table.insert(entities, {region_key = region_key, xmlpath = CommonLib.ToCanonicalFilePath(directory .. "/" .. filename)});
        end
    end

    for _, entity in ipairs(entities) do
        self:GetRegion(entity.region_key).xmlpath = entity.xmlpath;
    end

    for _, region in pairs(self.__regions__) do
        region.rawmd5 = CommonLib.GetFileMD5(region.rawpath);
        region.xmlmd5 = CommonLib.GetFileMD5(region.xmlpath);
    end

    return self.__regions__;
end

function DiffWorld:Register(...)
    __rpc__:Register(...)
end

function DiffWorld:Call(...)
    __rpc__:Call(...);
end

function DiffWorld:LoadRegion(region)
    CommandManager:RunCommand("/loadregion %s %s %s", region.block_x, 5, region.block_z);
end


function DiffWorld:StartServer(ip, port)
    CommonLib.StartNetServer(ip, port);
    self:SyncLoadWorld();
    self:Reset();

    -- DownloadWorldById(nil, function(world_directory)
    --     CommandManager:RunCommand("/open paracraft://cmd/loadworld %s", world_directory);
    -- end);

    self:LoadAllRegionInfo();
end


function DiffWorld:StartClient(ip, port)
    __rpc__:SetServerIpAndPort(ip, port);
    self:SyncLoadWorld();
    self:Reset();
    self:LoadAllRegionInfo();

    local key, region = nil, nil;
    local function NextDiffRegionInfo()
        key, region = next(self.__regions__, key); 
        if (not region) then 
            return self:Call("DiffWorldFinish", nil, function()
                print("=======================request DiffWorldFinish===========================");
            end); 
        end 
        self:Call("DiffRegionInfo", region, function(data)
            region.is_equal_rawmd5 = data.is_equal_rawmd5;
            region.is_equal_xmlmd5 = data.is_equal_xmlmd5;
            print(string.format("diff region: %s, is_equal_rawmd5 = %s, is_equal_xmlmd5 = %s", region.region_key, region.is_equal_rawmd5, region.is_equal_xmlmd5));
            if (region.is_equal_rawmd5 and region.is_equal_xmlmd5) then 
                -- 完全一致 比较下一个区域
                NextDiffRegionInfo();
            else
                -- entity 或 block 不同
                self:DiffRegionChunkInfo(region, function()
                    -- 对比完成
                    NextDiffRegionInfo();
                end);
            end
        end);
    end

    self:Call("DiffWorldStart", nil, function()
        print("============request DiffWorldStart=============")
        NextDiffRegionInfo();
    end);
end

-- 响应区域信息
DiffWorld:Register("DiffRegionInfo", function(data)
    local self = DiffWorld;
    if (not self:IsExistRegion(data.region_key)) then 
        local region = self:GetRegion(data.region_key);
        commonlib.partialcopy(region, data);
        region.rawmd5, region.xmlmd5 = nil, nil;
    end 
    
    local region = self:GetRegion(data.region_key);
    region.is_diff = true;
    region.is_equal_rawmd5 = region.rawmd5 == data.rawmd5;
    region.is_equal_xmlmd5 = region.xmlmd5 == data.xmlmd5;
    print("==================response DiffRegionInfo", region.is_equal_rawmd5, region.is_equal_xmlmd5);
    return {is_equal_rawmd5 = region.is_equal_rawmd5, is_equal_xmlmd5 = region.is_equal_xmlmd5};
end)

-- 响应方块信息
DiffWorld:Register("DiffRegionChunkInfo", function(data)
    local self = DiffWorld;
    return self:LoadRegionChunkInfo(self:GetRegion(data.region_key), data.chunk_generates);
end);

-- 对比chunk
function DiffWorld:DiffRegionChunkInfo(region, callback)
    local local_chunks = self:LoadRegionChunkInfo(region);
    local remote_chunks = nil;
    local chunk_key, local_chunk = nil, nil;

    local function NextDiffRegionChunkInfo()
        chunk_key, local_chunk = next(local_chunks, chunk_key);
        if (not local_chunk) then return type(callback) == "function" and callback() end 
        local remote_chunk = remote_chunks[chunk_key] or {};
        if (local_chunk.chunk_md5 == remote_chunk.chunk_md5) then
            NextDiffRegionChunkInfo();
        else
            print(string.format("region chunk not equal. chunk_key = %s, local_chunk_md5 = %s remote_chunk_md5 = %s", local_chunk.chunk_key, local_chunk.chunk_md5, remote_chunk.chunk_md5));
            self:DiffRegionChunkBlockInfo(local_chunk, function()
                NextDiffRegionChunkInfo();
            end);
        end
    end

    -- 保证两个世界chunk生成是一致的
    local data = {region_key = region.region_key, chunk_generates = {}};
    for chunk_key, chunk in pairs(local_chunks) do
        data.chunk_generates[chunk_key] = chunk.is_generate;
    end
    self:Call("DiffRegionChunkInfo", data, function(chunks)
        remote_chunks = chunks;
        for chunk_key, remote_chunk in pairs(remote_chunks) do
            local local_chunk = local_chunks[chunk_key];
            if (not local_chunk.is_generate and remote_chunk.is_generate) then
                self:GenerateChunk(local_chunk.chunk_x, local_chunk.chunk_z);
                local chunk_v = ParaTerrain.GetMapChunkData(local_chunk.chunk_x, local_chunk.chunk_z, false, 0xffff);
                local_chunk.chunk_md5 = CommonLib.MD5(chunk_v);
            end
        end
        NextDiffRegionChunkInfo();
    end);
end

function DiffWorld:IsGenerateChunk(chunk_x, chunk_z)
    local real_chunk = GameLogic.GetWorld():GetChunk(chunk_x, chunk_z, true);
    return  (real_chunk and real_chunk:GetTimeStamp() > 0) and true or false;
end

function DiffWorld:GenerateChunk(chunk_x, chunk_z)
    if (self:IsGenerateChunk(chunk_x, chunk_z)) then return end
    local chunk = GameLogic.GetWorld():GetChunk(chunk_x, chunk_z, true);
    GameLogic.GetBlockGenerator():GenerateChunk(chunk, chunk_x, chunk_z, true)
end

function DiffWorld:LoadRegionChunkInfo(region, chunk_generates)
    self:LoadRegion(region);

    local size = RegionSize / ChunkSize;
    region.chunks = region.chunks or {};
    for i = 0, 31 do
        for j = 0, 31 do
            local chunk_x, chunk_z = region.region_x * size + i, region.region_z * size + j;
            local chunk_key = string.format("%s_%s", chunk_x, chunk_z);
            if (chunk_generates and chunk_generates[chunk_key]) then self:GenerateChunk(chunk_x, chunk_z) end 
            local is_generate = self:IsGenerateChunk(chunk_x, chunk_z);
            local chunk_v = (is_generate) and (ParaTerrain.GetMapChunkData(chunk_x, chunk_z, false, 0xffff)) or "";
            local chunk_md5 = CommonLib.MD5(chunk_v);
            local chunk = region.chunks[chunk_key] or {};

            region.chunks[chunk_key] = chunk;   
            chunk.chunk_x, chunk.chunk_z, chunk.chunk_md5, chunk.chunk_key = chunk_x, chunk_z, chunk_md5, chunk_key;
            chunk.is_equal_rawmd5, chunk.is_equal_xmlmd5, chunk.region_key = region.is_equal_rawmd5, region.is_equal_xmlmd5, region.region_key;
            chunk.is_generate = is_generate;
        end
    end
    return region.chunks;
end


-- 对比方块信息
function DiffWorld:DiffRegionChunkBlockInfo(chunk, callback)
    local blocks = self:LoadRegionChunkBlockInfo(chunk);

    self:Call("DiffRegionChunkBlockInfo", {chunk = chunk, blocks = blocks}, function()
        return type(callback) == "function" and callback();
    end);
end

function DiffWorld:LoadRegionChunkBlockInfo(chunk)
    local is_equal_rawmd5, is_equal_xmlmd5 = chunk.is_equal_rawmd5, chunk.is_equal_xmlmd5;
    local start_x, start_y = chunk.chunk_x * ChunkSize, chunk.chunk_z * ChunkSize;
    local blocks = {}
    for i = 0, 15 do
        for j = 0, 15 do
            local x, z = start_x + i, start_y + j;
            for y = -128, 128 do
                local index = BlockEngine:GetSparseIndex(x, y, z);
                local block_id, block_data, entity_data = BlockEngine:GetBlockFull(x, y, z);
                entity_data = entity_data and commonlib.serialize_compact(entity_data);
                local entity_data_md5 = entity_data and CommonLib.MD5(entity_data);
                -- 无实体数据且方块相同则不同步
                if (block_id and block_id ~= 0) then
                    if (not is_equal_rawmd5 or entity_data) then
                        blocks[index] = {block_id = block_id, block_data = block_data, entity_data = entity_data, entity_data_md5 = entity_data_md5}
                    end
                end
            end
        end
    end
    return blocks;
end

-- 响应方块比较
DiffWorld:Register("DiffRegionChunkBlockInfo", function(data)
    local self = DiffWorld;
    local chunk, remote_blocks = data.chunk, data.blocks;
    local local_blocks = self:LoadRegionChunkBlockInfo(chunk);
    local region_key, chunk_key = chunk.region_key, chunk.chunk_key;
    local __diffs__ = self.__diffs__;
    local diff_region = __diffs__[region_key] or {};
    __diffs__[region_key] = diff_region;
    local diff_region_chunk = diff_region[chunk_key] or {};
    diff_region[chunk_key] = diff_region_chunk;

    local diff_blocks = {};
    local diff_block_count = 0;

    for block_index, remote_block in pairs(remote_blocks) do
        local local_block = local_blocks[block_index];
        if (not local_block or local_block.block_id ~= remote_block.block_id or local_block.block_data ~= remote_block.block_data or local_block.entity_data_md5 ~= remote_block.entity_data_md5) then
            diff_block_count = diff_block_count + 1;
            local x, y, z = BlockEngine:FromSparseIndex(block_index);
            diff_blocks[block_index] = {
                x = x, y = y, z = z,
                remote_block_id = remote_block.block_id,
                remote_block_data = remote_block.block_data,
                remote_entity_data = remote_block.entity_data,
                local_block_id = local_block and local_block.block_id,
                local_block_data = local_block and local_block.block_data,
                local_entity_data = local_block and local_block.entity_data,
            }
        end
    end

    for block_index, local_block in pairs(local_blocks) do
        if (not remote_blocks[block_index]) then
            diff_block_count = diff_block_count + 1;
            local x, y, z = BlockEngine:FromSparseIndex(block_index);
            diff_blocks[block_index] = {
                x = x, y = y, z = z,
                local_block_id = local_block.block_id,
                local_block_data = local_block.block_data,
                local_entity_data = local_block.entity_data,
            }
        end
    end

    diff_region_chunk.diff_blocks, diff_region_chunk.diff_block_count = diff_blocks, diff_block_count;
    return diff_block_count;
end);


DiffWorld:Register("DiffWorldStart", function()
    print("-----------------------response DiffWorldStart---------------------------")
    return ;
end)

-- 响应世界比较结束
DiffWorld:Register("DiffWorldFinish", function()
    print("----------------------response DiffWorldFinish----------------------------")
    local self = DiffWorld;
    local new_regions = {}
    for key, region in pairs(self.__regions__) do
        if (not region.is_diff) then
            new_regions[#new_regions + 1] = key;
        end
    end
    self.__diffs__.__new_regions__ = new_regions;
    echo(self.__diffs__["37_37"], true)
end);

DiffWorld:InitSingleton();

-- DiffWorld:SyncLoadWorld();
-- -- echo(DiffWorld.__regions__, true)
-- local key, region = next(DiffWorld.__regions__, nil);
-- DiffWorld:LoadRegion(region)
-- -- 19190,4,19195
-- local blocks = ParaTerrain.GetMapChunkData(19190 / 16, 19195 / 16, true, 0xffff);
-- echo(region, true)
-- echo(blocks, true)
-- diff tool


-- 流程
-- 1. 用户启动下载当前世界最新版, 启动服务器, 新起新版世界客户端(远程客户端), 加载当前世界所有区域信息
-- 2. 远程客户端启动后, 加载本脚本, 加载世界所有区域信息, 与本地世界建立RPC通信
-- 3. 远程世界逐个区域信息上报到本地世界比较

-- region=512*256*512
-- chunk=16*16*16

-- 1. 遍历raw文件和entity文件  
-- 2. 如果raw相同 entity不同, 加载raw(loadregion 512*x + 256 0 512 * z + 256) 只比较entity 
-- 3. 如果raw不同 先比较chunk (return ParaTerrain.GetMapChunkData(self.Coords:GetChunkX(), self.Coords:GetChunkZ(), bIncludeInit, verticalSectionFilter (0xffff 返回整高度256));) 
-- /terraingen 地形生成命令