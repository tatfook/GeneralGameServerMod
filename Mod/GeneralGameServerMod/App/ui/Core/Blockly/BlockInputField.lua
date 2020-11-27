--[[
Title: InputField
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local BlockInputField = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/BlockInputField.lua");
-------------------------------------------------------
]]

local Const = NPL.load("./Const.lua", IsDevEnv);
local BlockInputField = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local UnitSize = Const.UnitSize;

BlockInputField:Property("Block");
BlockInputField:Property("Option");
BlockInputField:Property("Color");                    -- 颜色

function BlockInputField:ctor()
    self.leftUnitCount, self.topUnitCount, self.widthUnitCount, self.heightUnitCount = 0, 0, 0, 0;
    self.left, self.top, self.width, self.height = 0, 0, 0, 0;
    self.maxWidthUnitCount, self.maxHeightUnitCount, self.maxWidth, self.maxHeight = 0, 0, 0, 0;
    self.totalWidthUnitCount, self.totalHeightUnitCount, self.totalWidth, self.totalHeight = 0, 0, 0, 0;
end

function BlockInputField:Init(block, option)
    option = option or {};

    self:SetBlock(block);
    self:SetOption(option or {});

    -- 解析颜色值
    self:SetColor(option.color);

    return self;
end

function BlockInputField:SetTotalWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    self.totalWidthUnitCount, self.totalHeightUnitCount = widthUnitCount, heightUnitCount;
    self.totalWidth, self.totalHeight = widthUnitCount * UnitSize, heightUnitCount * UnitSize;

end

function BlockInputField:GetTotalWidthHeightUnitCount()
    return self.totalWidthUnitCount, self.totalHeightUnitCount;
end

function BlockInputField:SetMaxWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    self.maxWidthUnitCount, self.maxHeightUnitCount = widthUnitCount, heightUnitCount;
    self.maxWidth, self.maxHeight = widthUnitCount * UnitSize, heightUnitCount * UnitSize;
end


function BlockInputField:UpdateWidthHeightUnitCount()
    return 0, 0;
end

function BlockInputField:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    if (self.widthUnitCount == widthUnitCount and self.heightUnitCount == heightUnitCount) then return end

    self.widthUnitCount, self.heightUnitCount = widthUnitCount, heightUnitCount;
    self.width, self.height = widthUnitCount * UnitSize, heightUnitCount * UnitSize;

    self:OnSizeChange();
end

function BlockInputField:GetMaxWidthHeightUnitCount()
    return self.maxHeightUnitCount, self.maxHeightUnitCount;
end

function BlockInputField:GetWidthHeightUnitCount()
    return self.widthUnitCount, self.heightUnitCount;
end

function BlockInputField:UpdateLeftTopUnitCount()
end

function BlockInputField:SetLeftTopUnitCount(leftUnitCount, topUnitCount)
    if (self.leftUnitCount == leftUnitCount and self.topUnitCount == topUnitCount) then return end

    self.leftUnitCount, self.topUnitCount = leftUnitCount, topUnitCount;
    self.left, self.top = leftUnitCount * UnitSize, topUnitCount * UnitSize;
    
    self:OnSizeChange();
end

function BlockInputField:GetLeftTopUnitCount()
    return self.leftUnitCount, self.topUnitCount;
end

function BlockInputField:GetAbsoluteLeftTopUnitCount()
    if (self == self:GetBlock()) then return self:GetLeftTopUnitCount() end
    local blockLeftUnitCount, blockTopUnitCount = self:GetBlock():GetLeftTopUnitCount();
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    return blockLeftUnitCount + leftUnitCount, blockTopUnitCount + topUnitCount;
end

function BlockInputField:OnSizeChange()
end

function BlockInputField:GetSingleLineTextHeight()
    return self:GetFontSize() * 6 / 5;
end

function BlockInputField:GetSpaceUnitCount() 
    return Const.SpaceUnitCount;
end

function BlockInputField:GetLineHeightUnitCount()
    return Const.LineHeightUnitCount;
end

function BlockInputField:GetUnitSize()
    return Const.UnitSize;
end

function BlockInputField:GetFontSize()
    return (self:GetLineHeightUnitCount() - 4) * self:GetUnitSize();
end

function BlockInputField:GetFont()
    return string.format("System;%s", self:GetFontSize());
end

function BlockInputField:RenderContent(painter)
end
function BlockInputField:Render(painter)
    painter:SetPen(self:GetBlock():GetColor());
    painter:DrawRect(self.left, self.top, self.maxWidth, self.maxHeight);

    local offsetX, offsetY = self.left + (self.maxWidth - self.width) / 2, self.top + (self.maxHeight - self.height) / 2;
    painter:SetPen(self:GetColor());
    painter:Translate(offsetX, offsetY);
    self:RenderContent(painter);
    painter:Translate(-offsetX, -offsetY);
end


function BlockInputField:UpdateLayout()
end

function BlockInputField:OnMouseDown(event)
    self:GetBlock():OnMouseDown(event);
end

function BlockInputField:OnMouseMove(event)
    self:GetBlock():OnMouseMove(event);
end

function BlockInputField:OnMouseUp(event)
    self:GetBlock():OnMouseUp(event);
end

function BlockInputField:GetMouseUI(x, y)
    if (x < self.left or x > (self.left + self.width) or y < self.top or y > (self.top + self.height)) then return end
    return self;
end

function BlockInputField:ConnectionBlock(block)
    return ;
end

function BlockInputField:GetNextBlock()
    local connection = self.nextConnection and self.nextConnection:GetConnection();
    return connection and connection:GetBlock();
end

function BlockInputField:GetLastNextBlock()
    local prevBlock, nextBlock = self, self:GetNextBlock();
    while (nextBlock) do 
        prevBlock = nextBlock;
        nextBlock = prevBlock:GetNextBlock();
    end
    return prevBlock;
end

function BlockInputField:GetTopBlock()
    local prevBlock, nextBlock = self:GetPrevBlock(), self;
    while (prevBlock) do 
        nextBlock = prevBlock;
        prevBlock = nextBlock:GetPrevBlock();
    end
    return nextBlock;
end

function BlockInputField:GetPrevBlock()
    local connection = self.previousConnection and self.previousConnection:GetConnection();
    return connection and connection:GetBlock();
end

