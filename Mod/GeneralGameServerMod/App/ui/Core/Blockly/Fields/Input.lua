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
local InputElement = NPL.load("../../Window/Elements/Input.lua", IsDevEnv);

local Const = NPL.load("../Const.lua", IsDevEnv);
local Shape = NPL.load("../Shape.lua", IsDevEnv);
local Field = NPL.load("./Field.lua", IsDevEnv);
local Input = commonlib.inherit(Field, NPL.export());

Input:Property("Name", "Input");
Input:Property("Color", "#000000");
Input:Property("BackgroundColor", "#ffffff");
Input:Property("Value", "");
Input:Property("Text", "");
Input:Property("Type", "text");
-- Input:Property("")

local UnitSize = Const.UnitSize;

function Input:Init(block, opt)
    Input._super.Init(self, block);

    local value = "";
    if (type(opt.text) == "function") then value = opt.text() 
    elseif (type(opt.text) == "string") then value = opt.text 
    else  end

    self:SetValue(value);
    self:SetText(value);

    return self;
end

function Input:RenderContent(painter)
    local UnitSize = self:GetUnitSize();

    -- background
    painter:SetPen(self:GetBackgroundColor());
    Shape:DrawLeftEdge(painter, self.heightUnitCount);
    painter:DrawRect(Const.BlockEdgeWidthUnitCount * UnitSize, 0, self.width - Const.BlockEdgeWidthUnitCount * 2 * UnitSize, self.height);
    Shape:DrawRightEdge(painter, self.heightUnitCount, 0, self.widthUnitCount - Const.BlockEdgeWidthUnitCount);

    -- input
    painter:SetPen(self:GetColor());
    painter:SetFont(self:GetFont());
    painter:DrawText(Const.BlockEdgeWidthUnitCount * Const.UnitSize, (self.height - self:GetSingleLineTextHeight()) / 2, self:GetText());
end

function Input:UpdateWidthHeightUnitCount()
    local widthUnitCount, heightUnitCount = math.max(self:GetTextWidthUnitCount(self:GetText()), 4) + Const.BlockEdgeWidthUnitCount * 2, self:GetLineHeightUnitCount() - Const.BlockEdgeHeightUnitCount * 2;
    return if_else(self:IsEdit(), math.max(widthUnitCount, self:GetMinEditFieldWidthUnitCount()), widthUnitCount), heightUnitCount;
end

function Input:GetFieldEditElement(parentElement)
    local InputFieldEditElement = InputElement:new():Init({
        name = "input",
        attr = {
            style = "width: 100%; height: 100%; font-size: 14px;",
            value = self:GetValue(),
            autofocus = true,
        },
    }, parentElement:GetWindow(), parentElement);

    InputFieldEditElement:SetAttrValue("onkeydown.enter", function()
        local value = InputFieldEditElement:GetValue();
        self:SetValue(value);
        self:SetText(value);
        self:FocusOut();
    end)

    return InputFieldEditElement;
end