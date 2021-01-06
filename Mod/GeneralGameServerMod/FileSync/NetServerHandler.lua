--[[
Title: FileSync
Author(s): wxa
Date: 2020-06-12
Desc: 文件同步
use the lib:
------------------------------------------------------------
local NetServerHandler = NPL.load("Mod/GeneralGameServerMod/FileSync/NetServerHandler.lua");
------------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Core/Common/Connection.lua");

local Common = NPL.load("Mod/GeneralGameServerMod/FileSync/Common.lua");
local NetServerHandler = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection"), NPL.export());

local FileSyncDebug = GGS.Debug.GetModuleDebug("FileSyncDebug");

function NetServerHandler:ctor()
    -- self:SetSynchronousSend(true);
    self:SetThreadName("FileSync");
    self:SetDefaultNeuronFile("Mod/GeneralGameServerMod/FileSync/NetClientHandler.lua");
    self:SetNetHandler(self);
end

function NetServerHandler:StaticInit(fileSyncDir)
    Common:ThreadStaticInit(fileSyncDir);
end

function NetServerHandler:handleMsg(msg)
    local action = msg.action;

    FileSyncDebug(action, __rts__:GetName());

    if (action == "StaticInit") then
        self:StaticInit(msg.fileSyncDir);
    elseif (action == "GetSyncFileList") then
        self:Send({action = "SetSyncFileList", filelist = Common:GetFileList()});
    elseif (action == "GetSyncFile") then
        self:Send({action = "SetSyncFile", filecache = Common:LoadFile(msg.filepath)});
    end
end

NPL.this(function()
    NetServerHandler:OnActivate(msg);
end)
