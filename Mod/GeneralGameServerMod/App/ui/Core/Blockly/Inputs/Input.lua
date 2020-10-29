--[[
Title: Input
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Input = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Input.lua");
-------------------------------------------------------
]]

local Input = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Input:Property("Block");                    -- 所属块
Input:Property("Type");                     -- statement value dummy

function Input:ctor()
    self.leftUnitCount, self.topUnitCount, self.widthUnitCount, self.heightUnitCount = 0, 0, 0, 0;
end

function Input:Init(block)
    self:SetBlock(block);

    return self;
end

function Input:GetUnitSize()
    return self:GetBlock():GetUnitSize();
end

function Input:Render(painter)
    for _, field in ipairs(self.fields) do
    end
end
