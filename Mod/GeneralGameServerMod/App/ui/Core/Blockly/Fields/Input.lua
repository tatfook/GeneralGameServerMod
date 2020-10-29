--[[
Title: Label
Author(s): wxa
Date: 2020/6/30
Desc: 输入字段
use the lib:
-------------------------------------------------------
local Label = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Label.lua");
-------------------------------------------------------
]]

local Field = NPL.load("./Field.lua", IsDevEnv);
local Input = commonlib.inherit(Field, NPL.export());

Input:Property("Name", "");
Input:Property("Color", "#000000");
Input:Property("BackgroundColor", "#ffffff");
Input:Property("Value", "");
Input:Property("Type", "text");
-- Input:Property("")

function Input:Init(block, opt)
    Input._super.Init(self, block);

    local value = "";
    if (type(opt.text) == "function") then value = opt.text() 
    elseif (type(opt.text) == "string") then value = opt.text 
    else  end

    self:SetValue(value);
    self:SetName(opt.name);

    return self;
end

function Input:Render(painter)
    Input._super.Render(self, painter);
    local UnitSize = self:GetUnitSize();
    local SpaceUnitCount = self:GetBlock():GetSpaceUnitCount();

    local offsetY = (self.heightUnitCount - self:GetDefaultHeightUnitCount()) / 2 * UnitSize;
    painter:Translate(0, offsetY);

    painter:SetPen(self:GetBackgroundColor());
    painter:DrawRect(0, UnitSize / 2, self.width - SpaceUnitCount * UnitSize, self.height - UnitSize);

    painter:Translate(UnitSize, 0);
    painter:SetPen(self:GetColor());
    painter:SetFont(self:GetFont());
    painter:DrawText(0, (self:GetDefaultHeightUnitCount() * UnitSize - self:GetSingleLineTextHeight()) / 2, self:GetValue());
    -- painter:DrawCircle(UnitSize * 4, UnitSize * 4, 0, UnitSize * 4, "z", true, nil, math.pi / 2, math.pi * 3 / 2);
    -- painter:DrawCircle(UnitSize * (4  + fieldWidthUnitCount), UnitSize * 4, 0, UnitSize * 4, "z", true, nil, math.pi * 3 / 2, math.pi * 5 / 2);
    painter:Translate(-UnitSize, 0);

    painter:Translate(0, -offsetY);
end

function Input:UpdateLayout()
    local defaultFieldHeightUnitCount = self:GetDefaultHeightUnitCount();
    local UnitSize = self:GetUnitSize();
    local value, font = self:GetValue(), self:GetFont();
    local valueWidth = _guihelper.GetTextWidth(value or "", font);
    local valueWidthUnitCount = math.max(4, math.ceil(valueWidth / UnitSize)) + 2;
    local SpaceUnitCount = self:GetBlock():GetSpaceUnitCount();
    return valueWidthUnitCount + SpaceUnitCount, defaultFieldHeightUnitCount;
end