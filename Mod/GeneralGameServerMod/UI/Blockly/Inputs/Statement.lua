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

local Const = NPL.load("../Const.lua");
local Shape = NPL.load("../Shape.lua", IsDevEnv);
local Input = NPL.load("./Input.lua", IsDevEnv);
local Statement = commonlib.inherit(Input, NPL.export());

local StatementWidthUnitCount = 6;

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

function Statement:Init(block, opt)
    Statement._super.Init(self, block, opt);
    self.inputConnection:SetType("statement");
    return self;
end

function Statement:Render(painter)
    Shape:SetBrush(self:GetBlock():GetBrush());
    Shape:DrawRect(painter, self.leftUnitCount, self.topUnitCount, self.widthUnitCount, self.heightUnitCount);
    Shape:SetPen(self:GetBlock():GetPen());
    Shape:DrawLine(painter, self.leftUnitCount, self.topUnitCount, self.leftUnitCount, self.topUnitCount + self.heightUnitCount);
    -- Shape:DrawLine(painter, self.leftUnitCount + self.widthUnitCount, self.topUnitCount, self.leftUnitCount + self.widthUnitCount, self.topUnitCount + self.heightUnitCount);

    painter:Translate(self.left + self.width, self.top);
    local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
    local blockWidthUnitCount, blockHeightUnitCount = self:GetBlock():GetWidthHeightUnitCount();
    local connectionWidthUnitCount = blockWidthUnitCount - widthUnitCount;
    Shape:DrawNextConnection(painter, connectionWidthUnitCount, nil, nil, true);
    painter:Translate(0, (self.inputHeightUnitCount + Const.ConnectionHeightUnitCount) * Const.UnitSize);
    Shape:DrawPrevConnection(painter, connectionWidthUnitCount, nil, nil, true);
    painter:Translate(0, -(self.inputHeightUnitCount + Const.ConnectionHeightUnitCount) * Const.UnitSize);
    painter:Translate(-(self.left + self.width), -self.top);

    -- painter:DrawRect(self.left + self.width, self.top + Const.ConnectionHeightUnitCount * Const.UnitSize - Const.UnitSize, Const.UnitSize, Const.UnitSize);
    -- painter:DrawRect(self.left + self.width, self.top + self.height - Const.ConnectionHeightUnitCount * Const.UnitSize, Const.UnitSize, Const.UnitSize);
    local inputBlock = self:GetInputBlock();
    if (not inputBlock) then return end
    painter:DrawRect(self.left + self.width, self.top + Const.ConnectionHeightUnitCount * Const.UnitSize, Const.UnitSize, Const.UnitSize);
    painter:DrawRect(self.left + self.width, self.top + self.height - Const.ConnectionHeightUnitCount * Const.UnitSize - Const.UnitSize, Const.UnitSize, Const.UnitSize);
    inputBlock:Render(painter)
end

function Statement:UpdateWidthHeightUnitCount()
    local inputBlock = self:GetInputBlock();
    if (inputBlock) then 
        _, _, _, _, self.inputWidthUnitCount, self.inputHeightUnitCount = inputBlock:UpdateWidthHeightUnitCount();
    else
        self.inputWidthUnitCount, self.inputHeightUnitCount = 0, 6;
    end
    local widthUnitCount, heightUnitCount = StatementWidthUnitCount + self.inputWidthUnitCount, Const.ConnectionHeightUnitCount * 2 + self.inputHeightUnitCount;
    return widthUnitCount, heightUnitCount, StatementWidthUnitCount, heightUnitCount;
end

function Statement:UpdateLeftTopUnitCount()
    local inputBlock = self:GetInputBlock();
    if (not inputBlock) then return end
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    inputBlock:SetLeftTopUnitCount(leftUnitCount + StatementWidthUnitCount, topUnitCount + Const.ConnectionHeightUnitCount);
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

function Statement:GetMouseUI(x, y, event)
    if (x >= self.left and x <= (self.left + self.width) and y >= self.top and y <= (self.top + self.height)) then return self end
    local block = self:GetBlock();
    if (x >= block.left and x <= (block.left + block.width)  and y >= self.top and y <= (self.top + Const.ConnectionHeightUnitCount * Const.UnitSize)) then return self end
    local inputBlock = self:GetInputBlock();
    return inputBlock and inputBlock:GetMouseUI(x, y, event);
end


