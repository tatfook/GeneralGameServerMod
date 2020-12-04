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
local ToolBox = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local UnitSize = Const.UnitSize;

ToolBox:Property("Blockly");
-- ToolBox:Property("");

function ToolBox:ctor()
    self.leftUnitCount, self.topUnitCount = 0, 0;
    self.widthUnitCount, self.heightUnitCount = 0, 0;
    self.offsetX, self.offsetY = 0, 0;
    self.blocks = {};
end

function ToolBox:Init(blockly)
    self:SetBlockly(blockly);

    local offsetX, offsetY = 5, 5;
    for index, blockOption in ipairs(LuaBlocks) do
        local block = Block:new():Init(blockly, blockOption);
        block.isDragClone = true;
        local widthUnitCount, heightUnitCount = block:UpdateWidthHeightUnitCount();
        block:SetLeftTopUnitCount(offsetX, offsetY);
        block:UpdateLeftTopUnitCount();
        offsetY = offsetY + heightUnitCount + 5;
        table.insert(self.blocks, block);
    end

    return self;
end

function ToolBox:Render(painter)
    local _, _, width, height = self:GetBlockly():GetContentGeometry();
    width = self.widthUnitCount * UnitSize;

    painter:SetPen("#ffffff");
    painter:DrawLine(width, 0, width, height);
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
end



