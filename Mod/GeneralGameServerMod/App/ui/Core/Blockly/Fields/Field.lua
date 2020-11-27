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

Field:Property("Value");                    -- 值
Field:Property("Type");                     -- label text, value

function Field:ctor()
end

function Field:GetFieldEditElement(parentElement)
end

function Field:BeginEdit(opt)
    local editor = self:GetEditorElement();
    editor:ClearChildElement();
    local style = editor:GetStyle();
    style.NormalStyle.left = self.left + (self.maxWidth - self.width) / 2;
    style.NormalStyle.top = self.top + (self.maxHeight - self.height) / 2;
    style.NormalStyle.width = self.width;
    style.NormalStyle.height = self.height;
    local fieldEditElement = self:GetFieldEditElement(editor);
    if (not fieldEditElement) then return end
    editor:InsertChildElement(fieldEditElement);
    editor:UpdateLayout();
end

function Field:EndEdit()
    local editor = self:GetEditorElement();
    editor:SetGeometry(0, 0, 0, 0);
    self:GetTopBlock():UpdateLayout();
end
