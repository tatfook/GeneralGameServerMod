--[[
Title: FileSync
Author(s): wxa
Date: 2020-06-12
Desc: 文件同步
use the lib:
------------------------------------------------------------
local FileSync = NPL.load("Mod/GeneralGameServerMod/FileSync/FileSync.lua");
------------------------------------------------------------
]]
local GGS = NPL.load("Mod/GeneralGameServerMod/Core/Common/GGS.lua");

NPL.load("(gl)script/ide/System/Encoding/sha1.lua");
local Encoding = commonlib.gettable("System.Encoding");

local Config = NPL.load("./Config.lua");

local FileSync = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local FileSyncDebug = GGS.Debug.GetModuleDebug("FileSyncDebug");

FileSync:Property("FileSyncDirectory");  -- 同步目录
FileSync:Property("FileSyncConfig");     -- 同步配置

local FileCacheMap = {};                 -- 文件缓存
local NID = nil;                         -- 当前连接的 NID
local NeuronFile = "Mod/GeneralGameServerMod/FileSync/FileSync.lua";
local ThreadName = "FileSync";
local ConfigFileName = "Config.txt";
local lfs = commonlib.Files.GetLuaFileSystem();

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

-- FileSyncDebug(GetFileList("D:/workspace/npl/GeneralGameServerMod/Mod/GeneralGameServerMod/FileSync/Test/", nil, true));

function FileSync:ctor()

end

function FileSync:Init(fileSyncDir)
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

-- 加载所有同步文件
function FileSync:LoadFileSyncDirectory()
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

-- 获取文件列表
function FileSync:GetFileList()
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

-- 获取配置文件路径
function FileSync:GetConfigFileName()
    return self:GetFileSyncDirectory() .. ConfigFileName;
end

-- 获取文件全路径
function FileSync:GetFullFilePath(filepath)
    return self:GetFileSyncDirectory() .. filepath;
end

-- 生成配置文件
function FileSync:GenerateConfig()
    self:WriteConfig({filelist = self:GetFileList()});
    return ;
end

-- 读配置
function FileSync:ReadConfig()
    -- 读取配置文件
    local file = ParaIO.open(self:GetConfigFileName(), "r");
    if(not file:IsValid()) then return {} end

    local text = file:GetText();
    file:close();

    FileSyncConfig = NPL.LoadTableFromString(text) or {};

    return FileSyncConfig;
end

-- 写配置
function FileSync:WriteConfig(config)
    local file = ParaIO.open(self:GetConfigFileName(), "w");
    -- local text = commonlib.serialize_compact(config or FileSyncConfig);
    local text = commonlib.serialize(config or FileSyncConfig, true);
    
	file:WriteString(text);
	file:close();
end

-- 加载单个文件
function FileSync:LoadFile(filepath)
    if (FileCacheMap[filepath]) then return FileCacheMap[filepath] end

    local file = ParaIO.open(self:GetFullFilePath(filepath), "r");
    if (not file) then return end
    
    local text = file:GetText();
    file:close();

    FileCacheMap[filepath] = {
        filepath = filepath,
        sha = Encoding.sha1(text or "", "base64"),
        text = text,
    }

    return FileCacheMap[filepath];
end

-- 主线程初始化
function FileSync:StaticInit()
    if (self.inited or __rts__:GetName() ~= "main") then return end
    self.inited = true;

    local fileSyncDir = ParaIO.GetCurDirectory(0) .. "FileSync/";
    if (IsDevEnv) then fileSyncDir = "D:/workspace/npl/GeneralGameServerMod/Mod/GeneralGameServerMod/FileSync/Test/" .. (IsServer and "Server/" or "Client/") end
    
    fileSyncDir = ToCanonicalFilePath(fileSyncDir);

    FileSyncDebug.Format("文件同步目录: %s", fileSyncDir);

    -- 设置目录
    self:SetFileSyncDirectory(fileSyncDir);

    -- 确保目录存在
    ParaIO.CreateDirectory(fileSyncDir);
    -- 暴露通信接口
    NPL.AddPublicFile(NeuronFile, 1000);

    -- 创建文件同步线程
    NPL.CreateRuntimeState(ThreadName, 0):Start(); 
    -- 工作线程初始化
    self:Send({action = "Init", fileSyncDir = fileSyncDir})
