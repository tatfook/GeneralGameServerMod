--[[
Title: Button
Author(s): wxa
Date: 2020/8/14
Desc: 按钮
-------------------------------------------------------
local Button = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/Button.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua", IsDevEnv);
local Button = commonlib.inherit(Element, NPL.export());

Button:Property("Value");                                -- 按钮文本值
Button:Property("Active", false, "IsActive");            -- 是否激活
Button:Property("Hover", false, "IsHover");              -- 是否鼠标悬浮

Button:Property("BaseStyle", {
	["display"] = "inline",
	["background-color"] = "#ff0000",
});

function Button:ctor()
	self:SetName("Button");
end

-- 初始化函数
function Button:Init(xmlNode)
	-- 设置元素属性
	self:SetTagName(xmlNode.name);
	self:SetAttr(xmlNode.attr);
	self:SetXmlNode(xmlNode);

	-- 获取按钮文本
	local value = self:GetAttrValue("value");
	-- 如果没值取第一个文本节点
	if (not value) then
		for i = 1, #xmlNode do
			if (type(xmlNode[i]) == "string" or type(xmlNode[i] == "number")) then
				value = tostring(xmlNode[i]);
				break;
			end
		end
	end

	-- 设置按钮
	self:SetValue(value or "");

	return self;
end

-- 子元素布局前回调
function Button:OnBeforeUpdateChildElementLayout(elementLayout, parentElementLayout)
	local style = self:GetStyle();

    local paddingLeft, paddingTop, paddingRight, paddingBottom = elementLayout:GetPaddings();
    local width, height = elementLayout:GetWidthHeight();
    
    width = width or (_guihelper.GetTextWidth(self:GetValue(), style:GetFont())  + paddingLeft + paddingRight);
	height = height or (style:GetLineHeight() + paddingTop + paddingBottom);
	
    elementLayout:SetWidthHeight(width, height);

	return true;  -- 返回true不执行子元素布局
end

-- 按钮渲染
function Button:RenderContent(painter, style)
	-- local style = self:GetCurrentStyle(); 
	local x, y, w, h = self:GetGeometry();
	local text = self:GetValue();
	if(not text or text =="") then return end
	local paddingTop, paddingRight, paddingBottom, paddingLeft = style["padding-top"] or 0, style["padding-right"] or 0, style["padding-bottom"] or 0, style["padding-left"] or 0;
	local textWidth = _guihelper.GetTextWidth(self:GetValue(), style:GetFont());
	local textHeight = style:GetFontSize();
	local offsetLeft = (w - textWidth - paddingLeft - paddingRight) / 2;
	local offsetTop = (h - textHeight - paddingTop - paddingBottom) / 2;
	offsetLeft = offsetLeft > 0 and offsetLeft or 0;
	offsetTop = offsetTop > 0 and offsetTop or 0;
	x = x + paddingLeft + offsetLeft;
	y = y + paddingTop + offsetTop;
	painter:SetFont(style:GetFont());
	painter:SetPen(style:GetColor());
	painter:DrawText(x, y, text);
end


