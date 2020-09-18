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

function Div:OnLoadComponentBeforeChild(parentElement, parentLayout, style)
    -- 默认为白色背景
    if(style and not style.background and not style["background-color"]) then style["background-color"] = "#ffffff00" end
    -- 执行基类函数
	Div._super.OnLoadComponentBeforeChild(self, parentElement, parentLayout, style)	
end
