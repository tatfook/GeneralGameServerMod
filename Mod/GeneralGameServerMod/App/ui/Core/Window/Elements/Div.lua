--[[
Title: Div
Author(s): wxa
Date: 2020/8/14
Desc: Div 元素
-------------------------------------------------------
local Div = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/Div.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/Shapes/Rectangle.lua");
local Rectangle = commonlib.gettable("System.Windows.Shapes.Rectangle");

local Element = NPL.load("../Element.lua");
local Div = commonlib.inherit(Element, NPL.export());

function Div:ctor()
    self:SetName("Div");
end

function Div:LoadComponent(parentElement, parentLayout, parentStyle)
	local _this = self.control;
	if(not _this) then
		_this = Rectangle:new():init(parentElement);
		self:SetControl(_this);
	else
		_this:SetParent(parentElement);
	end

	Div._super.LoadComponent(self, _this, parentLayout, parentStyle);
end

function Div:OnLoadComponentBeforeChild(parentElement, parentLayout, style)
    -- 默认为白色背景
    if(not style.background and not style["background-color"]) then style["background-color"] = "#ffffff00" end
    -- 执行基类函数
	Div._super.OnLoadComponentBeforeChild(self, parentElement, parentLayout, style)	
end
