--[[
Title: Div
Author(s): wxa
Date: 2020/8/14
Desc: Div 元素
-------------------------------------------------------
local Div = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/Div.lua");
-------------------------------------------------------
]]


local Element = NPL.load("../Element.lua");
local Div = commonlib.inherit(Element, NPL.export());

function Div:ctor()
    self:SetName("Div");
end
