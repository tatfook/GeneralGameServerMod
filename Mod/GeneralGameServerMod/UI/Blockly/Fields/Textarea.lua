--[[
Title: Textarea
Author(s): wxa
Date: 2020/6/30
Desc: 标签字段
use the lib:
-------------------------------------------------------
local Textarea = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Textarea.lua");
-------------------------------------------------------
]]

local Const = NPL.load("../Const.lua", IsDevEnv);
local Field = NPL.load("./Field.lua", IsDevEnv);
local Shape = NPL.load("../Shape.lua", IsDevEnv);

local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");

local Textarea = commonlib.inherit(Field, NPL.export());
Textarea:Property("Color", "#000000");

function Textarea:RenderContent(painter)
    painter:SetPen(self:GetColor());
    painter:SetFont(self:GetFont());
    local value = self:GetValue();
    local text = _guihelper.TrimUtf8TextByWidth(value, Const.MaxTextShowWidthUnitCount * Const.UnitSize - 30, self:GetFont());
    if (text ~= value) then text = text .. "..." end
    
    Shape:SetBrush(self:GetBackgroundColor());
    Shape:DrawRect(painter, Const.BlockEdgeWidthUnitCount, 0, self.widthUnitCount - Const.BlockEdgeWidthUnitCount * 2, self.heightUnitCount);
    Shape:SetDrawBorder(false);
    Shape:DrawLeftEdge(painter, self.heightUnitCount);
    Shape:DrawRightEdge(painter, self.heightUnitCount, 0, self.widthUnitCount - Const.BlockEdgeWidthUnitCount);
    Shape:SetDrawBorder(true);

    painter:SetPen(self:GetColor());
    painter:SetFont(self:GetFont());
    painter:DrawText(Const.BlockEdgeWidthUnitCount * Const.UnitSize, (self.height - self:GetSingleLineTextHeight()) / 2, text);
end

function Textarea:UpdateWidthHeightUnitCount()
    local widthUnitCount = self:GetTextWidthUnitCount(self:GetValue()) + Const.BlockEdgeWidthUnitCount * 2;
    return math.min(math.max(widthUnitCount, Const.MinTextShowWidthUnitCount), Const.MaxTextShowWidthUnitCount),  Const.LineHeightUnitCount;
end

function Textarea:OnBeginEdit()
    Page.Show({
        text = self:GetValue(),

        confirm = function(value)
            self:SetValue(value);
            self:FocusOut();
        end,

        close = function()
            self:FocusOut();
        end
    }, {
        url = "%ui%/Blockly/Pages/FieldEditTextArea.html",
        draggable = false,
    });
end

function Textarea:OnEndEdit()
end