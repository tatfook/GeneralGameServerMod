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

local FileSync = NPL.export();

local FileSyncConfig = {};
local FileList = nil;
local FileSyncDir = nil;

-- 获取配置文件路径
function FileSync:GetConfigFileName()
    return FileSyncDir .. "config.json";
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

-- 初始化
function FileSync:Init()
    if (self.inited) then return end
    
    self.inited = true;

    FileSyncDir = ParaIO.GetCurDirectory(0) .. "FileSync/";

    -- 确保目录存在
    ParaIO.CreateDirectory(FileSyncDir);

    FileSyncConfig = self:ReadConfig();

    self:Sync();
end

-- 同步文件
function FileSync:Sync()
end

-- 初始化环境
FileSync:Init();