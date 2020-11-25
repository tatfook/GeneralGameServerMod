--[[
Title: InputField
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local InputField = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/InputField.lua");
-------------------------------------------------------
]]


local InputField = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

InputField:Property("Block");
InputField:Property("Type");                     -- label text, value
InputField:Property("Color");                    -- 颜色

function InputField:ctor()
    self.leftUnitCount, self.topUnitCount, self.widthUnitCount, self.heightUnitCount = 0, 0, 0, 0;
    self.left, self.top, self.width, self.height = 0, 0, 0, 0;
end

function InputField:Init(block)
    self:SetBlock(block);
    return self;
end

function InputField:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    local UnitSize = self:GetUnitSize();
    self.widthUnitCount, self.heightUnitCount = widthUnitCount, heightUnitCount;
    self.width, self.height = widthUnitCount * UnitSize, heightUnitCount * UnitSize;
end

function InputField:GetWidthHeightUnitCount()
    return self.widthUnitCount, self.heightUnitCount;
end

function InputField:SetLeftTopUnitCount(leftUnitCount, topUnitCount)
    local UnitSize = self:GetUnitSize();
    self.leftUnitCount, self.topUnitCount = leftUnitCount, topUnitCount;
    self.left, self.top = leftUnitCount * UnitSize, topUnitCount * UnitSize;
end

function InputField:GetLeftTopUnitCount()
    return self.leftUnitCount, self.topUnitCount;
end

function InputField:GetSingleLineTextHeight()
    return self:GetFontSize() * 6 / 5;
end

function InputField:GetLineHeightUnitCount()
    return self:GetBlock():GetLineHeightUnitCount();
end

function InputField:GetUnitSize()
    return self:GetBlock():GetUnitSize();
end

function InputField:GetFontSize()
    return (self:GetLineHeightUnitCount() - 4) * self:GetUnitSize();
end

function InputField:GetFont()
    return string.format("System;%s", self:GetFontSize());
end

function InputField:Render()
end

function InputField:UpdateLayout()
end

function InputField:OnMouseDown(event)
    self:GetBlock():OnMouseDown(event);
end

function InputField:OnMouseMove(event)
    self:GetBlock():OnMouseMove(event);
end

function InputField:OnMouseUp(event)
    self:GetBlock():OnMouseUp(event);
end

function InputField:GetMouseUI(x, y)
    if (x < self.left or x > (self.left + self.width) or y < self.top or y > (self.top + self.height)) then return end
    return self;
end

function InputField:ConnectionBlock(block)
    return ;
end
