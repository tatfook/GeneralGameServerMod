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

local ButtonWidthUnitCount = Const.LineHeightUnitCount;

function Button:RenderContent(painter)
    -- painter:DrawRectTexture(6, 6, 13, 13, "Texture/Aries/Creator/keepwork/ggs/blockly/plus_13x13_32bits.png#0 0 13 13");
end

function Button:UpdateWidthHeightUnitCount()
    return ButtonWidthUnitCount, Const.LineHeightUnitCount;
end

function Button:SaveToXmlNode()
    return nil;
end

function Button:LoadFromXmlNode(xmlNode)
end

function Button:IsCanEdit()
    return false;
end

function Button:OnMouseDown()
end