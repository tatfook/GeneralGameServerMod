

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

local BlocklyCacheMap = {};

local function GetBlocklyElement(virtualEventParams, window)
    local windowName, blocklyId = window:GetWindowName(), virtualEventParams.blocklyId;
    local blockly = BlocklyCacheMap[windowName] and BlocklyCacheMap[windowName][blocklyId];
    if (not blockly) then
        blockly = window:ForEach(function(element)
            if (element:GetName() == "Blockly" and element:GetAttrStringValue("id") == blocklyId) then return element end
            return nil;
        end);
        BlocklyCacheMap[windowName] = BlocklyCacheMap[windowName] or {};
        BlocklyCacheMap[windowName][blocklyId] = blockly;
    end
    return blockly; 
end


function BlocklySimulator:ctor()
    self:RegisterSimulator();
end

function BlocklySimulator:HandlerVirtualEvent(virtualEventType, virtualEventParams, window)
    local blockly = GetBlocklyElement(virtualEventParams, window);
    if (not blockly) then return end
    if (virtualEventParams.action == "SetBlocklyOffset") then 
        blockly.offsetX, blockly.offsetY = virtualEventParams.newOffsetX, virtualEventParams.newOffsetY;
    end
end

function BlocklySimulator:SetBlockPosTrigger(blockly, params)
    local toolbox = blockly:GetToolBox();
    local blockType = params.blockType;
    toolbox:SetBlockPos(blockType);
    local startLeftUnitCount, startTopUnitCount = toolbox:GetBlockPos(blockType);
    if (not startLeftUnitCount) then return end
    local endLeftUnitCount, endTopUnitCount = params.leftUnitCount, params.topUnitCount;
    local UnitSize = blockly:GetUnitSize();
    local startX, startY = startLeftUnitCount * UnitSize, startTopUnitCount * UnitSize;
    local endX, endY = endLeftUnitCount * UnitSize - blockly.offsetX, endTopUnitCount * UnitSize - blockly.offsetY;
    local winX, winY = blockly:GetWindowPos();
    local startScreenX, startScreenY = blockly:WindowPointToScreenPoint(winX + startX, winY + startY);
    local endScreenX, endScreenY = blockly:WindowPointToScreenPoint(winX + endX, winY + endY);
    local offsetX, offsetY = 20, 16;
    return self:SetDragTrigger(startScreenX + offsetX, startScreenY + offsetY, endScreenX + offsetX, endScreenY + offsetY);
end

function BlocklySimulator:TriggerVirtualEvent(virtualEventType, virtualEventParams, window)
    local blockly = GetBlocklyElement(virtualEventParams, window);
    if (not blockly) then return end

    local action = virtualEventParams.action;
    if (action == "SetBlocklyOffset") then 
    elseif (action == "SetBlockPos") then
        return self:SetBlockPosTrigger(blockly, virtualEventParams);
    end
end

function BlocklySimulator:BeginPlay()
    BlocklyCacheMap = {};
end

BlocklySimulator:InitSingleton();
