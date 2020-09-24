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
	NormalStyle = {
		["display"] = "inline",
		["background-color"] = "#434343",
		["color"] = "#ffffff",
		["font-size"] = 12,
		["padding-top"] = 5,
		["padding-right"] = 10,
		["padding-bottom"] = 5,
		["padding-left"] = 10,
	},
	HoverStyle = {
		["color"] = "#ff0000",
	}
});

local ButtonElementDebug = GGS.Debug.GetModuleDebug("ButtonElementDebug");

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

	-- ButtonElementDebug(xmlNode, value);

	-- 设置按钮
	self:SetValue(value or "");

	return self;
end

-- 子元素布局前回调
function Button:OnBeforeUpdateChildLayout()
	local layout, style = self:GetLayout(), self:GetStyle();
	local borderTop, borderRight, borderBottom, borderLeft = layout:GetBorder();
    local paddingTop, paddingRight, paddingBottom, paddingLeft = layout:GetPadding();
    local width, height = layout:GetWidthHeight();
	
	local textWidth = _guihelper.GetTextWidth(self:GetValue(), style:GetFont());
	local textHeight = style:GetLineHeight();
    width = width or (textWidth + paddingLeft + paddingRight + borderLeft + borderRight);
	height = height or (textHeight + paddingTop + paddingBottom + borderTop + borderBottom);

	-- ButtonElementDebug.Format("width = %s, height = %s, textWidth = %s, textHeight = %s, paddingLeft = %s, paddingRight = %s, paddingTop = %s, paddingBottom = %s", width, height, textWidth, textHeight, paddingLeft, paddingRight, paddingTop, paddingBottom);

    layout:SetWidthHeight(width, height);

	return true;  -- 返回true不执行子元素布局
end

-- 按钮渲染
function Button:RenderContent(painter, style)
	local layout = self:GetLayout();
	local x, y = layout:GetPos();
	local w, h = layout:GetWidthHeight();
	local text = self:GetValue();
	if(not text or text =="") then return end
	local paddingTop, paddingRight, paddingBottom, paddingLeft = style["padding-top"] or 0, style["padding-right"] or 0, style["padding-bottom"] or 0, style["padding-left"] or 0;
	local textWidth = _guihelper.GetTextWidth(text, style:GetFont());
	local textHeight = style:GetFontSize();
	local offsetLeft = (w - textWidth - paddingLeft - paddingRight) / 2;
	local offsetTop = (h - textHeight - paddingTop - paddingBottom) / 2 - textHeight / 6;  -- 后面减去的像素是根据实际效果调整的
	offsetLeft = offsetLeft > 0 and offsetLeft or 0;
	offsetTop = offsetTop > 0 and offsetTop or 0;
	x = x + paddingLeft + offsetLeft;
	y = y + paddingTop + offsetTop;
	painter:SetFont(style:GetFont());
	painter:SetPen(style:GetColor("#000000"));
	painter:DrawTextScaled(x, y, text);
end


