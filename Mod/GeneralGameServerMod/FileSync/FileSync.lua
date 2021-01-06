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

local FileSync = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local FileSyncDebug = GGS.Debug.GetModuleDebug("FileSyncDebug");

FileSync:Property("FileSyncDirectory");  -- 同步目录

local NeuronFile = "Mod/GeneralGameServerMod/FileSync/FileSync.lua";
local ThreadName = "FileSync";

local function ToCanonicalFilePath(filename)
	if(System.os.GetPlatform()=="win32") then
		filename = string.gsub(filename, "/+", "\\");
	else
		filename = string.gsub(filename, "\\+", "/");
	end
	return filename;
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
    NeuronFile = IsServer and "Mod/GeneralGameServerMod/FileSync/NetServerHandler.lua" or "Mod/GeneralGameServerMod/FileSync/NetClientHandler.lua"
    NPL.AddPublicFile(NeuronFile, 1000);

    -- 创建文件同步线程
    NPL.CreateRuntimeState(ThreadName, 0):Start(); 

    -- 工作线程初始化
    self:Send({action = "StaticInit", fileSyncDir = fileSyncDir})
end

-- 获取服务器配置信息
function FileSync:GetSyncFileList()
    self:Send({action = "GetSyncFileList"});
end

-- 获取同步文件
function FileSync:GetSyncFile(filepath)
    self:Send({action = "GetSyncFile", filepath = filepath});
end

-- 刷新
function FileSync:Refresh()
    self:Send({action = "Refresh"});
end

-- 设置服务地址
function FileSync:SetIpPort(ip, port)
    return self:Send({ip = ip, port = port, action = "SetIpPort"});
end

-- 发送数据
function FileSync:Send(data)
    -- FileSyncDebug(string.format("(%s)%s", ThreadName, NeuronFile));
    NPL.activate(string.format("(%s)%s", ThreadName, NeuronFile), data);
end

-- 初始化环境
FileSync:InitSingleton():StaticInit();





