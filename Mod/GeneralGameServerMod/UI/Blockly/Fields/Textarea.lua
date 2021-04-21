--[[
Title: Textarea
Author(s): wxa
Date: 2020/6/30
Desc: 标签字段
use the lib:
-------------------------------------------------------
local Textarea = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Textarea.lua");
-------------------------------------------------------
]]

local Const = NPL.load("../Const.lua");
local Shape = NPL.load("../Shape.lua");
local Field = NPL.load("./Field.lua", IsDevEnv);

local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");

local Textarea = commonlib.inherit(Field, NPL.export());

function Textarea:OnBeginEdit()
    Page.Show({
        text = self:GetValue(),

        confirm = function(value)
            self:SetFieldValue(value);
            self:SetLabel(string.gsub(self:GetValue(), "\n", " "));
            self:FocusOut();
        end,

        close = function()
            self:FocusOut();
        end
    }, {
        url = "%ui%/Blockly/Pages/FieldEditTextArea.html",
        draggable = false,
    });
end

function Textarea:OnEndEdit()
end