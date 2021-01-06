--[[
Title: FileSync
Author(s): wxa
Date: 2020-06-12
Desc: 文件同步
use the lib:
------------------------------------------------------------
local Common = NPL.load("Mod/GeneralGameServerMod/FileSync/Common.lua");
------------------------------------------------------------
]]
local GGS = NPL.load("Mod/GeneralGameServerMod/Core/Common/GGS.lua");

NPL.load("(gl)script/ide/System/Encoding/sha1.lua");
local Encoding = commonlib.gettable("System.Encoding");

local Common = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local FileSyncDebug = GGS.Debug.GetModuleDebug("FileSyncDebug");

Common:Property("FileSyncDirectory");  -- 同步目录

local lfs = commonlib.Files.GetLuaFileSystem();
local FileCacheMap = {};                 -- 文件缓存
local ConfigFileName = "Config.txt";

local function IsMainThread()
    return __rts__:GetName() == "main";
end

-- replace / with \ under win32, and vice versa on linux. 
local function ToCanonicalFilePath(filename)
	if(System.os.GetPlatform()=="win32") then
		filename = string.gsub(filename, "/+", "\\");
	else
		filename = string.gsub(filename, "\\+", "/");
	end
	return filename;
end

function GetFileList(directory, prefix, recursive)
    local list = {};
    for filename in lfs.dir(directory) do
        if (filename ~= "." and filename ~= "..") then
            local filepath = ToCanonicalFilePath(directory .. "/" .. filename);
            local subprefix = ToCanonicalFilePath((prefix and prefix ~= "") and (prefix .. "/" .. filename) or filename);
            local fileattr = lfs.attributes(filepath);

            if (fileattr.mode == "directory") then
                if (recursive) then
                    local sublist = GetFileList(filepath, subprefix, recursive);
                    for _, item in ipairs(sublist) do table.insert(list, #list + 1, item) end
                end
            else
                table.insert(list, #list + 1, subprefix);
            end
        end
    end
    return list;
end

-- 获取配置文件路径
function Common:GetConfigFileName()
    return self:GetFileSyncDirectory() .. ConfigFileName;
end

-- 获取文件全路径
function Common:GetFullFilePath(filepath)
    return self:GetFileSyncDirectory() .. filepath;
end

-- 加载单个文件
function Common:LoadFile(filepath)
    if (FileCacheMap[filepath]) then return FileCacheMap[filepath] end

    local file = ParaIO.open(self:GetFullFilePath(filepath), "r");
    if (not file:IsValid()) then return end
    
    local text = file:GetText();
    file:close();

    FileCacheMap[filepath] = {
        filepath = filepath,
        sha = Encoding.sha1(text or "", "base64"),
        text = text,
    }

    return FileCacheMap[filepath];
end

-- 加载所有同步文件
function Common:LoadFileSyncDirectory()
    -- FileSyncDebug.Format(__rts__:GetName());
    local filelist = GetFileList(self:GetFileSyncDirectory(), nil, true);
    for _, filepath in ipairs(filelist) do
        if (filepath ~= ConfigFileName) then
            if(not self:LoadFile(filepath)) then 
                FileSyncDebug.Format("无效读取文件: %s", self:GetFullFilePath(filepath));
            end
        end
    end
    -- FileSyncDebug(FileCacheMap);
end

-- 生成配置文件
function Common:GenerateConfig()
    self:WriteConfig({filelist = self:GetFileList()});
    return ;
end

-- 读配置
function Common:ReadConfig()
    -- 读取配置文件
    local file = ParaIO.open(self:GetConfigFileName(), "r");
    if(not file:IsValid()) then return {} end

    local text = file:GetText();
    file:close();

    return NPL.LoadTableFromString(text) or {};
end

-- 写配置
function Common:WriteConfig(config)
    local file = ParaIO.open(self:GetConfigFileName(), "w");
    -- local text = commonlib.serialize_compact(config);
    local text = commonlib.serialize(config, true);
    
	file:WriteString(text);
	file:close();
end

-- 线程静态初始化
function Common:ThreadStaticInit(fileSyncDir)
    self:SetFileSyncDirectory(fileSyncDir);
    
    if (IsServer) then
        self:LoadFileSyncDirectory();
        self:GenerateConfig();
    else
        
    end

    local config = self:ReadConfig();
    local filelist = config.filelist or {};

    for _, fileitem in ipairs(filelist) do
        local filepath = fileitem.filepath;
        FileCacheMap[filepath] = FileCacheMap[filepath] or {};
        FileCacheMap[filepath].filepath = fileitem.filepath;
        FileCacheMap[filepath].sha = fileitem.sha;
    end

    FileSyncDebug(FileCacheMap, __rts__:GetName());
end

-- 获取文件列表
function Common:GetFileList()
    local filelist = {};
    for _, fileitem in pairs(FileCacheMap) do 
        if (fileitem.filepath ~= ConfigFileName) then
            table.insert(filelist, {
                filepath = fileitem.filepath,
                sha = fileitem.sha,
            });
        end
    end
    return filelist;
end

-- 设置同步文件
function Common:SetSyncFile(filecache)
    if (not filecache or not filecache.filepath) then return end

    local file = ParaIO.open(self:GetFullFilePath(filecache.filepath), "w");
	file:WriteString(filecache.text or "");
    file:close();

    -- 更新文件缓存
    FileCacheMap[filecache.filepath] = FileCacheMap[filecache.filepath] or {};
    FileCacheMap[filecache.filepath].filepath = filecache.filepath; 
    FileCacheMap[filecache.filepath].sha = filecache.sha;           
    self:GenerateConfig();
end

-- 设置同步文件列表
function Common:SetSyncFileList(filelist, callback)
    if (not filelist) then return end
    
    -- FileSyncDebug(FileCacheMap, __rts__:GetName());
    for _, fileitem in ipairs(filelist) do
        local oldfileitem = FileCacheMap[fileitem.filepath];
        if (not oldfileitem or oldfileitem.sha ~= fileitem.sha) then
            if (type(callback) == "function") then callback(fileitem.filepath) end
        end
    end
end

-- 情况缓存
function Common:ClearSyncFileCache()
    FileCacheMap = {};
end

-- 初始化环境
Common:InitSingleton();





