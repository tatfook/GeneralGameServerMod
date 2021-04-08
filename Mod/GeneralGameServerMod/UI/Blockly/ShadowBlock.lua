--[[
Title: ShadowBlock
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local ShadowBlock = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/ShadowBlock.lua");
-------------------------------------------------------
]]

local Const = NPL.load("./Const.lua");
local Shape = NPL.load("./Shape.lua");
local Block = NPL.load("./Block.lua");

local ShadowBlock = commonlib.inherit(Block, NPL.export());

function ShadowBlock:Init(blockly, opt)
    opt = opt or {
        type = "__shadow_block__",
        previousStatement = true,
        nextStatement = true,
        output = true,
        color = "#00000080",
        isDraggable = false,
    };

    ShadowBlock._super.Init(self, blockly, opt);
    self:SetLeftTopUnitCount(0, 0);
    self:SetWidthHeightUnitCount(0, 12);

    self.next_connection = self.nextConnection;
    self.previous_connection = self.previousConnection;
    self.output_connection = self.outputConnection;
    self.shadowBlock = nil;
    self.isShadowBlock = true;

    return self;
end

function ShadowBlock:Disconnection()
    local previousConnection = self.previousConnection and self.previousConnection:Disconnection();
    local nextConnection = self.nextConnection and self.nextConnection:Disconnection();

    if (previousConnection) then
        previousConnection:Connection(nextConnection);
        previousConnection:GetBlock():GetTopBlock():UpdateLayout();
    else 
        if (nextConnection) then
            self:GetBlockly():AddBlock(nextConnection:GetBlock());
        end
    end

    if (self.outputConnection) then self.outputConnection:Disconnection() end
end

function ShadowBlock:Shadow(block)
    self:Disconnection();
    self.shadowBlock = block;
    if (not block) then 
        self:GetBlockly():RemoveBlock(self);
        return ;
    end

    self:GetBlockly():AddBlock(self);
    self.nextConnection = block.nextConnection and self.next_connection;
    self.previousConnection = block.previousConnection and self.previous_connection;
    self.outputConnection = block.outputConnection and self.output_connection;
    self:SetLeftTopUnitCount(block.leftUnitCount, block.topUnitCount);
    self:SetWidthHeightUnitCount(block.widthUnitCount, self.heightUnitCount);
    self:TryConnectionBlock();
end

function ShadowBlock:Render(painter)
    if (not self.previousConnection and not self.nextConnection) then return end
    if (not self.previousConnection:IsConnection() and not self.nextConnection:IsConnection()) then return end 

    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();

    heightUnitCount = heightUnitCount + Const.ConnectionHeightUnitCount;

    Shape:SetBrush(self:GetBrush());
    Shape:DrawShadowBlock(painter, leftUnitCount, topUnitCount, widthUnitCount, heightUnitCount);

    local nextBlock = self:GetNextBlock();
    if (nextBlock) then nextBlock:Render(painter) end
end

function ShadowBlock:UpdateWidthHeightUnitCount()
    local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
    local maxWidthUnitCount, maxHeightUnitCount = widthUnitCount, heightUnitCount;

    self:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount);
    self:SetMaxWidthHeightUnitCount(maxWidthUnitCount, maxHeightUnitCount);

    local nextBlock = self:GetNextBlock();
    if (nextBlock) then 
        local _, _, _, _, nextBlockTotalWidthUnitCount, nextBlockTotalHeightUnitCount = nextBlock:UpdateWidthHeightUnitCount();
        self:SetTotalWidthHeightUnitCount(math.max(maxWidthUnitCount, nextBlockTotalWidthUnitCount), maxHeightUnitCount + nextBlockTotalHeightUnitCount);
    else
        self:SetTotalWidthHeightUnitCount(maxWidthUnitCount, maxHeightUnitCount);
    end
    local totalWidthUnitCount, totalHeightUnitCount = self:GetTotalWidthHeightUnitCount();
    return maxWidthUnitCount, maxHeightUnitCount, widthUnitCount, heightUnitCount, totalWidthUnitCount, totalHeightUnitCount;
end