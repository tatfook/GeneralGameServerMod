
--[[
Title: FileSync
Author(s): wxa
Date: 2020-06-12
Desc: 文件同步
use the lib:
------------------------------------------------------------
local NetClientHandler = NPL.load("Mod/GeneralGameServerMod/FileSync/NetClientHandler.lua");
------------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Core/Common/Connection.lua");

local Common = NPL.load("Mod/GeneralGameServerMod/FileSync/Common.lua");
local NetClientHandler = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection"), NPL.export());

local FileSyncDebug = GGS.Debug.GetModuleDebug("FileSyncDebug");

function NetClientHandler:ctor()
    self:SetSynchronousSend(true);
    self:SetThreadName("FileSync");
    self:SetRemoteNeuronFile("Mod/GeneralGameServerMod/FileSync/NetServerHandler.lua");
    self:SetNetHandler(self);
end

function NetClientHandler:handleMsg(msg)
    local action = msg.action;

    FileSyncDebug(action, __rts__:GetName());

    if (action == "SetIpPort") then
        self:Init({ip = msg.ip, port = msg.port});
    elseif (action == "StaticInit") then
        Common:ThreadStaticInit(msg.fileSyncDir);
    elseif (action == "GetSyncFileList") then
        self:Send(msg);
    elseif (action == "SetSyncFileList") then
        Common:SetSyncFileList(msg.filelist, function(filepath) 
            self:Send({action = "GetSyncFile", filepath = filepath});
        end);
    elseif (action == "GetSyncFile") then
        self:Send(msg);
    elseif (action == "SetSyncFile") then
        Common:SetSyncFile(msg.filecache);
    elseif (action == "Refresh") then
        Common:ClearSyncFileCache();
        self:Send({action = "GetSyncFileList"});
    end
end

-- 初始化环境
NetClientHandler:InitSingleton()

NPL.this(function()
    NetClientHandler:OnActivate(msg);
end)