--[[
Title: Field
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Field = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Field.lua");
-------------------------------------------------------
]]

local Field = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Field:Property("Input");
Field:Property("Type");                     -- label text, value
Field:Property("Value");                    -- 值
function Field:ctor()
end

function Field:Init(input)
    self:SetInput(input);
    return self;
end

function Field:GetUnitSize()
    return self:GetInput():GetUnitSize();
end

function Field:GetFont()
    -- return string.format("System;%s", 4 * self:GetUnitSize());
    return "System;16";
end

function Field:Render(painter)
    local defaultFieldHeightUnitCount = 8;
    local UnitSize = self:GetUnitSize();
    if (self:GetType() == "label") then
        local width = _guihelper.GetTextWidth(self:GetValue() or "", self:GetFont());
        local fieldWidthUnitCount = math.floor(width / UnitSize) + 1;
        return fieldWidthUnitCount, defaultFieldHeightUnitCount;
    end
end
