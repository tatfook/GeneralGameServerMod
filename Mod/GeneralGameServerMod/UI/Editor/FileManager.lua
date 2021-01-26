
local lfs = commonlib.Files.GetLuaFileSystem();
local GlobalScope = GetGlobalScope();

_G.Directory = "";
_G.FileMap = {};
_G.DefaultFileName = "index";

FileList = {};          -- 目录
FileName = "";          -- 新增文件名

GlobalScope:Set("CurrentFileName", "");  -- 当前文件名

-- 获取目录
local function GetDirectory()
    return _G.Directory;
end

local function GetCurrentFileName()
    return GlobalScope:Get("CurrentFileName");
end

-- 新建文件
local function NewFile(filename)
    if (_G.FileMap[filename]) then return end

    _G.FileMap[filename] = {
        filepath = ToCanonicalFilePath(GetDirectory() .. "/" .. filename),
        filename = filename,
        text = ""
    }

    return _G.FileMap[filename];
end

-- 移除文件
local function DeleteFile(filename)
    local file = _G.FileMap[filename];
    if (not file) then return end
    ParaIO.DeleteFile(file.filepath);
    _G.FileMap[filename] = nil;
end

-- 保存当前文件
local function SaveFile(filename, text)
    local file = _G.FileMap[filename];
    if (not file) then return false end
    file.text = text or file.text or "";
    local io = ParaIO.open(file.filepath, "w");
	io:WriteString(file.text);
    io:close();
    return true;
end

-- 保存Html文件
local function SaveHtml(filename, text)
    local filepath = ToCanonicalFilePath(GetDirectory() .. "/" .. filename .. ".html");
    local io = ParaIO.open(filepath, "w");
    io:WriteString(text);
    io:close();
end

-- 加载文件
local function LoadFile(filename)
    local file = _G.FileMap[filename];
    if (not file) then return "" end
    if (file.text) then return file.text end
    local io = ParaIO.open(file.filepath, "r");
    local text = "";
    if(io:IsValid()) then 
        text = io:GetText();
        io:close();
    end
    file.text = text;
    return file.text;
end

local function EditFile(filename)
    local file = _G.FileMap[filename];
    -- if (not file) then return end
    if (not file) then return print("编辑文件不存在: ", filename) end
    GlobalScope:Set("CurrentFileName", filename);
    _G.LoadFromText(LoadFile(filename));
end

-- 切换目录
local function SwitchDirectory(directory)
    if (not directory or directory == "") then return end

    directory = ToCanonicalFilePath(ParaWorld.GetWorldDirectory() .. "/" .. directory .. "/");

    if (_G.Directory == directory) then return end

    print("UI 目录:", directory);
    ParaIO.CreateDirectory(directory);

    _G.Directory = directory;

    for filename in lfs.dir(directory) do
        if (filename ~= "." and filename ~= "..") then
            local filepath = ToCanonicalFilePath(directory .. "/" .. filename);
            local fileattr = lfs.attributes(filepath);

            if (fileattr.mode ~= "directory" and not string.match(filename, "%.html$")) then
                _G.FileMap[filename] = {
                    filename = filename,
                    filepath = filepath,
                };
            end
        end
    end

    -- 新建默认文件名
    NewFile(DefaultFileName);
    
    local filelist = {};
    for key, file in pairs(_G.FileMap) do
        table.insert(filelist, {filename = file.filename});
    end
    FileList = filelist;
end

_G.SaveCurrentFile = function()
    local CurrentFileName = GetCurrentFileName();
    SaveFile(CurrentFileName, _G.SaveToText());
    SaveHtml(CurrentFileName, _G.GenerateCode())
end

_G.EditDefaultFile = function()
    EditFile(DefaultFileName);
end

function ClickNewBtn()
    if (FileName == "") then return end

    local file = NewFile(FileName);
    if (not file) then return end

    table.insert(FileList, 1, {filename = file.filename});
    FileName = "";
end

function ClickDeleteBtn(file, index)
    table.remove(FileList, index);
    DeleteFile(file.filename);
    if (file.filename == GetCurrentFileName()) then
        EditFile(DefaultFileName);
    end
end

function ClickEditBtn(file, index)
    local CurrentFileName = GetCurrentFileName();
    if (file.filename == CurrentFileName) then return end

    if (CurrentFileName == "") then
        return EditFile(file.filename);
    end

    ShowWindow({
        text = "是否保存当前文件: " .. CurrentFileName,
        confirm = function()
            _G.SaveCurrentFile();
            EditFile(file.filename)
        end,
        cancel = function()
            EditFile(file.filename)
        end,
    }, {
        url = "%ui%/Common/MessageBox.html",
        draggable = false,
        width = "80%",
        height = "80%",
        zorder = 2,
    });
end

function OnReady()
    SwitchDirectory("code/ui");
end

-- 属性
-- function OnAttrValueChange(attrName, attrValue)
--     if (attrName == "directory") then
--         SwitchDirectory(attrValue);
--     end
-- end


-- -- 编辑
-- function FileManager:EditFile(filename)
--     if (filename == self:GetFileName()) then return end
    
--     -- print("-----------edit file---------------", filename);
    
--     self:Save();

--     self:SetFileName(filename);

--     local text = self:Load();

--     local blockly = self:GetBlockly();
--     if (not blockly) then return end

--     blockly:LoadFromXmlNodeText(text);
-- end

-- -- 切换目录
-- function FileManager:SwitchDirectory(directory)
--     directory = directory or self:GetDefaultDirectory();

--     if (self:GetDirectory() == directory) then return end

--     self:SetDirectory(directory);

--     self.files = {};
--     for filename in lfs.dir(directory) do
--         if (filename ~= "." and filename ~= "..") then
--             local filepath = ToCanonicalFilePath(directory .. "/" .. filename);
--             local fileattr = lfs.attributes(filepath);

--             if (fileattr.mode ~= "directory" and string.match(filename, "%.xml$")) then
--                 self.files[filename] = {
--                     filename = filename,
--                     filepath = filepath,
--                 };
--             end
--         end
--     end

--     local defaultFileName = self:GetDefaultFileName();
--     if (not self.files[defaultFileName]) then
--         self.files[defaultFileName] = {
--             filepath = ToCanonicalFilePath(self:GetDirectory() .. "/" .. defaultFileName);
--             filename = defaultFileName,
--             text = "",
--         }
--     end
-- end

-- -- 获取文件集
-- function FileManager:GetFileList()
--     local filelist = {};
--     for filename in pairs(self.files) do table.insert(filelist, {filename = filename}) end
--     return filelist;
-- end

-- -- 加载所有文件
-- function FileManager:LoadAll()
--     for filename in pairs(self.files) do 
--         self:Load(filename);
--     end
-- end

-- -- 遍历
-- function FileManager:Each(callback)
--     for _, file in pairs(self.files) do
--         callback(file);
--     end
-- end