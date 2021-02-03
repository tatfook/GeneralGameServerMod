--[[
Title: Vue
Author(s): wxa
Date: 2020/6/30
Desc: Lua
use the lib:
-------------------------------------------------------
local Blocks = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Blocks/Blocks.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");

local DataBlocks = NPL.load("./Data.lua", IsDevEnv);
local MathBlocks = NPL.load("./Math.lua", IsDevEnv);
local VarBlocks = NPL.load("./Var.lua", IsDevEnv);
local ControlBlocks = NPL.load("./Control.lua", IsDevEnv);
local EventBlocks = NPL.load("./Event.lua", IsDevEnv);
local LogBlocks = NPL.load("./Log.lua", IsDevEnv);
local HelperBlocks = NPL.load("./Helper.lua", IsDevEnv);

local Toolbox = NPL.export();

local AllBlocks = {};
local CategoryList = {
    {
        name = "数据",
        color = StyleColor.ConvertTo16("rgb(0,120,215)"),
        blocktypes = {}
    },
    {
        name = "运算",
        color = StyleColor.ConvertTo16("rgb(122,187,85)"),
        blocktypes = {}
    },
    {
        name = "控制",
        color = StyleColor.ConvertTo16("rgb(118,75,204)"),
        blocktypes = {}
    },
    {
        name = "事件",
        color = StyleColor.ConvertTo16("rgb(216,59,1)"),
        blocktypes = {}
    },
    {
        name = "辅助",
        color = StyleColor.ConvertTo16("rgb(143,109,64)"),
        blocktypes = {}
    },
}
local CategoryMap = {};

for _, category in ipairs(CategoryList) do
    CategoryMap[category.name] = category;
end

local function AddToAllBlocks(blocks, categoryName)
    local category = CategoryMap[categoryName];

    for _, block in ipairs(blocks) do
        if (category) then
            block.color = category.color;
            block.category = categoryName;
            -- block.color = block.color or category.color;
            table.insert(category.blocktypes, #(category.blocktypes) + 1, block.type);
        end

        table.insert(AllBlocks, #AllBlocks + 1, block);
    end
end

AddToAllBlocks(VarBlocks, "数据");
AddToAllBlocks(DataBlocks, "数据");
AddToAllBlocks(MathBlocks, "运算");
AddToAllBlocks(ControlBlocks, "控制");
AddToAllBlocks(EventBlocks, "事件");
AddToAllBlocks(LogBlocks, "辅助");
AddToAllBlocks(HelperBlocks, "辅助");

function Toolbox.GetAllBlocks()
    return AllBlocks;
end

function Toolbox.GetCategoryList()
    return CategoryList;
end

