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

local Const = NPL.load("../Const.lua");
local Shape = NPL.load("../Shape.lua", IsDevEnv);
local BlockInputField = NPL.load("../BlockInputField.lua", IsDevEnv);
local Field = commonlib.inherit(BlockInputField, NPL.export());

local MinEditFieldWidth = 120;
local TextMarginUnitCount = Const.TextMarginUnitCount;    -- 文本边距

Field:Property("Type");                     -- label text, value
Field:Property("Color", "#000000");
Field:Property("BackgroundColor", "#ffffff");

function Field:ctor()
end

function Field:Render(painter)
    painter:SetPen(self:GetBlock():GetColor());

    local offsetX, offsetY = self.left + (self.maxWidth - self.width) / 2, self.top + (self.maxHeight - self.height) / 2;
    painter:SetPen(self:GetColor());
    painter:Translate(offsetX, offsetY);
    self:RenderContent(painter);
    painter:Translate(-offsetX, -offsetY);
end

function Field:RenderContent(painter)
    if (self:IsEdit()) then return end
    local UnitSize = self:GetUnitSize();
    
    Shape:SetBrush(self:GetBackgroundColor());
    Shape:DrawInputField(painter, self.widthUnitCount, self.heightUnitCount + Const.BlockEdgeHeightUnitCount, nil, -Const.BlockEdgeHeightUnitCount / 2);

    -- input
    painter:SetPen(self:GetColor());
    painter:SetFont(self:GetFont());
    painter:DrawText((Const.BlockEdgeWidthUnitCount + TextMarginUnitCount) * UnitSize, (self.height - self:GetSingleLineTextHeight()) / 2, self:GetLabel());
end

function Field:UpdateWidthHeightUnitCount()
    local widthUnitCount = self:GetTextWidthUnitCount(self:GetLabel()) + (TextMarginUnitCount + Const.BlockEdgeWidthUnitCount) * 2;
    return math.min(math.max(widthUnitCount, Const.MinTextShowWidthUnitCount), Const.MaxTextShowWidthUnitCount), Const.LineHeightUnitCount;
end

function Field:IsField()
    return true;
end

function Field:IsCanEdit()
    return true;
end

function Field:GetBlockly()
    return self:GetBlock():GetBlockly();
end

function Field:GetFieldValue()
    return self:GetValue();
end

function Field:GetValueAsString()
    return string.format('"%s"', self:GetValue());
end

-- 获取xmlNode
function Field:SaveToXmlNode()
    local xmlNode = {name = "Field", attr = {}};
    local attr = xmlNode.attr;
    
    attr.name = self:GetName();
    attr.label = self:GetLabel();
    attr.value = self:GetValue();

    return xmlNode;
end

function Field:LoadFromXmlNode(xmlNode)
    local attr = xmlNode.attr;

    self:SetLabel(attr.label);
    self:SetValue(attr.value);
end