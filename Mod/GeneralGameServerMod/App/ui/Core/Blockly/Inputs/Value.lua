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

local Input = NPL.load("./Input.lua", IsDevEnv);

local Value = commonlib.inherit(Input, NPL.export());

function Value:ctor()
end

function Value:Init(block)
    Value._super.Init(self, block);

    self:SetColor("#ffffff");

    return self;
end


function Value:Render(painter)
    local UnitSize = self:GetUnitSize()
    
    painter:SetPen(self:GetBlock():GetColor());
    painter:DrawRect(0, 0, self.width, self.height);

    painter:SetPen(self:GetColor());

    -- 用field_input代替  field_input应支持方形, 圆形
    if (not self:GetInputBlock()) then
        painter:Translate(0, UnitSize);
        painter:DrawCircle(UnitSize * 3, -UnitSize * 3, 0, UnitSize * 3, "z", true, nil, math.pi / 2, math.pi * 3 / 2);
        painter:DrawRect(UnitSize * 3, 0, UnitSize * 3, self.height - 2 * UnitSize);
        painter:DrawCircle(UnitSize * 6, -UnitSize * 3, 0, UnitSize * 3, "z", true, nil, math.pi * 3 / 2, math.pi * 5 / 2);
        painter:Translate(0, -UnitSize);
    end
end

function Value:UpdateLayout()
    if (not self:GetInputBlock()) then return 9, self:GetLineHeightUnitCount() end

    local blockWidthUnitCount, blockHeightUnitCount = self:GetInputBlock():UpdateLayout();

    return blockWidthUnitCount, blockHeightUnitCount;
end