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

function Input:RenderContent(painter)
    local UnitSize = self:GetUnitSize();

    -- background
    painter:SetPen(self:GetBackgroundColor());
    painter:DrawRect(0, UnitSize, self.width, self.height - 2 * UnitSize);
    -- painter:DrawRect(0, 0, self.width, self.height);

    painter:SetPen(self:GetColor());
    painter:SetFont(self:GetFont());
    painter:DrawText(UnitSize, (self.contentHeight - self.singleLineTextHeight) / 2, self:GetValue());
    -- painter:DrawCircle(UnitSize * 4, UnitSize * 4, 0, UnitSize * 4, "z", true, nil, math.pi / 2, math.pi * 3 / 2);
    -- painter:DrawCircle(UnitSize * (4  + fieldWidthUnitCount), UnitSize * 4, 0, UnitSize * 4, "z", true, nil, math.pi * 3 / 2, math.pi * 5 / 2);
end

function Input:UpdateWidthHeightUnitCount()
    local width = _guihelper.GetTextWidth(self:GetValue() or "", self:GetFont());
    local widthUnitCount = math.max(6, math.ceil(width / self:GetUnitSize())) + 2;
    local heightUnitCount = self:GetDefaultHeightUnitCount();
    self:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount);
    return widthUnitCount, heightUnitCount;
end