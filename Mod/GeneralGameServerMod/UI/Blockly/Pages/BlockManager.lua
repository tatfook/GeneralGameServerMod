--[[
Title: BlockManager
Author(s): wxa
Date: 2020/6/30
Desc: 文件管理器
use the lib:
-------------------------------------------------------
local BlockManager = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/Pages/BlockManager.lua");
-------------------------------------------------------
]]


local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");

local SystemCategoryAndBlockPaths = {
    "Mod/GeneralGameServerMod/UI/Blockly/Blocks/SystemLuaBlock.blockly",
}

local SystemCategoryMap, SystemBlockMap = {}, {};
local AllCategoryMap, AllBlockMap = {}, {};

local BlockManager = NPL.export();

local inited = false;
local Directory = nil; 
local FileName = nil; 

function BlockManager.LoadCategoryAndBlock(filename)
    filename = filename or FileName;
    local io = ParaIO.open(filename, "r");
    if(not io:IsValid()) then return nil end 
    local text = io:GetText();
    io:close();
    return NPL.LoadTableFromString(text);
end

function BlockManager.SaveCategoryAndBlock(filename)
    filename = filename or FileName;
    local text = commonlib.serialize_compact({AllBlockMap = AllBlockMap, AllCategoryMap = AllCategoryMap});
    local io = ParaIO.open(FileName, "w");
	io:WriteString(text);
    io:close();
end

function BlockManager.NewBlock(block)
    if (not block.type) then return end
    AllBlockMap[block.type] = {
        type = block.type,
        category = block.category,
        color = block.color,
        output = block.output,
        previousStatement = block.previousStatement,
        nextStatement = block.nextStatement,
        message = block.message,
        arg = block.arg,
        -- func_description = block.func_description,
        code_description = block.code_description,
        xml_text = block.xml_text,
    };
    BlockManager.SaveCategoryAndBlock();
end

function BlockManager.DeleteBlock(blockType)
    AllBlockMap[blockType] = nil;
    BlockManager.SaveCategoryAndBlock();
end

function BlockManager.GetAllCategoryMap()
    return AllCategoryMap;
end

function BlockManager.GetAllBlockMap()
    return AllBlockMap;
end

local function OnWorldLoaded()
    Directory = CommonLib.ToCanonicalFilePath(ParaIO.GetCurDirectory(0) .. ParaWorld.GetWorldDirectory() .. "/blockly/");
    local filename = CommonLib.ToCanonicalFilePath(Directory .. "/category_block.config");
    if (filename == FileName) then return end
    FileName = filename;
    
    -- 确保目存在
    ParaIO.CreateDirectory(directory);

    --加载数据
    AllBlockMap, AllCategoryMap = {}, {};
    local WorldCategoryBlock = BlockManager.LoadCategoryAndBlock();
    CategoryMap = WorldCategoryBlock and WorldCategoryBlock.AllCategoryMap or {};
    BlockMap = WorldCategoryBlock and WorldCategoryBlock.AllBlockMap or {};
    for categoryName, category in pairs(SystemCategoryMap) do
        AllCategoryMap[categoryName] = AllCategoryMap[categoryName] or {name = categoryName};
        commonlib.partialcopy(AllCategoryMap[categoryName], category);
    end
    for blockType, block in pairs(SystemBlockMap) do
        AllBlockMap[blockType] = block;  -- 直接覆盖
    end
    for categoryName, category in pairs(CategoryMap) do
        AllCategoryMap[categoryName] = AllCategoryMap[categoryName] or {name = categoryName};
        commonlib.partialcopy(AllCategoryMap[categoryName], category);
    end
    for blockType, block in pairs(BlockMap) do
        AllBlockMap[blockType] = block;  -- 直接覆盖
        AllCategoryMap[block.category] = AllCategoryMap[block.category] or {name = block.category};
    end
end

local function OnWorldUnloaded()
end

function BlockManager.StaticInit()
    if (inited) then return BlockManager end
    inited = true;
    
    for _, path in ipairs(SystemCategoryAndBlockPaths) do
        local SystemCategoryBlock = BlockManager.LoadCategoryAndBlock(path);
        local CategoryMap = SystemCategoryBlock.AllCategoryMap or {};
        local BlockMap = SystemCategoryBlock.AllBlockMap or {};
        for categoryName, category in pairs(CategoryMap) do
            SystemCategoryMap[categoryName] = SystemCategoryMap[categoryName] or {name = categoryName};
            commonlib.partialcopy(SystemCategoryMap[categoryName], category);
        end
        for blockType, block in pairs(BlockMap) do
            SystemBlockMap[blockType] = block;  -- 直接覆盖
        end
    end

    GameLogic:Connect("WorldLoaded", nil, OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", nil, OnWorldUnloaded, "UniqueConnection");
    
    OnWorldLoaded();

    return BlockManager;
end

local function ToNPL(block)
    local blockType = block:GetType();
    local option = AllBlockMap[blockType];
    if (not option) then return "" end
    local args = {};
    for i, arg in ipairs(option.arg) do
        if (arg.type == "input_value" or arg.type == "input_statement") then
            args[arg.name] = block:GetValueAsString(arg.name);
        else
            args[arg.name] = block:GetFieldValue(arg.name);
        end
    end 
    local code_description = string.gsub(option.code_description or "", "\\n", "\n");
    local code = string.gsub(code_description, "%$([%w_]+)", args);
    code = string.gsub(code, "%$%{([%w_]+)%}", args);
    code = string.gsub(code, "\n+$", "");
    code = string.gsub(code, "^\n+", "");
    if (not option.output) then code = code .. "\n" end
    return code;
end

function BlockManager.GetAllBlockList()
    local BlockList = {};
    for block_type, block in pairs(AllBlockMap) do 
        if (block_type ~= "") then
            block.ToNPL = ToNPL;
            table.insert(BlockList, block);
        end
    end
    return BlockList, AllBlockMap;
end

function BlockManager.GetAllCategoryList()
    local CategoryList = {};
    local CategoryMap = {};
    for _, category in pairs(AllCategoryMap) do
        local data = {
            name = category.name,
            text = category.text,
            color = category.color,
            blocktypes = {},
        }
        CategoryMap[data.name] = data;
        table.insert(CategoryList, data);
    end
    for block_type, block in pairs(AllBlockMap) do 
        if (block_type ~= "") then
            local categoryName = block.category;
            local category = CategoryMap[categoryName];
            if (not category) then
                category = {name = categoryName, blocktypes = {}}
                CategoryMap[categoryName] = category;
                table.insert(CategoryList, category);
            end
            table.insert(category.blocktypes, #(category.blocktypes) + 1, block_type);
        end
    end
    return CategoryList, CategoryMap;
end

BlockManager.StaticInit();
