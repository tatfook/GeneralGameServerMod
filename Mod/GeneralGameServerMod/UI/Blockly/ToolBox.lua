--[[
Title: ToolBox
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local BlockInputField = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/BlockInputField.lua");
-------------------------------------------------------
]]

local Const = NPL.load("./Const.lua", IsDevEnv);
local Block = NPL.load("./Block.lua", IsDevEnv);
local LuaBlocks = NPL.load("./Blocks/Lua.lua", IsDevEnv);
local DataBlocks = NPL.load("./Blocks/Data.lua", IsDevEnv);
local VarBlocks = NPL.load("./Blocks/Var.lua", IsDevEnv);
local ControlBlocks = NPL.load("./Blocks/Control.lua", IsDevEnv);
local EventBlocks = NPL.load("./Blocks/Event.lua", IsDevEnv);
local LogBlocks = NPL.load("./Blocks/Log.lua", IsDevEnv);
local HelperBlocks = NPL.load("./Blocks/Helper.lua", IsDevEnv);
local ToolBox = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local UnitSize = Const.UnitSize;
local AllBlocks = {};
ToolBox:Property("Blockly");

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

function ToolBox:ctor()
    self.leftUnitCount, self.topUnitCount = 0, 0;
    self.widthUnitCount, self.heightUnitCount = 0, 0;
    self.width, self.height = 0, 0;
    self.offsetX, self.offsetY = 0, 0;
    self.blocks = {};
end

function ToolBox:Init(blockly)
    self:SetBlockly(blockly);

    -- local offsetX, offsetY = 5, 5;
    -- for index, blockOption in ipairs(AllBlocks) do
    --     local block = Block:new():Init(blockly, blockOption);
    --     block.isDragClone = true;
    --     local widthUnitCount, heightUnitCount = block:UpdateWidthHeightUnitCount();
    --     block:SetLeftTopUnitCount(offsetX, offsetY);
    --     block:UpdateLeftTopUnitCount();
    --     offsetY = offsetY + heightUnitCount + 5;
    --     if (not blockOption.hide_in_toolbox) then
    --         table.insert(self.blocks, block);
    --     end
    --     blockly:DefineBlock(blockOption);
    -- end

    return self;
end

function ToolBox:SetBlockList(blocklist)
    self.blocks = {};
    local offsetX, offsetY = 5, 5;
    for index, blockType in ipairs(blocklist) do
        local block = self:GetBlockly():GetBlockInstanceByType(blockType);
        if (block) then
            block.isDragClone = true;
            local widthUnitCount, heightUnitCount = block:UpdateWidthHeightUnitCount();
            block:SetLeftTopUnitCount(offsetX, offsetY);
            block:UpdateLeftTopUnitCount();
            offsetY = offsetY + heightUnitCount + 5;
            table.insert(self.blocks, block);
        end
    end
end

function ToolBox:Render(painter)
    local _, _, width, height = self:GetBlockly():GetContentGeometry();
    width = self.widthUnitCount * UnitSize;

    painter:SetPen("#ffffff");
    painter:DrawLine(width, 0, width, height);
    -- painter:DrawRect(0, 0, width, height);
    -- echo({self.widthUnitCount, self.heightUnitCount})

    painter:Save();
    painter:SetClipRegion(0, 0, width, height);
    painter:Translate(self.offsetX, self.offsetY);

    for _, block in ipairs(self.blocks) do
        block:Render(painter);
        painter:Flush();
    end

    painter:Translate(-self.offsetX, -self.offsetY);
    painter:Restore();
end

function ToolBox:GetMouseUI(x, y)
    if (x > self.widthUnitCount * UnitSize) then return nil end

    for _, block in ipairs(self.blocks) do
        ui = block:GetMouseUI(x, y, event);
        if (ui) then return ui:GetBlock() end
    end

    return self;
end

function ToolBox:OnMouseDown(event)
end

function ToolBox:OnMouseMove(event)
end

function ToolBox:OnMouseUp(event)
end

function ToolBox:OnMouseWheel(event)
    local delta = event:GetDelta();             -- 1 向上滚动  -1 向下滚动
    local dist, offset = 5, 5;                  -- 滚动距离为5 * UnitSize  

    if (#self.blocks == 0) then return end

    if (delta < 0) then
        local block = self.blocks[#self.blocks];
        if ((block.topUnitCount + block.heightUnitCount) <= (self.heightUnitCount - offset)) then return end  
    else
        local block = self.blocks[1];
        if (block.topUnitCount >= offset) then return end
    end
    for _, block in ipairs(self.blocks) do
        local left, top = block:GetLeftTopUnitCount();
        block:SetLeftTopUnitCount(left, top + dist * delta);
        block:UpdateLeftTopUnitCount();
    end
end

function ToolBox:OnFocusOut()
end

function ToolBox:OnFocusIn()
end

function ToolBox:FocusIn()
end

function ToolBox:FocusOut()
end

function ToolBox:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    self.widthUnitCount, self.heightUnitCount = Const.ToolBoxWidthUnitCount, heightUnitCount or self.heightUnitCount;
    self.width = self.widthUnitCount * UnitSize, self.heightUnitCount * UnitSize;
end

function ToolBox:IsContainPoint(x, y)
    return x < self.widthUnitCount * UnitSize;
end
