--[[
Title: FileCache
Author(s):  wxa
Date: 2020-06-12
Desc: Command
use the lib:
------------------------------------------------------------
local FileCache = NPL.load("Mod/GeneralGameServerMod/Command/ProxyServer/FileCache.lua");
------------------------------------------------------------
]]
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");

local FileCache =  commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

FileCache:Property("CacheDirectory");                       -- 缓存目录
FileCache:Property("MaxFileCacheCount", 256);               -- 最大缓存文件数
FileCache:Property("MaxSingleFileCacheSize", 1024 * 1024);  -- 单个缓存文件最大1M

function FileCache:ctor()
    self.__file_cache_map__ = {};
    self.__file_cache_count__ = 0;
    self:SetCacheDirectory(CommonLib.ToCanonicalFilePath(CommonLib.GetRootDirectory() .. "/temp/filecache/"));
    ParaIO.CreateDirectory(self:GetCacheDirectory());
end

function FileCache:Init()
    return self;
end

function FileCache:GetFilePath(filename)
    return CommonLib.ToCanonicalFilePath(self:GetCacheDirectory() .. "/" .. filename);
end

function FileCache:AddFileCache(filename, text, isSaveFile)
    local filecache = {
        filename = filename,
        text = text,
        access_time = commonlib.TimerManager.timeGetTime(),
    }
    
    if ((#text) < self:GetMaxSingleFileCacheSize()) then
        if (self.__file_cache_count__ >= self:GetMaxFileCacheCount()) then
            local min_access_time, min_access_time_filename = filecache.access_time, filecache.filename; 
            for _, cache in pairs(self.__file_cache_map__) do
                if (cache.access_time < min_access_time) then
                    min_access_time, min_access_time_filename = cache.access_time, cache.filename;
                end
            end
            self.__file_cache_map__[min_access_time_filename] = nil;
            self.__file_cache_count__ = self.__file_cache_count__ - 1;
        end
        self.__file_cache_map__[filename] = filecache;
        self.__file_cache_count__ = self.__file_cache_count__ + 1;
    end

    if (isSaveFile) then CommonLib.WriteFile(self:GetFilePath(filename), text) end 

    return filecache;
end

function FileCache:IsExistFileCache(filename) 
    return self.__file_cache_map__[filename] ~= nil;
end

function FileCache:GetFileCache(filename)
    if (self.__file_cache_map__[filename]) then return self.__file_cache_map__[filename] end 
    local filepath = self:GetFilePath(filename);
    if(not CommonLib.IsExistFile(filepath)) then return end
    return self:AddFileCache(filename, CommonLib.GetFileText(filepath));
end

function FileCache:GetFileCacheText(filename)
    local filecache = self:GetFileCache(filename);
    return filecache and filecache.text;
end


-- texture/aries/books/fashionmagazine_v1/cloth_pic04.png.p,75f54246d5b9f38a74ed61696439b1dc,352066