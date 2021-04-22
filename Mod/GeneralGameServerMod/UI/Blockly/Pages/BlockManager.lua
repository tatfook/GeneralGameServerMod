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

local AllCategoryMap, AllBlockMap = {}, {};

local BlockManager = NPL.export();

local inited = false;
local Directory = nil; 
local FileName = nil; 

function BlockManager.LoadCategoryAndBlock()
    local io = ParaIO.open(FileName, "r");
    if(not io:IsValid()) then return nil end 
    local text = io:GetText();
    io:close();
    return NPL.LoadTableFromString(text);
end

function BlockManager.SaveCategoryAndBlock()
    local text = commonlib.serialize_compact({AllBlockMap = AllBlockMap, AllCategoryMap = AllCategoryMap});
    local io = ParaIO.open(FileName, "w");
	io:WriteString(text);
    io:close();
end

function BlockManager.NewBlock(block)
    if (not block.type) then return end
    AllBlockMap[block.type] = block;
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

function BlockManager.StaticInit()
    if (inited) then return BlockManager end
    inited = true;

    Directory = CommonLib.ToCanonicalFilePath(ParaIO.GetCurDirectory(0) .. ParaWorld.GetWorldDirectory() .. "/blockly/");
    FileName = CommonLib.ToCanonicalFilePath(Directory .. "/category_block.config");

    -- 确保目存在
    ParaIO.CreateDirectory(directory);

    --加载数据
    local AllCategoryBlock = BlockManager.LoadCategoryAndBlock();
    AllCategoryMap = AllCategoryBlock and AllCategoryBlock.AllCategoryMap or {};
    AllBlockMap = AllCategoryBlock and AllCategoryBlock.AllBlockMap or {};

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
    local code = string.gsub(code_description, "%$(%w+)", args);
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
