--[[
Title: Label
Author(s): wxa
Date: 2020/6/30
Desc: 标签字段
use the lib:
-------------------------------------------------------
local Label = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Label.lua");
-------------------------------------------------------
]]

local Field = NPL.load("./Field.lua", IsDevEnv);
local Label = commonlib.inherit(Field, NPL.export());

Label:Property("Color", "#ffffff");

function Label:Init(block, value)
    Label._super.Init(self, block);

    self:SetValue(value);

    return self;
end

function Label:Render(painter)
    Label._super.Render(self, painter);

    painter:SetPen(self:GetColor());
    painter:SetFont(self:GetFont());
    painter:DrawText(0, (self.height - self:GetSingleLineTextHeight()) / 2, self:GetValue());
end

function Label:UpdateLayout()
    local defaultFieldHeightUnitCount = self:GetDefaultHeightUnitCount();
    local UnitSize = self:GetUnitSize();
    local value, font = self:GetValue(), self:GetFont();
    local valueWidth = _guihelper.GetTextWidth(value or "", font);
    local valueWidthUnitCount = math.ceil(valueWidth / UnitSize);
    local SpaceUnitCount = self:GetBlock():GetSpaceUnitCount();
    return valueWidthUnitCount + SpaceUnitCount, defaultFieldHeightUnitCount;
end