end

function FileSync:SetIpPort(ip, port)
    if (IsMainThread()) then
        -- return self:Send({ip = ip, port = port, action = "SetIpPort"});
        return NPL.activate_with_timeout(timeout or 3, string.format("(%s)%s", ThreadName, NeuronFile), {ip = ip, port = port, action = "SetIpPort"});
    end

    NID = tostring(ip) .. "_" .. tostring(port);
    NPL.AddNPLRuntimeAddress({host = tostring(ip), port = tostring(port), nid = NID});
end

-- 获取服务器配置信息
function FileSync:GetSyncFileList()
    self:Send({action = "GetSyncFileList"});
end

-- 设置服务器配置信息
function FileSync:SetSyncFileList(filelist)
    if (not filelist) then return end
    
    FileSyncDebug(FileCacheMap, __rts__:GetName());

    for _, fileitem in ipairs(filelist) do
        local oldfileitem = FileCacheMap[fileitem.filepath];
        if (not oldfileitem or oldfileitem.sha ~= fileitem.sha) then
            self:GetSyncFile(fileitem.filepath);
        end
    end
end

-- 获取同步文件
function FileSync:GetSyncFile(filepath)
    self:Send({action = "GetSyncFile", filepath = filepath});
end

-- 设置同步文件
function FileSync:SetSyncFile(filecache)
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

-- 刷新
function FileSync:Refresh()
    self:Send({action = "Refresh"});
end

-- 发送数据
function FileSync:Send(data, nid, threadName, neuronFile, timeout)
    -- FileSyncDebug(data);
    nid, threadName, neuronFile = nid or NID, threadName or ThreadName, neuronFile or NeuronFile;
    local address = string.format("(%s)%s%s", threadName, (nid and nid ~= "") and (nid .. ":") or "", neuronFile);
    
    FileSyncDebug(address);

    -- 转至工作线程执行
    if (__rts__:GetName() == "main" and threadName ~= "main" and threadName ~= "gl") then 
        address = string.format("(%s)%s", threadName, neuronFile);
        if (NPL.activate_with_timeout(timeout or 3, address, {action = "Send", data = data}) ~= 0) then
            FileSyncDebug("send data failed, address = " .. address);
            return false;
        end
        return true;
    end
    
    -- timeout 超时秒数
    if (NPL.activate_with_timeout(timeout or 3, address, data) ~= 0) then
        FileSyncDebug("send data failed, address = " .. address);
        return false;
    end
    return true;
end

-- 激活函数
function FileSync:OnActivate(msg)
    if (type(msg) ~= "table") then return end
    
    NID = IsServer and (msg.nid or msg.tid) or NID;
    
    local action = msg.action;
    
    FileSyncDebug(__rts__:GetName(), action);

    if (action == "GetSyncFileList") then
        self:Send({action = "SetSyncFileList", filelist = self:GetFileList()});
    elseif (action == "SetSyncFileList") then
        self:SetSyncFileList(msg.filelist);
    elseif (action == "GetSyncFile") then
        self:Send({action = "SetSyncFile", filecache = self:LoadFile(msg.filepath)});
    elseif (action == "SetSyncFile") then
        self:SetSyncFile(msg.filecache);
    elseif (action == "Refresh") then
        self:Send({action = "SetSyncFileList", filelist = self:GetFileList()});
    elseif (action == "SetIpPort") then
        self:SetIpPort(msg.ip, msg.port);
    elseif (action == "Send") then
        self:Send(msg.data);
    elseif (action == "Init") then
        self:Init(msg.fileSyncDir)
    end
end

-- 初始化环境
FileSync:InitSingleton():StaticInit();

NPL.this(function() 
	FileSync:OnActivate(msg);
end);




