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

function BlockManager.SaveBlock(block)
    if (not block.type) then return end
    AllBlockMap[block.type] = block;
    BlockManager.SaveCategoryAndBlock();
end

function BlockManager.GetAllCategoryMap()
    return AllCategoryMap;
end

function BlockManager.GetAllBlockMap()
    return AllBlockMap;
end

function BlockManager.StaticInit()
    if (inited) then return end
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

-- BlockManager.StaticInit();
