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

local DataBlocks = NPL.load("./Data.lua", IsDevEnv);
local MathBlocks = NPL.load("./Math.lua", IsDevEnv);
local VarBlocks = NPL.load("./Var.lua", IsDevEnv);
local ControlBlocks = NPL.load("./Control.lua", IsDevEnv);
local EventBlocks = NPL.load("./Event.lua", IsDevEnv);
local LogBlocks = NPL.load("./Log.lua", IsDevEnv);
local HelperBlocks = NPL.load("./Helper.lua", IsDevEnv);

Blocks = NPL.export();

local AllBlocks = {};

local function AddToAllBlocks(blocks)
    for _, block in ipairs(blocks) do
        table.insert(AllBlocks, #AllBlocks + 1, block);
    end
end

AddToAllBlocks(DataBlocks);
AddToAllBlocks(MathBlocks);
AddToAllBlocks(VarBlocks);
AddToAllBlocks(ControlBlocks);
AddToAllBlocks(EventBlocks);
AddToAllBlocks(LogBlocks);
AddToAllBlocks(HelperBlocks);


function Blocks.GetAllBlocks()
    return AllBlocks;
end

function Blocks.GetToolBoxBlockList()
    local list = {};
    for _, block in ipairs(AllBlocks) do table.insert(list, #list + 1, block.type) end
    return list;
end