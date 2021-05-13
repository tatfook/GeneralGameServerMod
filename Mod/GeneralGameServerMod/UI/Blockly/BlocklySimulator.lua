

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

NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/Macros.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayer.lua");
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros");

local Simulator = NPL.load("../Window/Event/Simulator.lua");
local Const = NPL.load("./Const.lua");

local BlocklySimulator = commonlib.inherit(Simulator, NPL.export());
BlocklySimulator:Property("SimulatorName", "BlocklySimulator");

local BlocklyCacheMap = {};
local BlockOffsetX, BlockOffsetY = 20, 16;
local InputValueOffsetX, InputValueOffsetY = 16, 12;

local function GetBlocklyElement(virtualEventParams, window)
    local windowName, blocklyId = window:GetWindowName(), virtualEventParams.blocklyId;
    local blockly = BlocklyCacheMap[windowName] and BlocklyCacheMap[windowName][blocklyId];
    if (not blockly) then
        blockly = window:ForEach(function(element)
            if (element:GetName() == "Blockly" and (not blocklyId or element:GetAttrStringValue("id") == blocklyId)) then return element end
            return nil;
        end);
        BlocklyCacheMap[windowName] = BlocklyCacheMap[windowName] or {};
        BlocklyCacheMap[windowName][blocklyId or ""] = blockly;
    end
    return blockly; 
end

function BlocklySimulator:ctor()
    self:RegisterSimulator();
end

function BlocklySimulator:SetBlockPos(blockly, params)
    local blockType = params.blockType;
    local block = blockly:GetBlockInstanceByType(blockType);
    if (not block) then return end
    block:SetLeftTopUnitCount(params.leftUnitCount, params.topUnitCount);
    block:UpdateLayout();
    if (not block:TryConnectionBlock()) then
        blockly:AddBlock(block);
    end
end

function BlocklySimulator:SetToolBoxCategory(blockly, params)
    local toolbox = blockly:GetToolBox();
    toolbox:SwitchCategory(params.newCategoryName);    
end

function BlocklySimulator:SetInputValue(blockly, params)
    local UnitSize = blockly:GetUnitSize();
    local winX, winY = blockly:GetWindowPos();
    local x, y = params.leftUnitCount * UnitSize + InputValueOffsetX, params.topUnitCount * UnitSize + InputValueOffsetY;
    local ui = blockly:GetXYUI(x, y);
    if (not ui) then return end
    ui:SetValue(params.value);
    ui:SetLabel(params.label);
    ui:GetTopBlock():UpdateLayout();
end

function BlocklySimulator:HandlerVirtualEvent(virtualEventType, virtualEventParams, window)
    local blockly = GetBlocklyElement(virtualEventParams, window);
    if (not blockly) then return end
    local action = virtualEventParams.action;
    if (action == "SetBlocklyOffset") then 
        blockly.offsetX, blockly.offsetY = virtualEventParams.newOffsetX, virtualEventParams.newOffsetY;
    elseif (action == "SetBlockPos") then
        self:SetBlockPos(blockly, virtualEventParams);
    elseif (action == "SetToolBoxCategory") then
        self:SetToolBoxCategory(blockly, virtualEventParams);
    elseif (action == "SetInputValue") then
        self:SetInputValue(blockly, virtualEventParams);
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
    local endX, endY = endLeftUnitCount * UnitSize + blockly.offsetX, endTopUnitCount * UnitSize + blockly.offsetY;
    local winX, winY = blockly:GetWindowPos();
    local startScreenX, startScreenY = blockly:WindowPointToScreenPoint(winX + startX, winY + startY);
    local endScreenX, endScreenY = blockly:WindowPointToScreenPoint(winX + endX, winY + endY);
    return self:SetDragTrigger(startScreenX + BlockOffsetX, startScreenY + BlockOffsetY, endScreenX + BlockOffsetX, endScreenY + BlockOffsetY);
end

function BlocklySimulator:SetToolBoxCategoryTrigger(blockly, params)
    local winX, winY = blockly:GetWindowPos();
    local toolbox = blockly:GetToolBox();
    local categoryList = toolbox:GetCategoryList();
    for i, category in ipairs(categoryList) do
        if (category.name == params.newCategoryName) then
            local x, y = math.floor(Const.ToolBoxCategoryWidth / 2), (i - 1) * Const.ToolBoxCategoryHeight + 20;
            x, y = blockly:WindowPointToScreenPoint(winX + x, winY + y);
            return self:SetClickTrigger(x, y);
        end
    end
end

function BlocklySimulator:SetInputValueTrigger(blockly, params)
    local UnitSize = blockly:GetUnitSize();
    local ui = blockly:GetXYUI(params.leftUnitCount * UnitSize + InputValueOffsetX, params.topUnitCount * UnitSize + InputValueOffsetY);
    if (true or ui:GetFieldEditType() == "input") then
        local callback = {};
        local text = params.label;
        local index, size = 1, ParaMisc.GetUnicodeCharNum(text);
        local function ExecTrigger()
            local char = ParaMisc.UniSubString(text, index, index);
            local buttons = Macros.TextToKeyName(char);
            MacroPlayer.SetKeyPressTrigger(buttons or char, text, function()
                if (ui) then
                    local label = ParaMisc.UniSubString(text, 1, index);
                    ui:SetLabel(label);
                    ui:GetTopBlock():UpdateLayout();
                end

                index = index + 1;
                if (index <= size) then
                    return ExecTrigger();
                end
                if(callback.OnFinish) then 
                    callback.OnFinish();
                end
            end);
        end
        
        local UnitSize = blockly:GetUnitSize();
        local winX, winY = blockly:GetWindowPos();
        local x, y = params.leftUnitCount * UnitSize + blockly.offsetX, params.topUnitCount * UnitSize + blockly.offsetY;
        x, y = blockly:WindowPointToScreenPoint(winX + x, winY + y);
        MacroPlayer.SetClickTrigger(x + InputValueOffsetX, y + InputValueOffsetY, "left", function()
            -- if (ui) then ui:OnFocusIn() end
            ExecTrigger();
            -- if (ui) then ui:OnFocusOut() end
        end);
        return callback;
    else
        Macros.Text(string.format("点击字段, 自动填写字段值: %s", params.label));
        local UnitSize = blockly:GetUnitSize();
        local winX, winY = blockly:GetWindowPos();
        local x, y = params.leftUnitCount * UnitSize + blockly.offsetX, params.topUnitCount * UnitSize + blockly.offsetY;
        x, y = blockly:WindowPointToScreenPoint(winX + x, winY + y);
        return self:SetClickTrigger(x + InputValueOffsetX, y + InputValueOffsetY, nil, function() 
            Macros.Text(nil);
        end);
    end
end

function BlocklySimulator:TriggerVirtualEvent(virtualEventType, virtualEventParams, window)
    local blockly = GetBlocklyElement(virtualEventParams, window);
    if (not blockly) then return end

    local action = virtualEventParams.action;
    if (action == "SetBlocklyOffset") then 
    elseif (action == "SetBlockPos") then
        return self:SetBlockPosTrigger(blockly, virtualEventParams);
    elseif (action == "SetToolBoxCategory") then
        return self:SetToolBoxCategoryTrigger(blockly, virtualEventParams);
    elseif (action == "SetInputValue") then
        return self:SetInputValueTrigger(blockly, virtualEventParams);
    end
end

function BlocklySimulator:BeginPlay()
    BlocklyCacheMap = {};
end

BlocklySimulator:InitSingleton();
