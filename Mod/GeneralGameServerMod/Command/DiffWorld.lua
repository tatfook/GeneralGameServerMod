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

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local VirtualConnection = NPL.load("Mod/GeneralGameServerMod/CommonLib/VirtualConnection.lua");

local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local lfs = commonlib.Files.GetLuaFileSystem();

CommonLib.AddPublicFile("Mod/GeneralGameServerMod/Command/DiffWorld.lua");

local function DownloadWorldById(pid, callback)
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

local DiffWorld = commonlib.inherit(VirtualConnection, NPL.export());
local RegionSize = 512;

function DiffWorld:ctor()
    self.__regions__ = {};
end

function DiffWorld:GetRegion(key)
    self.__regions__[key] = self.__regions__[key] or {};
    return self.__regions__[key];
end

-- 获取所有区域信息
function DiffWorld:LoadAllRegionInfo()
    local directory = CommonLib.ToCanonicalFilePath(ParaWorld.GetWorldDirectory() .. "/blockWorld.lastsave");
    local entities = {};
    for filename in lfs.dir(directory) do
        if (string.match(filename, "%d+_%d+%.raw")) then
            local region_x, region_z = string.match(filename, "(%d+)_(%d+)%.raw");
            local key = string.format("%s_%s", region_x, region_z);
            local region = self:GetRegion(key);
            region.key = key;
            region.region_x, region.region_z = tonumber(region_x), tonumber(region_z);
            region.block_x, region.block_z = region.region_x * RegionSize, region.region_z * RegionSize;
            region.filepath = CommonLib.ToCanonicalFilePath(directory .. "/" .. filename);
        elseif (string.match(filename, "%d+_%d+%.region%.xml")) then 
            local key = string.match(filename, "(%d+_%d+)%.region%.xml");
            table.insert(entities, {key = key, filename = CommonLib.ToCanonicalFilePath(directory .. "/" .. filename)});
        end
    end

    for _, entity in ipairs(entities) do
        self:GetRegion(entity.key).xmlpath = entity.filename;
    end
end

function DiffWorld:StartServer(ip, port)
    if (CommonLib.IsServerStarted()) then return end

	NPL.StartNetServer(ip or "0.0.0.0", tostring(port or "9000"));
end

function DiffWorld:Connect(ip, port)
end

print(table, table.insert)
DiffWorld:InitSingleton();

DiffWorld:LoadAllRegionInfo();
-- DownloadWorldById(71542, function(world_directory)
--     print(world_directory);
-- end)


-- diff tool

-- 1. 遍历raw文件和entity文件  
-- 2. 如果raw相同 entity不同, 加载raw(loadregion 512*x + 256 0 512 * z + 256) 只比较entity 
-- 3. 如果raw不同 先比较chunk (return ParaTerrain.GetMapChunkData(self.Coords:GetChunkX(), self.Coords:GetChunkZ(), bIncludeInit, verticalSectionFilter (0xff 返回整高度256));) 