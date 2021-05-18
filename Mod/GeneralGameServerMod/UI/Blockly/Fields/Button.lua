--[[
Title: Button
Author(s): wxa
Date: 2020/6/30
Desc: 按钮字段
use the lib:
-------------------------------------------------------
local Button = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Button.lua");
-------------------------------------------------------
]]

local Const = NPL.load("../Const.lua");
local Field = NPL.load("./Field.lua");

local Button = commonlib.inherit(Field, NPL.export());
local ButtonCallback = {};

Button:Property("Color", "#cccccc");                    -- 颜色
Button:Property("BackgroundColor", "#ffffff00");

function Button:RenderContent(painter)
    painter:SetPen(self:GetColor());
    painter:SetFont(self:GetFont());
    painter:DrawText(0, (self.height - self:GetSingleLineTextHeight()) / 2, self:GetValue());
end

function Button:UpdateWidthHeightUnitCount()
    return self:GetTextWidthUnitCount(self:GetValue()), Const.LineHeightUnitCount;
end

function Button:SaveToXmlNode()
    return nil;
end

function Button:LoadFromXmlNode(xmlNode)
end

function Button:IsCanEdit()
    return false;
end

function Button:GetCallBack()
    local callback = self:GetOption().callback;
    if (type(callback) == "function") then return callback end
    if (type(callback) == "string") then 
        if (ButtonCallback[callback]) then return ButtonCallback[callback] end

        local func, errmsg = loadstring(callback);
        return func;
    end
end

function Button:OnMouseDown()
    local callback = self:GetCallBack();
    if (callback) then
        callback(self:GetBlock());
    end
end

function ButtonCallback.NPL_Macro_Start(block)
    local player = GameLogic.EntityManager.GetPlayer();
    if (not player) then return end
    local bx, by, bz = player:GetBlockPos();
    block:SetFieldValue("X", bx);
    block:SetFieldValue("Y", by);
    block:SetFieldValue("Z", bz);
    block:GetTopBlock():UpdateLayout();
end
