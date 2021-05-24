--[[
Title: Image
Author(s): wxa
Date: 2020/8/14
Desc: 图片
-------------------------------------------------------
local Image = NPL.load("Mod/GeneralGameServerMod/UI/Window/Elements/Image.lua");
-------------------------------------------------------
]]


local Element = NPL.load("../Element.lua");
local Image = commonlib.inherit(Element, NPL.export());

Image:Property("Name", "Image");

function Image:ctor()
end

function Image:GetBackground()
    return self:GetAttrStringValue("src") or Image._super.GetBackground(self);
end