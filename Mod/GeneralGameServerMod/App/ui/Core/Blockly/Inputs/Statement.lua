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
local Input = NPL.load("./Input.lua", IsDevEnv);
local Statement = commonlib.inherit(Input, NPL.export());

function Statement:ctor()
end

function Statement:Init(block)
    Statement._super.Init(self, block);
    
    return self;
end

function Statement:Render(painter)
    painter:SetPen(self:GetColor() or self:GetBlock():GetColor());
    painter:DrawRect(0, 0, self.width, self.height);

    painter:Translate(self.width, 0);
    local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
    local blockWidthUnitCount, blockHeightUnitCount = self:GetBlock():GetWidthHeightUnitCount();
    local UnitSize = self:GetUnitSize();
    local WidthUnitCount = blockWidthUnitCount - widthUnitCount;
    Shape:DrawNextConnection(painter, {UnitSize = UnitSize, WidthUnitCount = WidthUnitCount});

    local inputBlockWidthUnitCount, inputBlockHeightUnitCount = self:GetIputBlockWidthHeightUnitCount();
    painter:Translate(0, (inputBlockHeightUnitCount + 4) * UnitSize);
    Shape:DrawPrevConnection(painter, {UnitSize = UnitSize, WidthUnitCount = WidthUnitCount});
    painter:Translate(0, -(inputBlockHeightUnitCount + 4) * UnitSize);
    
    painter:Translate(-self.width, 0)
end


function Statement:GetIputBlockWidthHeightUnitCount()
    if (self:GetInputBlock()) then
        return self:GetInputBlock():UpdateLayout();
    end

    return 0, 4;
end

function Statement:UpdateLayout()
    local inputBlockWidthUnitCount, inputBlockHeightUnitCount = self:GetIputBlockWidthHeightUnitCount();
    
    return 6, inputBlockHeightUnitCount + 6;
end
