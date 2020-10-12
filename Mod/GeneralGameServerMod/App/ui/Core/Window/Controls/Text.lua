--[[
Title: Text
Author(s): wxa
Date: 2020/8/14
Desc: 文本
-------------------------------------------------------
local Text = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Controls/Text.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua", IsDevEnv);

local Text = commonlib.inherit(Element, NPL.export());

local TextElementDebug = GGS.Debug.GetModuleDebug("TextElementDebug").Disable();

Text:Property("Value");  -- 文本值

Text:Property("BaseStyle", {
	NormalStyle = {
		["display"] = "inline",
		["width"] = "100%",
		["color"] = "#000000",
	}
});

-- 处理实体字符
local function ReplaceEntityReference(value)
	value = string.gsub(value, "&nbsp;", " ");
	return value;
end

function Text:ctor()
	self:SetName("Text");
end

-- public:
function Text:Init(xmlNode, window)
	self:InitElement(xmlNode, window);

	local value = (type(xmlNode) == "string" or type(xmlNode) == "number") and tostring(xmlNode) or (xmlNode and xmlNode.attr and xmlNode.attr.value);
	
	if (type(xmlNode) == "table") then
		self:SetAttr(xmlNode.attr);
	end

	if (not value and type(xmlNode) == "table") then
		for i = 1, #xmlNode do
			if (type(xmlNode[i]) == "string" or type(xmlNode[i] == "number")) then
				value = tostring(xmlNode[i]);
				break;
			end
		end
	end

	-- TextElementDebug("Init Value:" .. tostring(value), xmlNode);
	-- 处理实体字符
	self:SetValue(ReplaceEntityReference(value));

	return self;
end

function Text:SetText(value)
	local value = ReplaceEntityReference(value);
	if (value == self:GetValue()) then return end
	self:SetValue(value);
	self:UpdateLayout();
end

local function CalculateTextLayout(self, text, width, left, top)
	TextElementDebug.Format("CalculateTextLayout, text = %s, width = %s, left = %s, top = %s", text, width, left, top);
	if(not text or text =="") then return 0, 0 end

	local style = self:GetStyle();
	local textWidth, textHeight = _guihelper.GetTextWidth(text, self:GetFont()), style:GetLineHeight();
	local remaining_text = nil;

	if(width and width > 0 and textWidth > width) then
		text, remaining_text = _guihelper.TrimUtf8TextByWidth(text, width, self:GetFont())
		textWidth = _guihelper.GetTextWidth(text, self:GetFont());
	end

	TextElementDebug.Format("text = %s, x = %s, y = %s, w = %s, h = %s", text, left, top, textWidth, textHeight);
	table.insert(self.texts, {text = text, x = left, y = top, w = textWidth, h = textHeight});
		
	if(style and width and width > 0 and width > textWidth) then
		if(style["text-align"]) then
			if(style["text-align"] == "right") then
				_this:setX(left + width - textWidth);
			elseif(style["text-align"] == "center") then
				_this:setX(left + (width - textWidth) / 2);
			end
		end
	end
	
	if (remaining_text and remaining_text ~= "") then
		local remainingWidth, remainingHeight = CalculateTextLayout(self, remaining_text, width, left, top + textHeight);
		textHeight = textHeight + remainingHeight;
	end

	return textWidth, textHeight;
end

function Text:OnUpdateLayout()
	local layout = self:GetLayout();
	local width, height = layout:GetWidthHeight();
	local left, top = 0, 0;

	self.texts = {};

	width, height = CalculateTextLayout(self, self:GetValue(), width, left, top);

	TextElementDebug.Format("OnBeforeUpdateChildElementLayout, width = %s, height = %s", width, height);

	self:GetLayout():SetWidthHeight(width, height);

    return true; 
end

-- 绘制文本
function Text:OnRender(painter)
	local style, layout = self:GetStyle(), self:GetLayout();
	local fontSize, lineHeight = style:GetFontSize(), style:GetLineHeight();
	local linePadding = (lineHeight - fontSize) / 2 - fontSize / 6;
	local left, top = layout:GetPos();

	painter:SetFont(style:GetFont());
	painter:SetPen(style:GetColor());

	for i = 1, #self.texts do
		local obj = self.texts[i];
		local x, y, text = left + obj.x, top + obj.y + linePadding, obj.text;
		painter:DrawText(x, y, text);
	end
end