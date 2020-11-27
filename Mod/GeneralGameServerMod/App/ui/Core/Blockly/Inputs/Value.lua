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

local Shape = NPL.load("../Shape.lua", IsDevEnv);
local Const = NPL.load("../Const.lua", IsDevEnv);
local Input = NPL.load("./Input.lua", IsDevEnv);
local Value = commonlib.inherit(Input, NPL.export());

local UnitSize = Const.UnitSize;

function Value:ctor()
end

function Value:Init(block, opt)
    opt = opt or {};

    opt.color = opt.color or "#ffffff";

    Value._super.Init(self, block, opt);

    self.inputConnection:SetType("value");

    return self;
end


function Value:Render(painter)
    painter:SetPen(self:GetBlock():GetColor());
    painter:DrawRect(self.left, self.top, self.maxWidth, self.maxHeight);

    local inputBlock = self:GetInputBlock();
    if (inputBlock) then return inputBlock:Render(painter) end

    painter:Translate(self.left, self.top + Const.BlockEdgeHeightUnitCount * UnitSize);
    painter:SetPen("#fffffff0");
    Shape:DrawLeftEdge(painter, self.heightUnitCount);
    painter:DrawRect(Const.BlockEdgeWidthUnitCount * UnitSize, 0, self.width - Const.BlockEdgeWidthUnitCount * 2 * UnitSize, self.height);
    Shape:DrawRightEdge(painter, self.heightUnitCount, 0, self.widthUnitCount - Const.BlockEdgeWidthUnitCount);
    painter:Translate(-self.left, -self.top - Const.BlockEdgeHeightUnitCount * UnitSize);
end

function Value:OnSizeChange()
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
    self.inputConnection:SetGeometry(leftUnitCount, topUnitCount, widthUnitCount, heightUnitCount);
end

function Value:UpdateWidthHeightUnitCount()
    local inputBlock = self:GetInputBlock();

    if (not inputBlock) then return Const.InputValueWidthUnitCount, self:GetLineHeightUnitCount() - Const.BlockEdgeHeightUnitCount * 2 end
    return inputBlock:UpdateWidthHeightUnitCount();
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
            block:GetBlockly():AddBlock(inputConnectionConnection:GetBlock());
        end
        return true;
    end

    local inputBlock = self:GetInputBlock();
    return inputBlock and block:ConnectionBlock(inputBlock);
end

function Value:GetMouseUI(x, y)
    if (x < self.left or x > (self.left + self.width) or y < self.top or y > (self.top + self.height)) then return end
    return self:GetInputBlock() or self;
end