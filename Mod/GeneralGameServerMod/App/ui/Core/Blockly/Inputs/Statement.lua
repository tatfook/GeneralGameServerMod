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

local Connection = NPL.load("../Connection.lua", IsDevEnv);
local Shape = NPL.load("../Shape.lua", IsDevEnv);
local Const = NPL.load("../Const.lua", IsDevEnv);
local Input = NPL.load("./Input.lua", IsDevEnv);
local Statement = commonlib.inherit(Input, NPL.export());

function Statement:ctor()
end

function Statement:OnSizeChange()
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
    local blockWidthUnitCount, blockHeightUnitCount = self:GetBlock():GetWidthHeightUnitCount();
    if (widthUnitCount == 0 or heightUnitCount == 0) then return end
    self.nextConnection:SetGeometry(leftUnitCount, topUnitCount, Const.ConnectionRegionWidthUnitCount, Const.ConnectionRegionHeightUnitCount);
end

function Statement:Init(block)
    Statement._super.Init(self, block);

    self.nextConnection = Connection:new():Init(block, "statement");

    return self;
end

function Statement:Render(painter)
    painter:SetPen(self:GetColor() or self:GetBlock():GetColor());
    painter:DrawRect(0, 0, self.width, self.height);

    painter:Translate(self.width, 0);
    local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
    local blockWidthUnitCount, blockHeightUnitCount = self:GetBlock():GetWidthHeightUnitCount();
    local UnitSize = self:GetUnitSize();
    local connectionWidthUnitCount = blockWidthUnitCount - widthUnitCount;
    Shape:DrawNextConnection(painter, connectionWidthUnitCount);

    local inputWidthUnitCount, inputHeightUnitCount = self:GetIputWidthHeightUnitCount();
    painter:Translate(0, (inputHeightUnitCount + Const.ConnectionHeightUnitCount) * UnitSize);
    Shape:DrawPrevConnection(painter, connectionWidthUnitCount);
    painter:Translate(0, -(inputHeightUnitCount + Const.ConnectionHeightUnitCount) * UnitSize);
    
    painter:Translate(-self.width, 0)
end

function Statement:GetIputWidthHeightUnitCount()
    if (self:GetNextBlock()) then return self:GetNextBlock():GetTotalWidthHeightUnitCount() end
    return 0, 4;
end

function Statement:UpdateLayout()
    local inputWidthUnitCount, inputHeightUnitCount = self:GetIputWidthHeightUnitCount();
    
    return 6, inputHeightUnitCount + 2 * Const.ConnectionHeightUnitCount;
end

function Statement:ConnectionBlock(block)
    if (self.nextConnection and block.previousConnection and self.nextConnection:IsMatch(block.previousConnection)) then
        block:GetBlockly():RemoveBlock(block);
        local absoluteLeftUnitCount, absoluteTopUnitCount = self:GetAbsoluteLeftTopUnitCount();
        block:SetLeftTopUnitCount(absoluteLeftUnitCount + self.widthUnitCount, absoluteTopUnitCount + Const.ConnectionHeightUnitCount);
        return true;
    end

    local nextBlock = self:GetNextBlock();
    return nextBlock and block:ConnectionBlock(nextBlock);
end
