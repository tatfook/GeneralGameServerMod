--[[
Title: Vue
Author(s): wxa
Date: 2020/6/30
Desc: Lua
use the lib:
-------------------------------------------------------
local VueBlocks = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Blocks/VueBlocks.lua");
-------------------------------------------------------
]]

local DataBlocks = NPL.load("./Data.lua", IsDevEnv);
local VarBlocks = NPL.load("./Var.lua", IsDevEnv);
local ControlBlocks = NPL.load("./Control.lua", IsDevEnv);
local EventBlocks = NPL.load("./Event.lua", IsDevEnv);
local LogBlocks = NPL.load("./Log.lua", IsDevEnv);
local HelperBlocks = NPL.load("./Helper.lua", IsDevEnv);

VueBlocks = NPL.export();

local AllBlocks = {};

local function AddToAllBlocks(blocks)
    for _, block in ipairs(blocks) do
        table.insert(AllBlocks, #AllBlocks + 1, block);
    end
end

AddToAllBlocks(DataBlocks);
AddToAllBlocks(VarBlocks);
AddToAllBlocks(ControlBlocks);
AddToAllBlocks(EventBlocks);
AddToAllBlocks(LogBlocks);
AddToAllBlocks(HelperBlocks);


function VueBlocks.GetAllBlocks()
    return AllBlocks;
end

function VueBlocks.GetToolBoxBlockList()
    local list = {};
    for _, block in ipairs(AllBlocks) do table.insert(list, #list + 1, block.type) end
    return list;
end