--[[
Title: Field
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Field = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Field.lua");
-------------------------------------------------------
]]

local Field = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Field:Property("Block");
Field:Property("Type");                     -- label text, value
Field:Property("Value");                    -- 值

function Field:ctor()
    self.leftUnitCount, self.topUnitCount, self.widthUnitCount, self.heightUnitCount = 0, 0, 0, 0;
end

function Field:Init(block)
    self:SetBlock(block);
    return self;
end

function Field:GetUnitSize()
    return self:GetBlock():GetUnitSize();
end

function Field:GetDefaultHeightUnitCount()
    return 8;
end

function Field:GetDefaultWidthUnitCount()
    return self:GetDefaultHeightUnitCount() * 2;
end

function Field:GetFontSize()
    return math.floor(self:GetUnitSize() * self:GetDefaultHeightUnitCount() * 4 / 7);  -- 1.4 * fontSize = lineHiehgt
end

function Field:GetFont()
    return string.format("System;%s", self:GetFontSize());
end

function Field:Render(painter)
    local SpaceUnitCount = self:GetBlock():GetSpaceUnitCount();
    local UnitSize = self:GetUnitSize();
    painter:Translate(-SpaceUnitCount * UnitSize, 0);
    painter:SetPen(self:GetBlock():GetColor());
    painter:DrawRect(0, 0, self.width + SpaceUnitCount * UnitSize, self.height);
    painter:Translate(SpaceUnitCount * UnitSize, 0);
end

function Field:UpdateLayout()
    return 0, 0;
end

function Field:GetSingleLineTextHeight()
    return self:GetFontSize() * 6 / 5;
end

function Field:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    local UnitSize = self:GetUnitSize();
    self.widthUnitCount, self.heightUnitCount = widthUnitCount, heightUnitCount;
    self.width, self.height = widthUnitCount * UnitSize, heightUnitCount * UnitSize;
end

function Field:SetLeftTopUnitCount(leftUnitCount, topUnitCount)
    local UnitSize = self:GetUnitSize();
    self.leftUnitCount, self.topUnitCount = leftUnitCount, topUnitCount;
    self.left, self.top = leftUnitCount * UnitSize, topUnitCount * UnitSize;
end