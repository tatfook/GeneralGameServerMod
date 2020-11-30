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

local Const = NPL.load("../Const.lua", IsDevEnv);
local BlockInputField = NPL.load("../BlockInputField.lua", IsDevEnv);
local Field = commonlib.inherit(BlockInputField, NPL.export());

local MinEditFieldWidth = 120;


Field:Property("Value");                    -- 值
Field:Property("Type");                     -- label text, value
Field:Property("Edit", false, "IsEdit");    -- 是否在编辑
function Field:ctor()
end

function Field:GetFieldEditElement(parentElement)
end

function Field:GetMinEditFieldWidthUnitCount()
    return Const.MinEditFieldWidthUnitCount;
end

function Field:BeginEdit(opt)
    local editor = self:GetEditorElement();
    editor:ClearChildElement();
    local style = editor:GetStyle();
    style.NormalStyle.left = self.left + (self.maxWidth - self.width) / 2;
    style.NormalStyle.top = self.top + (self.maxHeight - self.height) / 2;
    style.NormalStyle.width = math.max(self.width, self:GetMinEditFieldWidthUnitCount() * Const.UnitSize);
    style.NormalStyle.height = self.height;
    local fieldEditElement = self:GetFieldEditElement(editor);
    if (not fieldEditElement) then return end
    self:SetEdit(true);
    self:GetTopBlock():UpdateLayout();

    editor:InsertChildElement(fieldEditElement);
    editor:UpdateLayout();
end

function Field:EndEdit()
    self:SetEdit(false);

    local editor = self:GetEditorElement();
    editor:SetGeometry(0, 0, 0, 0);
    self:GetTopBlock():UpdateLayout();
end

function Field:OnFocusIn()
    self:BeginEdit();
end

function Field:OnFocusOut()
    self:EndEdit();
end

function Field:IsField()
    return true;
end

function Field:GetFieldValue()
    return self:GetValue();
end
