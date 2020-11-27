--[[
Title: Statement
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Statement = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Inputs/Statement.lua");
-------------------------------------------------------
]]

local Shape = NPL.load("../Shape.lua", IsDevEnv);
local Const = NPL.load("../Const.lua", IsDevEnv);
local Input = NPL.load("./Input.lua", IsDevEnv);
local Statement = commonlib.inherit(Input, NPL.export());

local StatementWidthUnitCount = 6;
local UnitSize = Const.UnitSize;

function Statement:ctor()
end

function Statement:OnSizeChange()
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
    local blockWidthUnitCount, blockHeightUnitCount = self:GetBlock():GetWidthHeightUnitCount();
    if (widthUnitCount == 0 or heightUnitCount == 0) then return end
    -- self.nextConnection:SetGeometry(leftUnitCount, topUnitCount, blockWidthUnitCount, Const.ConnectionRegionHeightUnitCount);
    self.inputConnection:SetGeometry(leftUnitCount, topUnitCount, Const.ConnectionRegionWidthUnitCount, Const.ConnectionRegionHeightUnitCount);
end

function Statement:Init(block)
    Statement._super.Init(self, block);
    self.inputConnection:SetType("statement");
    return self;
end

function Statement:Render(painter)
    painter:SetPen(self:GetColor() or self:GetBlock():GetColor());
    painter:DrawRect(self.left, self.top, self.width, self.height);

    painter:Translate(self.left + self.width, self.top);
    local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
    local blockWidthUnitCount, blockHeightUnitCount = self:GetBlock():GetWidthHeightUnitCount();
    local connectionWidthUnitCount = blockWidthUnitCount - widthUnitCount;
    Shape:DrawNextConnection(painter, connectionWidthUnitCount);
    painter:Translate(0, self.inputHeightUnitCount * UnitSize);
    Shape:DrawPrevConnection(painter, connectionWidthUnitCount);
    painter:Translate(0, -self.inputHeightUnitCount * UnitSize);
    
    painter:Translate(-(self.left + self.width), -self.top);
end

function Statement:UpdateWidthHeightUnitCount()
    local inputBlock = self:GetInputBlock();
    if (inputBlock) then 
        self.inputWidthUnitCount, self.inputHeightUnitCount = inputBlock:UpdateWidthHeightUnitCount();
    else
        self.inputWidthUnitCount, self.inputHeightUnitCount = 0, 6;
    end
    local widthUnitCount, heightUnitCount = StatementWidthUnitCount, Const.ConnectionHeightUnitCount + self.inputHeightUnitCount
    self:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount);
    return widthUnitCount, heightUnitCount;
end

function Statement:UpdateLeftTopUnitCount()
    local inputBlock = self:GetInputBlock();
    if (not inputBlock) then return end
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    inputBlock:SetLeftTopUnitCount(leftUnitCount + StatementWidthUnitCount, topUnitCount);
    inputBlock:UpdateLeftTopUnitCount();
end

function Statement:ConnectionBlock(block)
    if (block.previousConnection and not block.previousConnection:IsConnection() and self.inputConnection:IsMatch(block.previousConnection)) then
        block:GetBlockly():RemoveBlock(block);
        local inputConnectionConnection = self.inputConnection:Disconnection();
        self.inputConnection:Connection(block.previousConnection);
        local blockLastNextBlock = block:GetLastNextBlock();
        if (blockLastNextBlock.nextConnection) then blockLastNextBlock.nextConnection:Connection(inputConnectionConnection) end
        block:GetTopBlock():UpdateLayout();
        return true;
    end

    local inputBlock = self:GetInputBlock();
    return inputBlock and block:ConnectionBlock(inputBlock);
end
