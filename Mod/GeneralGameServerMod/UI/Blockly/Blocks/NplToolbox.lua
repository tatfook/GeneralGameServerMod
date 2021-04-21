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

NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpWindow.lua");
local CodeHelpWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpWindow");

local NplToolbox = NPL.export();

local all_blocks_cache = {};
local all_block_map_cache = {};
local all_category_list_cache = {};
local all_category_map_cache = {};

local function GetAllBlocksAndCategoryList(all_cmds, all_categories)
    if (all_blocks_cache[all_cmds]) then return all_blocks_cache[all_cmds], all_category_list_cache[all_categories], all_block_map_cache[all_cmds], all_category_map_cache[all_categories] end

    local CategoryList = {};  -- 分类列表
    local CategoryMap = {};   -- 分类MAP
    local AllBlocks = {};     -- 所有块列表
    local AllBlockMap = {};

    for index, category in ipairs(all_categories) do
        table.insert(CategoryList, index, {
            name = category.name,
            text = category.text,
            color = category.colour,
            blocktypes = {},
        });
        CategoryMap[CategoryList[index].name] = CategoryList[index];
    end
    
    local cmd_count = #all_cmds;
    for i = 1, cmd_count do
        local cmd = all_cmds[i];
        local category = CategoryMap[cmd.category];
        -- if (not cmd.func_description) then echo(cmd) end
        local func_description = string.gsub(cmd.func_description or "", "\\n", "\n");
        func_description = string.gsub(func_description, "%%d", "%%s");
        local block = {
            color = category.color;
            category = cmd.category;
            -- message = message,
            -- arg = arg,
            previousStatement = cmd.previousStatement and true or false,
            nextStatement = cmd.nextStatement and true or false,
            output = cmd.output and true or false,
            type = cmd.type,
            ToNPL = function(block)
                if (not cmd.func_description) then return cmd.ToNPL(block) end

                local args = {};
                for i, opt in ipairs(block.inputFieldOptionList) do
                    if (opt.type ~= "input_dummy") then
                        args[i] = block:GetValueAsString(opt.name) or "";
                    end
                end
                return string.format(func_description, table.unpack(args));
            end,
            hideInToolbox = cmd.hide_in_toolbox,
        } 
        if (block.previousStatement or block.nextStatement) then func_description = func_description .. "\n" end 

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
        AllBlockMap[block.type] = block;
    end

    all_blocks_cache[all_cmds], all_category_list_cache[all_categories] = AllBlocks, CategoryList;
    all_block_map_cache[all_cmds], all_category_map_cache[all_categories] = AllBlockMap, CategoryMap;
    return AllBlocks, CategoryList, AllBlockMap, CategoryMap;
end

function NplToolbox.GetAllBlocks()
    local AllBlocks, CategoryList, AllBlockMap, AllCategoryMap = GetAllBlocksAndCategoryList(CodeHelpWindow.GetAllCmds(), CodeHelpWindow.GetCategoryButtons());
    return AllBlocks, AllBlockMap;
end

function NplToolbox.GetCategoryList()
    local AllBlocks, CategoryList, AllBlockMap, AllCategoryMap = GetAllBlocksAndCategoryList(CodeHelpWindow.GetAllCmds(), CodeHelpWindow.GetCategoryButtons());
    return CategoryList, AllCategoryMap;
end

