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
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local RPC = NPL.load("Mod/GeneralGameServerMod/CommonLib/RPC.lua", IsDevEnv);

local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local lfs = commonlib.Files.GetLuaFileSystem();

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

local DiffWorld = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local __rpc__ = RPC:new():Init("127.0.0.1", 9000);
local RegionSize = 512;

function DiffWorld:ctor()
    self.__regions__ = {};
end

function DiffWorld:New()
    return self;
end

function DiffWorld:GetRegion(key)
    self.__regions__[key] = self.__regions__[key] or {};
    return self.__regions__[key];
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
    for filename in lfs.dir(directory) do
        if (string.match(filename, "%d+_%d+%.raw")) then
            local region_x, region_z = string.match(filename, "(%d+)_(%d+)%.raw");
            local key = string.format("%s_%s", region_x, region_z);
            local region = self:GetRegion(key);
            region.key = key;
            region.region_x, region.region_z = tonumber(region_x), tonumber(region_z);
            region.block_x, region.block_z = region.region_x * RegionSize, region.region_z * RegionSize;
            region.rawpath = CommonLib.ToCanonicalFilePath(directory .. "/" .. filename);
        elseif (string.match(filename, "%d+_%d+%.region%.xml")) then 
            local key = string.match(filename, "(%d+_%d+)%.region%.xml");
            table.insert(entities, {key = key, filename = CommonLib.ToCanonicalFilePath(directory .. "/" .. filename)});
        end
    end

    for _, entity in ipairs(entities) do
        self:GetRegion(entity.key).xmlpath = entity.filename;
    end

    for _, region in pairs(self.__regions__) do
        region.rawmd5 = CommonLib.GetFileMD5(region.rawpath);
        region.xmlmd5 = CommonLib.GetFileMD5(region.xmlpath);
    end

    return self.__regions__;
end

function DiffWorld:Register(...)
    __rpc__:Register(...);
end

function DiffWorld:Call(...)
    __rpc__:Call(...);
end

function DiffWorld:StartServer(ip, port)
    CommonLib.StartNetServer(ip, port);
end


function DiffWorld:StartClient(ip, port)
    __rpc__:SetServerIpAndPort(ip, port);

    local key, region = next(self.__regions__);
    local function UploadRegionInfo()
        if (not region) then return end 
        self:Call("UploadRegionInfo", region, function(data)
            echo(data);
        end);
    end
    UploadRegionInfo();
end


DiffWorld:Register("UploadRegionInfo", function(data)
    echo(data)
    return "response region info";
end)


DiffWorld:InitSingleton():LoadAllRegionInfo();

-- diff tool

-- 流程
-- 1. 用户启动下载当前世界最新版, 启动服务器, 新起新版世界客户端(远程客户端), 加载当前世界所有区域信息
-- 2. 远程客户端启动后, 加载本脚本, 加载世界所有区域信息, 与本地世界建立RPC通信
-- 3. 远程世界逐个区域信息上报到本地世界比较

-- 1. 遍历raw文件和entity文件  
-- 2. 如果raw相同 entity不同, 加载raw(loadregion 512*x + 256 0 512 * z + 256) 只比较entity 
-- 3. 如果raw不同 先比较chunk (return ParaTerrain.GetMapChunkData(self.Coords:GetChunkX(), self.Coords:GetChunkZ(), bIncludeInit, verticalSectionFilter (0xff 返回整高度256));) 