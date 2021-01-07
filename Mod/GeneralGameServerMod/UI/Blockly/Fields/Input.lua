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
Input:Property("Type", "text");

-- Input:Property("")

local UnitSize = Const.UnitSize;

function Input:Init(block, opt)
    Input._super.Init(self, block, opt);

    local value = "";
    if (type(opt.text) == "function") then value = opt.text() 
    elseif (type(opt.text) == "string") then value = opt.text 
    else  end

    self:SetType(opt.type == "field_number" and "number" or "text");
    self:SetValue(value);
    self:SetLabel(value);

    return self;
end

function Input:RenderContent(painter)
    local UnitSize = self:GetUnitSize();

    -- background
    Shape:SetBrush(self:GetBackgroundColor());
    Shape:DrawRect(painter, Const.BlockEdgeWidthUnitCount, 0, self.widthUnitCount - Const.BlockEdgeWidthUnitCount * 2, self.heightUnitCount);
    Shape:SetDrawBorder(false);
    Shape:DrawLeftEdge(painter, self.heightUnitCount);
    Shape:DrawRightEdge(painter, self.heightUnitCount, 0, self.widthUnitCount - Const.BlockEdgeWidthUnitCount);
    Shape:SetDrawBorder(true);

    -- input
    painter:SetPen(self:GetColor());
    painter:SetFont(self:GetFont());
    painter:DrawText(Const.BlockEdgeWidthUnitCount * Const.UnitSize, (self.height - self:GetSingleLineTextHeight()) / 2, self:GetLabel());
end

function Input:UpdateWidthHeightUnitCount()
    local widthUnitCount, heightUnitCount = math.max(self:GetTextWidthUnitCount(self:GetLabel()), 6) + Const.BlockEdgeWidthUnitCount * 2, Const.LineHeightUnitCount;
    return if_else(self:IsEdit(), math.max(widthUnitCount, self:GetMinEditFieldWidthUnitCount()), widthUnitCount), heightUnitCount;
end

function Input:GetFieldEditElement(parentElement)
    local InputFieldEditElement = InputElement:new():Init({
        name = "input",
        attr = {
            style = "width: 100%; height: 100%; font-size: 14px;",
            value = self:GetValue(),
        },
    }, parentElement:GetWindow(), parentElement);

    InputFieldEditElement:SetAttrValue("type", self:GetType());
    InputFieldEditElement:SetAttrValue("onkeydown.enter", function()
        local value = InputFieldEditElement:GetValue();
        self:SetValue(value);
        self:SetLabel(value);
        self:FocusOut();
    end)

    self.inputEl = InputFieldEditElement;

    return InputFieldEditElement;
end

function Input:OnBeginEdit()
    if (self.inputEl) then self.inputEl:FocusIn() end
end

function Input:OnEndEdit()
    if (self.inputEl) then self.inputEl:FocusOut() end
end