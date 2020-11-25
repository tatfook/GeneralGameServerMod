--[[
Title: Field
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Field = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Field.lua");
-------------------------------------------------------
]]

local InputField = NPL.load("../InputField.lua", IsDevEnv);
local Field = commonlib.inherit(InputField, NPL.export());

Field:Property("Value");                    -- 值

function Field:ctor()
end

function Field:Init(block)
    Field._super.Init(self, block);

    self.contentHeight = self:GetDefaultHeightUnitCount() * self:GetUnitSize();
    self.singleLineTextHeight = self:GetSingleLineTextHeight();

    return self;
end

function Field:GetDefaultHeightUnitCount()
    return 8;
end

function Field:GetDefaultWidthUnitCount()
    return self:GetDefaultHeightUnitCount() * 2;
end

function Field:RenderContent()
end

function Field:Render(painter)
    painter:SetPen(self:GetBlock():GetColor());
    painter:DrawRect(0, 0, self.width, self.height);

    local offsetY = (self.heightUnitCount - self:GetDefaultHeightUnitCount()) / 2 * self:GetUnitSize();
    painter:Translate(0, offsetY);
    self:RenderContent(painter);
    painter:Translate(0, -offsetY);
end


