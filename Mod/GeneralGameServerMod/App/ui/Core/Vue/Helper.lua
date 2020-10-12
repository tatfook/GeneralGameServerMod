--[[
Title: Helper
Author(s): wxa
Date: 2020/6/30
Desc: 辅助类, 一些工具函数实现
use the lib:
-------------------------------------------------------
local Helper = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Helper.lua");
-------------------------------------------------------
]]

local Helper = (NPL and NPL.export) and NPL.export() or {};

-- 路径简写
local PathAliasMap = {}; 
local FileCacheMap = {};

function Helper.SetPathAlias(alias, path)
    PathAliasMap[string.lower(alias)] = path or "";
end

-- 格式化文件名
function Helper.FormatFilename(filename)
    return string.gsub(filename or "", "%%(.-)%%", function(alias)
        return PathAliasMap[string.lower(alias)];
    end);
end

-- 获取脚本文件
function Helper.ReadFile(filename)
    filename = Helper.FormatFilename(filename);
    if (not filename or filename ==  "") then return end

    if (FileCacheMap[filename]) then return FileCacheMap[filename] end
    
    local text = nil;
	local file = ParaIO.open(filename, "r");
    if(file:IsValid()) then
        text = file:GetText();
        file:close();
    else
        echo(string.format("ERROR: read file failed: %s ", filename));
    end

    FileCacheMap[filename] = text;
    return text;
end