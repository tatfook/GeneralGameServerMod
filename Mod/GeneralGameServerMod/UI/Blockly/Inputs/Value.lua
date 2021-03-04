--[[
Title: Value
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Value = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Inputs/Value.lua");
-------------------------------------------------------
]]

local InputElement = NPL.load("../../Window/Elements/Input.lua", IsDevEnv);
local Const = NPL.load("../Const.lua");
local Shape = NPL.load("../Shape.lua", IsDevEnv);
local Input = NPL.load("./Input.lua", IsDevEnv);
local Value = commonlib.inherit(Input, NPL.export());

local TextMarginUnitCount = Const.TextMarginUnitCount;    -- 文本边距

Value:Property("Value", ""); -- 值

function Value:ctor()
end

function Value:Init(block, opt)
    opt = opt or {};

    opt.color = opt.color or "#000000";

    Value._super.Init(self, block, opt);

    self.inputConnection:SetType("value");

    return self;
end

function Value:Render(painter)
    local inputBlock = self:GetInputBlock();
    if (inputBlock) then return inputBlock:Render(painter) end

    local offsetX, offsetY = self:GetOffset();
    painter:Translate(offsetX, offsetY);
    Shape:SetBrush(self:GetBackgroundColor());
    Shape:DrawRect(painter, Const.BlockEdgeWidthUnitCount, 0, self.widthUnitCount - Const.BlockEdgeWidthUnitCount * 2, self.heightUnitCount);

    Shape:SetDrawBorder(false);
    Shape:DrawUpEdge(painter, self.widthUnitCount);
    Shape:DrawDownEdge(painter, self.widthUnitCount, 0, 0, self.heightUnitCount - Const.BlockEdgeHeightUnitCount);
    Shape:DrawLeftEdge(painter, self.heightUnitCount);
    Shape:DrawRightEdge(painter, self.heightUnitCount, 0, self.widthUnitCount - Const.BlockEdgeWidthUnitCount);
    Shape:SetDrawBorder(true);
    
    painter:SetPen(self:GetColor());
    painter:SetFont(self:GetFont());
    painter:DrawText((Const.BlockEdgeWidthUnitCount + TextMarginUnitCount) * Const.UnitSize, (self.height - self:GetSingleLineTextHeight()) / 2, self:GetLabel());
    painter:Translate(-offsetX, -offsetY);
end

function Value:OnSizeChange()
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
    self.inputConnection:SetGeometry(leftUnitCount, topUnitCount, widthUnitCount, heightUnitCount);
end

function Value:UpdateWidthHeightUnitCount()
    local inputBlock = self:GetInputBlock();
    if (inputBlock) then 
        local _, _, _, _, widthUnitCount, heightUnitCount = inputBlock:UpdateWidthHeightUnitCount();
        return widthUnitCount, heightUnitCount;
    else
        local widthUnitCount = self:GetTextWidthUnitCount(self:GetLabel()) + (TextMarginUnitCount + Const.BlockEdgeWidthUnitCount) * 2;
        return math.min(math.max(widthUnitCount, Const.MinTextShowWidthUnitCount), Const.MaxTextShowWidthUnitCount), Const.LineHeightUnitCount;
    end
end

function Value:UpdateLeftTopUnitCount()
    local inputBlock = self:GetInputBlock();
    if (not inputBlock) then return end
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    inputBlock:SetLeftTopUnitCount(leftUnitCount, topUnitCount);
    inputBlock:UpdateLeftTopUnitCount();
end

function Value:ConnectionBlock(block)
    if (block.outputConnection and not block.outputConnection:IsConnection() and self.inputConnection:IsMatch(block.outputConnection)) then
        block:GetBlockly():RemoveBlock(block);
        local inputConnectionConnection = self.inputConnection:Disconnection();
        self.inputConnection:Connection(block.outputConnection);
        self:GetTopBlock():UpdateLayout();
        if (inputConnectionConnection) then
            block:GetBlockly():AddBlock(inputConnectionConnection:GetBlock(), true);
        end
        return true;
    end

    local inputBlock = self:GetInputBlock();
    return inputBlock and block:ConnectionBlock(inputBlock);
end

function Value:GetMouseUI(x, y, event)
    if (x < self.left or x > (self.left + self.width) or y < self.top or y > (self.top + self.height)) then return end
    local inputBlock = self:GetInputBlock();
    if (inputBlock) then return inputBlock:GetMouseUI(x, y, event) end
    return self;
end

function Value:IsCanEdit()
    return if_else(self:GetOption().editable == false, false, true);
end

function Value:GetShadowType()
    local shadow = self:GetOption().shadow;
    return shadow and shadow.type;
end

function Value:GetFieldEditType()
    return "input";
end

function Value:GetValueAsString()
    if (not self:GetInputBlock()) then 
        if (self:GetShadowType() == "math_number" or self:GetShadowType() == "field_number") then
            return string.format('%s', self:GetValue());
        else 
            return string.format('"%s"', self:GetValue());
        end
    end
    return self:GetInputBlock():GetBlockCode();
end

function Value:GetFieldValue() 
    if (not self:GetInputBlock()) then 
        return self:GetValue();
    end
    return self:GetInputBlock():GetBlockCode();
end