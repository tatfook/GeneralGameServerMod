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
    return self:GetFileSyncDirectory() .. "config.json";
end

-- 读配置
function FileSync:ReadConfig()
    -- 读取配置文件
    local file = ParaIO.open(self:GetConfigFileName(), "r");
    if(not file:IsValid()) then return {} end

    local text = file:GetText();
    file:close();

    return NPL.LoadTableFromString(text) or {};
end

-- 写配置
function FileSync:WriteConfig()
    local file = ParaIO.open(self:GetConfigFileName(), "w");
    local text = commonlib.serialize_compact(FileSyncConfig);

	file:WriteString(text);
	file:close();
end

-- 加载列表文件
function FileSync:LoadListFile()
    local filelist = self:GetFileList();
    for _, fileitem in ipairs(filelist) do
        local filepath = fileitem.filepath;
        if (FileCacheMap[filepath].sha ~= fileitem.sha) then
            local file = ParaIO.open(filepath, "r");
            if(file:IsValid()) then 
                FileCacheMap[filepath].sha = fileitem.sha;
                FileCacheMap[filepath].text = file:GetText();
                file:close();
            end
        end
    end
end

-- 工作线程初始化
function FileSync:Init()
    FileSyncConfig = self:ReadConfig();

    if (IsServer) then
        self:LoadListFile();
    else
        self:GetRemoteFileSyncConfig();
    end
end

-- 主线程初始化
function FileSync:StaticInit()
    if (self.inited) then return end
    self.inited = true;

    local fileSyncDir = ParaIO.GetCurDirectory(0) .. "FileSync/";
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
    self:Init();
end

-- 获取文件列表
function FileSync:GetFileList()
    return FileSyncConfig.FileList or {};
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
end

-- 同步文件
function FileSync:Sync()
end

-- 发送数据
function FileSync:Send(data, nid, threadName, neuronFile)
    nid, threadName, neuronFile = nid or NID, threadName or ThreadName, neuronFile or NeuronFile;
    local address = string.format("(%s)%s%s", threadName, (nid and nid ~= "") and (nid .. ":") or "", neuronFile);
    if (NPL.activate(address, data) ~= 0) then
        FileSyncDebug("send data failed");
    end
end

-- 激活函数
function FileSync:OnActivate(msg)
    if (type(msg) ~= "table") then return end
    local NID = msg.nid or msg.tid;

    local action = msg.action;

    if (action == "GetRemoteFileSyncConfig") then
        self:Send({action = "SetRemoteFileSyncConfig", config = FileSyncConfig});
    elseif (action == "SetRemoteFileSyncConfig") then
        self:SetRemoteFileSyncConfig(msg.config);
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
        filepath = "FileSync/Test.lua",
        sha = "哈希值",  -- 检测文件内容是否更新
        type = "lua",   -- text, lua, xml,  lua 可以配合autoload=true程序启动加载
        autoload = false, -- 是否自动使用NPL.load加载脚本
        moduleName = "key.key.key",  -- lua 文件使用
    }
}
--]]