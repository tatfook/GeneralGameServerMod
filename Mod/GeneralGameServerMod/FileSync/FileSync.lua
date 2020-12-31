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
NPL.load("(gl)script/ide/Json.lua");
local GGS = NPL.load("Mod/GeneralGameServerMod/Core/Common/GGS.lua");

local FileSync = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local FileSyncDebug = GGS.Debug.GetModuleDebug("FileSyncDebug");

FileSync:Property("FileSyncDirectory"); -- 同步目录

local FileSyncConfig = {};
local FileCacheMap = {};
local NID = nil;                        -- 当前连接的 NID
local NeuronFile = "Mod/GeneralGameServerMod/FileSync/FileSync.lua";
local ThreadName = "FileSync";

function FileSync:ctor()

end

-- 获取配置文件路径
function FileSync:GetConfigFileName()
    return self:GetFileSyncDirectory() .. "Config.json";
end

-- 获取文件全路径
function FileSync:GetFullFilePath(filepath)
    return self:GetFileSyncDirectory() .. filepath;
end

-- 读配置
function FileSync:ReadConfig()
    -- 读取配置文件
    local file = ParaIO.open(self:GetConfigFileName(), "r");
    if(not file:IsValid()) then return {} end

    local text = file:GetText();
    file:close();

    FileSyncConfig = commonlib.Json.Decode(text) or {};

    FileSyncDebug(FileSyncConfig);

    return FileSyncConfig;
end

-- 写配置
function FileSync:WriteConfig()
    local file = ParaIO.open(self:GetConfigFileName(), "w");
    local text = commonlib.Json.Encode(FileSyncConfig);

	file:WriteString(text);
	file:close();
end

-- 获取文件列表
function FileSync:GetFileList()
    return FileSyncConfig.FileList or {};
end

-- 加载列表文件
function FileSync:LoadListFile()
    local filelist = self:GetFileList();
    for _, fileitem in ipairs(filelist) do
        local filepath = fileitem.filepath;
        local filecache = FileCacheMap[filepath] or {};
        FileCacheMap[filepath] = filecache;
        if (not filecache.sha or filecache.sha ~= fileitem.sha) then
            local file = ParaIO.open(self:GetFullFilePath(filepath), "r");
            if(file:IsValid()) then 
                filecache.sha = fileitem.sha;
                filecache.filepath = filepath;
                filecache.text = file:GetText();
                file:close();
            else
                FileSyncDebug.Format("无效读取文件: %s", self:GetFullFilePath(filepath));
            end
        end
    end
    FileSyncDebug(FileCacheMap);
end

-- 主线程初始化
function FileSync:StaticInit()
    if (self.inited) then return end
    self.inited = true;

    local fileSyncDir = ParaIO.GetCurDirectory(0) .. "FileSync/";
    if (IsDevEnv) then fileSyncDir = "D:/workspace/npl/GeneralGameServerMod/Mod/GeneralGameServerMod/FileSync/Test/" .. (IsServer and "Server/" or "Client/") end

    FileSyncDebug.Format("文件同步目录: %s", fileSyncDir);

    self:SetFileSyncDirectory(fileSyncDir);

    -- 确保目录存在
    ParaIO.CreateDirectory(fileSyncDir);
    -- 暴露通信接口
    NPL.AddPublicFile(NeuronFile, 1000);

    -- if (__rts__:GetName() == "main") then
    --     -- 创建文件同步线程
    --     NPL.CreateRuntimeState(ThreadName, 0):Start(); 
    --     self:Send({action = "Init", ""})
    -- else

    -- end
    if (IsDevEnv) then 
        ThreadName = "main";
        if (not IsServer) then
            self:SetIpPort("127.0.0.1", 9000);
        end
    end
    self:Send({action = "Init"}, "")
end

function FileSync:SetIpPort(ip, port)
    NID = tostring(ip) .. "_" .. tostring(port);
    NPL.AddNPLRuntimeAddress({host = tostring(ip), port = tostring(port), nid = NID});
    self:GetRemoteFileSyncConfig();
end

-- 加载脚本
function FileSync:Load(moduleName)
end

-- 获取服务器配置信息
function FileSync:GetRemoteFileSyncConfig()
    self:Send({action = "GetRemoteFileSyncConfig"});
end

-- 设置服务器配置信息
function FileSync:SetRemoteFileSyncConfig(config)
    if (not config) then return end
    local remoteFileList = config.FileList;
    local filelist = self:GetFileList();
    local filemap = {};

    for _, fileitem in ipairs(filelist) do filemap[fileitem.filepath] = fileitem end
    for _, fileitem in ipairs(remoteFileList) do
        local oldfileitem = filemap[fileitem.filepath];
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
end

-- 刷新
function FileSync:Refresh()
    self:Send({action = "Refresh"});
end

-- 发送数据
function FileSync:Send(data, nid, threadName, neuronFile)
    nid, threadName, neuronFile = nid or NID, threadName or ThreadName, neuronFile or NeuronFile;
    local address = string.format("(%s)%s%s", threadName, (nid and nid ~= "") and (nid .. ":") or "", neuronFile);
    FileSyncDebug(address, data)
    if (NPL.activate(address, {action = "connection"}) ~= 0) then
        FileSyncDebug("send data failed, address = " .. address);
    end
    if (NPL.activate(address, data) ~= 0) then
        FileSyncDebug("send data failed, address = " .. address);
    end
end

-- 激活函数
function FileSync:OnActivate(msg)
    if (type(msg) ~= "table") then return end
    NID = msg.nid or msg.tid;
    
    local action = msg.action;
    FileSyncDebug(msg);

    if (action == "GetRemoteFileSyncConfig") then
        self:Send({action = "SetRemoteFileSyncConfig", config = FileSyncConfig});
    elseif (action == "SetRemoteFileSyncConfig") then
        self:SetRemoteFileSyncConfig(msg.config);
    elseif (action == "GetSyncFile") then
        self:Send({action = "SetSyncFile", filecache = FileCacheMap[msg.filepath]});
    elseif (action == "SetSyncFile") then
        self:SetSyncFile(msg.filecache);
    elseif (action == "Refresh") then
        self:ReadConfig();
        self:LoadListFile();
        self:Send({action = "SetRemoteFileSyncConfig", config = FileSyncConfig});
    elseif (action == "Init") then
        self:ReadConfig();
        if (IsServer) then self:LoadListFile() end
    end
end

-- 初始化环境
FileSync:InitSingleton():StaticInit();

NPL.this(function() 
	FileSync:OnActivate(msg);
end);


-- local FileSyncTest = NPL.load("FileSync/FileSyncTest.lua");
-- echo(FileSyncTest)

--[[
配置文件格式:
{
    FileList = {
        filepath = "Test.lua",  -- 相对目录为文件同步目录
        sha = "哈希值",  -- 检测文件内容是否更新
        type = "lua",   -- text, lua, xml,  lua 可以配合autoload=true程序启动加载
        autoload = false, -- 是否自动使用NPL.load加载脚本
        moduleName = "key.key.key",  -- lua 文件使用
    }
}
--]]