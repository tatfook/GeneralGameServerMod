--[[
Title: FileSyncConnection
Author(s): wxa
Date: 2020/6/12
Desc: FileSyncConnection
-------------------------------------------------------
local FileSyncConnection = NPL.load("Mod/GeneralGameServerMod/CommonLib/FileSyncConnection.lua");
-------------------------------------------------------
]]
local lfs = commonlib.Files.GetLuaFileSystem();

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local RPCVirtualConnection = NPL.load("Mod/GeneralGameServerMod/CommonLib/RPCVirtualConnection.lua", IsDevEnv);

local FileSyncConnection = commonlib.inherit(RPCVirtualConnection, NPL.export());

local __neuron_file__ = "Mod/GeneralGameServerMod/CommonLib/FileSyncConnection.lua";
FileSyncConnection:Property("RemoteNeuronFile", __neuron_file__);       -- 对端处理文件
FileSyncConnection:Property("LocalNeuronFile", __neuron_file__);        -- 本地处理文件
FileSyncConnection:Property("SyncFinishCallBack");                      -- 同步完成回调
FileSyncConnection:Property("SyncFailedCallBack");                      -- 同步失败回调

FileSyncConnection:Register("SyncFinish", function()
    local callback = self:GetSyncFinishCallBack();
    -- print("======================response sync finish========================");
    if (type(callback) == "function") then callback() end 
end);

-- 客户端接收到文件内容同步
FileSyncConnection:Register("SyncFile", function(data)
    local local_file_path = data.local_file_path or CommonLib.ToCanonicalFilePath(self.__local_file_path__ .. data.file_rel_path);
    -- print("=====================response syncfile=====================");
    ParaIO.CreateDirectory(local_file_path);
    CommonLib.WriteFile(local_file_path, data.remote_file_text);
end);

-- 服务端响应请求文件列表
FileSyncConnection:Register("FileList", function(data)
    -- print("=====================response FileList=====================");
    self.__local_file_path__, self.__remote_file_path__ = data.local_file_path, data.remote_file_path;
    if (data.is_relative_root_directory) then self.__local_file_path__ = CommonLib.ToCanonicalFilePath(CommonLib.GetRootDirectory() .. self.__local_file_path__) end 
    print(self.__local_file_path__, self.__remote_file_path__);
    local __remote_file_map__ = {};
    for _, fileitem in ipairs(data.remote_file_list or {}) do
        __remote_file_map__[CommonLib.ToCanonicalFilePath(fileitem.file_rel_path)] = fileitem;
    end

    local __difflist__ = {};
    local __local_file_list__ = self:GetFileList();
    
    for _, local_fileitem in ipairs(__local_file_list__) do
        local remote_fileitem = __remote_file_map__[local_fileitem.file_rel_path];
        if (not remote_fileitem or remote_fileitem.file_md5 ~= local_fileitem.file_md5) then
            table.insert(__difflist__, {
                remote_file_path = local_fileitem.file_path,
                remote_file_md5 = local_fileitem.file_md5,
                local_file_path = remote_fileitem and remote_fileitem.file_path,
                local_file_md5 = remote_fileitem and remote_fileitem.file_md5,
                file_rel_path = local_fileitem.file_rel_path,
            });
        end
    end

    local index = 1;
    local function SyncNextFile()
        if (index > #__local_file_list__) then 
            -- 同步完成
            -- print("======================request sync finish========================");
            return self:Call("SyncFinish"); 
        end

        local local_fileitem = __local_file_list__[index];
        index = index + 1;

        local remote_fileitem = __remote_file_map__[local_fileitem.file_rel_path];
        if (not remote_fileitem or remote_fileitem.file_md5 ~= local_fileitem.file_md5) then
            -- print("===================request syncfile===============", local_fileitem.file_path);
            self:Call("SyncFile", {
                file_rel_path = local_fileitem.file_rel_path,
                local_file_path = remote_fileitem and remote_fileitem.file_path,
                remote_file_path = local_fileitem.file_path,
                remote_file_text = CommonLib.GetFileText(local_fileitem.file_path);
            }, function()
                -- 处理完成同步下一个文件
                SyncNextFile();
            end);
        else
            print("================The file contents are the same and out of sync===================", local_fileitem.file_rel_path);
            SyncNextFile();
        end
    end

    SyncNextFile();

    return __difflist__;
end);

function FileSyncConnection:GetFileList()
    if (self.__filelist__) then return self.__filelist__ end
    self.__filelist__ = CommonLib.GetFileList(self.__local_file_path__, true, true);
    return self.__filelist__;
end

function FileSyncConnection:Sync(data)
    self.__local_file_path__, self.__remote_file_path__ = data.local_file_path, data.remote_file_path;
    if (data.local_is_relative_root_directory) then self.__local_file_path__ = CommonLib.ToCanonicalFilePath(CommonLib.GetRootDirectory() .. self.__local_file_path__) end 

    -- print("=====================request FileList=====================");
    self:SetSyncFinishCallBack(data.finish_callback);
    self:SetSyncFailedCallBack(data.failed_callback);
    self:Call("FileList", {
        is_relative_root_directory = data.remote_is_relative_root_directory,
        local_file_path = self.__remote_file_path__,
        remote_file_path = self.__local_file_path__,
        remote_file_list = self:GetFileList(),
    }, function(data)
    end);
end

function FileSyncConnection:HandleDisconnected(...)
    -- print("======================sync failed=====================");
    FileSyncConnection._super.HandleDisconnected(self, ...);
    local callback = self:GetSyncFailedCallBack();
    if (type(callback) == "function") then callback() end
    self:CloseConnection();
end


NPL.this(function()
    FileSyncConnection:OnActivate(msg);
end);