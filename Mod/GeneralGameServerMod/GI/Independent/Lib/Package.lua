--[[
Title: Package
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local Package = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/Package.lua");
------------------------------------------------------------
]]

local Package = inherit(ToolBase, module("Package"));

Package:Property("Name");

function Package:ctor()
end

-- local function GetFileList(directory, prefix)
--     local list = {};
--     for filename in lfs.dir(directory) do
--         if (filename ~= "." and filename ~= "..") then
--             local filepath = ToCanonicalFilePath(directory .. "/" .. filename);
--             local fileattr = lfs.attributes(filepath);
--             if (fileattr.mode == "directory") then
--                 if (recursive) then
--                     local sublist = GetFileList(filepath, subprefix, recursive);
--                     for _, item in ipairs(sublist) do table.insert(list, #list + 1, item) end
--                 end
--             else
--                 table.insert(list, #list + 1, subprefix);
--             end
--         end
--     end
--     return list;
-- end

function LoadPackage(package_name)
    local filename = ToCanonicalFilePath(__package_directory__ .. "/" .. package_name .. "/" .. "package.lua");
    local pkg_cfg = ReadFileText(filename);
    echo(pkg_cfg, true);
end

