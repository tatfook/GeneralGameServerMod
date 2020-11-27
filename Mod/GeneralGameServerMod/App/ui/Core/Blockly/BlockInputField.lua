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

BlockInputField:Property("Name", "BlockInputField");
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
    self.maxWidthUnitCount, self.maxHeightUnitCount = widthUnitCount or self.widthUnitCount, heightUnitCount or self.heightUnitCount;
    self.maxWidth, self.maxHeight = self.maxWidthUnitCount * UnitSize, self.maxHeightUnitCount * UnitSize;
end

function BlockInputField:UpdateWidthHeightUnitCount()
    return 0, 0, 0, 0;  -- 元素区域宽高,  元素真实宽高
end

function BlockInputField:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    if (self.widthUnitCount == widthUnitCount and self.heightUnitCount == heightUnitCount) then return end

    self.widthUnitCount, self.heightUnitCount = widthUnitCount, heightUnitCount;
    self.width, self.height = widthUnitCount * UnitSize, heightUnitCount * UnitSize;

    self:OnSizeChange();
end

function BlockInputField:GetMaxWidthHeightUnitCount()
    return self.maxWidthUnitCount, self.maxHeightUnitCount;
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

function BlockInputField:GetTextWidthUnitCount(text)
    return math.ceil(_guihelper.GetTextWidth(text or "", self:GetFont()) / self:GetUnitSize())
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

function BlockInputField:OnFocusOut()
end

function BlockInputField:OnFocusIn()
end

function BlockInputField:FocusIn()
    local blockly = self:GetBlock():GetBlockly();
    local focusUI = blockly:GetFocusUI();
    if (focusUI == self) then return end
    if (focusUI) then focusUI:OnFocusOut() end
    self:OnFocusIn();
end

function BlockInputField:ConnectionBlock(block)
    return ;
end

function BlockInputField:GetNextBlock()
    local block = self:GetBlock();
    local connection = block.nextConnection and block.nextConnection:GetConnection();
    return connection and connection:GetBlock();
end

function BlockInputField:GetLastNextBlock()
    local prevBlock, nextBlock = self:GetBlock(), self:GetNextBlock();
    while (nextBlock) do 
        prevBlock = nextBlock;
        nextBlock = prevBlock:GetNextBlock();
    end
    return prevBlock;
end

function BlockInputField:GetTopBlock()
    local prevBlock, nextBlock = self:GetPrevBlock(), self:GetBlock();
    while (prevBlock) do 
        nextBlock = prevBlock;
        prevBlock = nextBlock:GetPrevBlock();
    end
    return nextBlock;
end

function BlockInputField:GetPrevBlock()
    local block = self:GetBlock();
    local connection = block.previousConnection and block.previousConnection:GetConnection();
    return connection and connection:GetBlock();
end

function BlockInputField:GetEditorElement()
    return self:GetBlock():GetBlockly():GetEditorElement();
end

function BlockInputField:GetBlocklyElement()
    return self:GetBlock():GetBlockly();
end

function BlockInputField:Debug()
    GGS.DEBUG.Format("left = %s, top = %s, width = %s, height = %s, maxWidth = %s, maxHeight = %s, totalWidth = %s, totalHeight = %s", 
        self.leftUnitCount, self.topUnitCount, self.widthUnitCount, self.heightUnitCount, self.maxWidthUnitCount, self.maxHeightUnitCount, self.totalWidthUnitCount, self.totalHeightUnitCount);
end