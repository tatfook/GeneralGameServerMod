--[[
Title: Space
Author(s): wxa
Date: 2020/6/30
Desc: 标签字段
use the lib:
-------------------------------------------------------
local Space = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Space.lua");
-------------------------------------------------------
]]

local Field = NPL.load("./Field.lua", IsDevEnv);
local Space = commonlib.inherit(Field, NPL.export());

function Space:Init(block)
    Space._super.Init(self, block);
    return self;
end

function Space:Render(painter)
    Space._super.Render(self, painter);
end

function Space:UpdateWidthHeightUnitCount()
    local widthUnitCount, heightUnitCount = self:GetBlock():GetSpaceUnitCount(), self:GetDefaultHeightUnitCount();
    self:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount);
    return widthUnitCount, heightUnitCount;
end