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
local PathAliasMap = {
    ["ui"] = "Mod/GeneralGameServerMod/UI",
    ["tutorial"] = "Mod/GeneralGameServerMod/Tutorial",
    ["vue"] = "Mod/GeneralGameServerMod/UI/Vue",
    ["world_directory"] = function() 
        return GameLogic.GetWorldDirectory();
    end
}; 

local FileCacheMap = {};

function Helper.SetPathAlias(alias, path)
    PathAliasMap[string.lower(alias)] = path or "";
end

-- 格式化文件名
function Helper.FormatFilename(filename)
    local path = string.gsub(filename or "", "%%(.-)%%", function(alias)
        local path = PathAliasMap[string.lower(alias)];
        if (type(path) == "string") then return path end
        if (type(path) == "function") then return path() end
        return "";
    end);
    path = string.gsub(path, "^@", GameLogic.GetWorldDirectory());
    return string.gsub(path, "/+", "/");
end

-- 获取脚本文件
function Helper.ReadFile(filename)
    filename = Helper.FormatFilename(filename);
    if (not filename or filename ==  "") then return end

    if (FileCacheMap[filename]) then return FileCacheMap[filename] end
    
    -- GGS.INFO("读取文件: " .. filename);

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


local BeginTime = 0;
function Helper.BeginTime()
    BeginTime = ParaGlobal.timeGetTime();
end

function Helper.EndTime(action, isResetBeginTime)
    local curTime = ParaGlobal.timeGetTime();
    GGS.INFO.Format("%s 耗时: %sms", action or "", curTime - BeginTime);
    if (isResetBeginTime) then BeginTime = curTime end
end
