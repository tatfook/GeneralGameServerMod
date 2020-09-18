--[[
Title: Text
Author(s): wxa
Date: 2020/8/14
Desc: 文本
-------------------------------------------------------
local Text = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/Text.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua", IsDevEnv);

local Text = commonlib.inherit(Element, NPL.export());

local TextElementDebug = GGS.Debug.GetModuleDebug("TextElementDebug");

Text:Property("Value");  -- 文本值

function Text:ctor()
	self:SetName("Text");
end

-- public:
function Text:Init(xmlNode)
	local value = (type(xmlNode) == "string" or type(xmlNode) == "number") and tostring(xmlNode) or (xmlNode and xmlNode.attr and xmlNode.attr.value);

	-- TextElementDebug("Init Value:" .. tostring(value), xmlNode);

	self:SetValue(self:GetTextTrimmed(value));

	return self;
end

function Text:GetTextTrimmed(value)
	value = value or self:GetValue() or self:GetAttrValue("value", nil);
	if(value) then
		value = string.gsub(value, "nbsp;", "");
		value = string.gsub(value, "^[%s]+", "");
		value = string.gsub(value, "[%s]+$", "");
	end
	return value;
end

local function CalculateTextLayout(self, text, width, left, top)
	TextElementDebug.Format("CalculateTextLayout, text = %s, width = %s, left = %s, top = %s", text, width, left, top);
	if(not text or text =="") then return 0, 0 end

	local style = self:GetStyle();
	local textWidth, textHeight = _guihelper.GetTextWidth(text, self.font), style:GetLineHeight();
	local remaining_text = nil;

	if(width and width > 0 and textWidth > width) then
		text, remaining_text = _guihelper.TrimUtf8TextByWidth(text, width, self.font)
		textWidth = _guihelper.GetTextWidth(text, self.font);
	end

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

function Text:OnBeforeUpdateChildElementLayout(elementLayout, parentElementLayout)
	local parentWidth, parentHeight = parentElementLayout:GetWidthHeight();
	local left, top = elementLayout:GetPos();

	self.texts = {};

	local width, height = CalculateTextLayout(self, self:GetValue(), parentWidth, left, top);

	TextElementDebug.Format("OnBeforeUpdateChildElementLayout, width = %s, height = %s", width, height);

	elementLayout:SetWidthHeight(width, height);

    return true; 
end

-- 绘制文本
function Text:OnRender(painter)
	local style = self:GetStyle();
	local fontSize, lineHeight = style:GetFontSize(), style:GetLineHeight();
	local linePadding = (lineHeight - fontSize) / 2;

	painter:SetFont(style:GetFont());
	painter:SetPen(style:GetColor("#000000"));

	for i = 1, #self.texts do
		local obj = self.texts[i];
		local x, y, text = obj.x, obj.y + linePadding, obj.text;
		painter:DrawText(x, y, text);
	end
end