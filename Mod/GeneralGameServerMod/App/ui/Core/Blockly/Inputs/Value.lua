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
    Value._super.Render(self, painter);
    
    painter:Translate(self.left, self.top);
    painter:SetPen(self:GetColor());
    Shape:DrawLeftEdge(painter, self.heightUnitCount, self.widthUnitCount - Const.BlockEdgeWidthUnitCount * 2);
    Shape:DrawRightEdge(painter, self.heightUnitCount, 0, self.widthUnitCount - Const.BlockEdgeWidthUnitCount);
    -- Shape:DrawDownEdge(painter, self.widthUnitCount, 0, 0, self.heightUnitCount - Const.BlockEdgeHeightUnitCount);

    -- 用field_input代替  field_input应支持方形, 圆形
    -- if (not self:GetInputBlock()) then
    --     painter:Translate(0, UnitSize);
    --     painter:DrawCircle(UnitSize * 3, -UnitSize * 3, 0, UnitSize * 3, "z", true, nil, math.pi / 2, math.pi * 3 / 2);
    --     painter:DrawRect(UnitSize * 3, 0, UnitSize * 3, self.height - 2 * UnitSize);
    --     painter:DrawCircle(UnitSize * 6, -UnitSize * 3, 0, UnitSize * 3, "z", true, nil, math.pi * 3 / 2, math.pi * 5 / 2);
    --     painter:Translate(0, -UnitSize);
    -- end
    painter:Translate(-self.left, -self.top);
end

function Value:UpdateWidthHeightUnitCount()
    local widthUnitCount, heightUnitCount = Const.InputValueWidthUnitCount, self:GetLineHeightUnitCount() - 2;

    if (self:GetInputBlock()) then 
        widthUnitCount, heightUnitCount = self:GetInputBlock():UpdateWidthHeightUnitCount();
        heightUnitCount = heightUnitCount - Const.BlockEdgeHeightUnitCount * 2;
    end

    self:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount);
    
    return widthUnitCount, heightUnitCount;
end

function Input:UpdateLeftTopUnitCount()
end