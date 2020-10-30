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

function Label:RenderContent(painter)
    painter:SetPen(self:GetColor());
    painter:SetFont(self:GetFont());
    painter:DrawText(0, (self.contentHeight - self.singleLineTextHeight) / 2, self:GetValue());
end

function Label:UpdateLayout()
    local width = _guihelper.GetTextWidth(self:GetValue() or "", self:GetFont());
    local widthUnitCount = math.ceil(width / self:GetUnitSize());
    return widthUnitCount, self:GetDefaultHeightUnitCount();
end
