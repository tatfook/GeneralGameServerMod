
--[[
Title: FileManager
Author(s): wxa
Date: 2020/6/30
Desc: 文件管理器
use the lib:
-------------------------------------------------------
local FileManager = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/Pages/FileManager.lua");
-------------------------------------------------------
]]

local FileManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local lfs = commonlib.Files.GetLuaFileSystem();
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");

FileManager:Property("Directory", "");  -- 目录
FileManager:Property("FileName", "");   -- 当前文件名


local function ToCanonicalFilePath(filename)
	if(System.os.GetPlatform()=="win32") then
		filename = string.gsub(filename, "/+", "\\");
	else
		filename = string.gsub(filename, "\\+", "/");
	end
	return filename;
end

function FileManager:ctor()
    self.files = {};
end

function FileManager:Init()
    if (self.inited) then return end
    self.inited = true;

    local worlddir = ParaWorld.GetWorldDirectory();
    local directory = ToCanonicalFilePath(worlddir .. "/blockly/");

    -- 确保目存在
    ParaIO.CreateDirectory(directory);

    self:SwitchDirectory(directory);
end


-- 新建文件
function FileManager:NewFile(filename)
    if (not string.match(filename, "%.xml$")) then filename = filename .. ".xml" end

    if (self.files[filename]) then return end

    self.files[filename] = {
        filepath = ToCanonicalFilePath(self:GetDirectory() .. "/" .. filename),
        filename = filename,
        text = ""
    }

    return self.files[filename];
end

-- 移除文件
function FileManager:DeleteFile(filename)
    local file = self.files[filename];
    if (not file) then return end
    ParaIO.DeleteFile(file.filepath);
end

-- 切换目录
function FileManager:SwitchDirectory(directory)
    if (self:GetDirectory() == directory) then return end

    self:SetDirectory(directory);

    self.files = {};
    for filename in lfs.dir(directory) do
        if (filename ~= "." and filename ~= "..") then
            local filepath = ToCanonicalFilePath(directory .. "/" .. filename);
            local fileattr = lfs.attributes(filepath);

            if (fileattr.mode ~= "directory" and string.match(filename, "%.xml$")) then
                self.files[filename] = {
                    filename = filename,
                    filepath = filepath,
                };
            end
        end
    end
end

-- 获取文件集
function FileManager:GetFileList()
    local filelist = {};
    for filename in pairs(self.files) do table.insert(filelist, {filename = filename}) end
    return filelist;
end

-- 保存当前文件
function FileManager:Save(text)
    local filename = self:GetFileName();
    local file = self.files[filename];
    if (not file) then return end
    file.text = text;

    local io = ParaIO.open(file.filepath, "w");
	io:WriteString(text);
	io:close();
end

function FileManager:Show()
    Page.Show({
        FileManager = FileManager,
    }, {
        url = "%ui%/Blockly/Pages/FileManager.html",
        width = 600,
        height = 500,
        zorder = 1,
    });
end

FileManager:InitSingleton();