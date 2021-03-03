--[[
Title: NplToolbox
Author(s): wxa
Date: 2021/3/1
Desc: Lua
use the lib:
-------------------------------------------------------
local NplToolbox = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Blocks/NplToolbox.lua");
-------------------------------------------------------
]]

local ParacraftCodeBlockly = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlocklyDef/ParacraftCodeBlockly.lua");

local NplToolbox = NPL.export();

local CategoryList = {};  -- 分类列表
local CategoryMap = {};   -- 分类MAP
local AllBlocks = {};     -- 所有块列表

local all_cmds = ParacraftCodeBlockly.GetAllCmds();
local all_categories = ParacraftCodeBlockly.GetCategoryButtons();

for index, category in ipairs(all_categories) do
    table.insert(CategoryList, index, {
        name = category.name,
        text = category.text,
        color = category.colour,
        blocktypes = {},
    });
    CategoryMap[CategoryList[index].name] = CategoryList[index];
end

for _, cmd in ipairs(all_cmds) do
    local category = CategoryMap[cmd.category];

    local block = {
        color = category.color;
        category = cmd.category;
        -- message = message,
        -- arg = arg,
        previousStatement = cmd.previousStatement and true or false,
	    nextStatement = cmd.nextStatement and true or false,
        output = cmd.output and true or false,
        type = cmd.type,
        ToNPL = cmd.ToNPL,
        hideInToolbox = cmd.hide_in_toolbox,
    } 

    local message, arg = "", {};
    for i = 0, 10 do
        local messageName = "message" .. tostring(i);
        local argName = "arg" .. tostring(i);
        if (not cmd[messageName]) then break end
        block[messageName] = cmd[messageName];
        block[argName] = commonlib.deepcopy(cmd[argName]);
        -- message = message .. " " .. cmd[messageName];
        -- local cmd_arg = cmd[argName];
        -- if (type(cmd_arg) == "table") then
        --     for _, cmd_arg_item in ipairs(cmd_arg) do table.insert(arg, #arg + 1, cmd_arg_item) end 
        -- end
    end

    if (not block.hideInToolbox) then
        table.insert(category.blocktypes, #(category.blocktypes) + 1, block.type);
    end
    table.insert(AllBlocks, #AllBlocks + 1, block);
end

function NplToolbox.GetAllBlocks()
    return AllBlocks;
end

function NplToolbox.GetCategoryList()
    return CategoryList;
end

