

--[[
Title: BlocklySimulator
Author(s): wxa
Date: 2020/6/30
Desc: BlocklySimulator
use the lib:
-------------------------------------------------------
local BlocklySimulator = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/BlocklySimulator.lua");
-------------------------------------------------------
]]

local Simulator = NPL.load("../Window/Event/Simulator.lua");
local BlocklySimulator = commonlib.inherit(Simulator, NPL.export());
BlocklySimulator:Property("SimulatorName", "BlocklySimulator");

function BlocklySimulator:ctor()
    self:RegisterSimulator();
end

function BlocklySimulator:TriggerVirtualEvent(virtualEventType, virtualEventParams, window)
    if (virtualEventType ~= "Blockly_NewBlock") then return end
    
    local blockly = window:ForEach(function(element)
        if (element:GetName() == "Blockly") then return element end
    end);
    
    if (blockly) then
        blockly.toolbox:SetBlockPos(virtualEventParams.block_type, virtualEventParams.block_top);
    end
end

BlocklySimulator:InitSingleton();
