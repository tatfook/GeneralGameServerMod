--[[
Title: FileAPI
Author(s):  wxa
Date: 2021-06-01
Desc: API 模板文件
use the lib:
------------------------------------------------------------
local FileAPI = NPL.load("Mod/GeneralGameServerMod/GI/Independent/API/FileAPI.lua");
------------------------------------------------------------
]]

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");

local FileAPI = NPL.export()

-- local function LoadPackage(package_name)

-- end

setmetatable(FileAPI, {__call = function(_, CodeEnv)
	CodeEnv.__package_directory__ = CommonLib.ToCanonicalFilePath(CommonLib.GetTempDirectory() .. "/ggs/packages");
    if (IsDevEnv) then CodeEnv.__package_directory__ = "Mod/GeneralGameServerMod/GI/Independent/Package" end 
    CodeEnv.ToCanonicalFilePath = CommonLib.ToCanonicalFilePath;
    CodeEnv.GetTempDirectory = CommonLib.GetTempDirectory;
    CodeEnv.GetWorldDirectory = CommonLib.GetWorldDirectory;
    CodeEnv.GetFileName = CommonLib.GetFileName;
    CodeEnv.GetFileText = CommonLib.GetFileText;
    CodeEnv.GetFileMD5 = CommonLib.GetFileMD5;
end});
