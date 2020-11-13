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

local TextDebug = GGS.Debug.GetModuleDebug("TextDebug").Disable();  -- Enable() Disable;

Text:Property("Value");  -- 文本值
Text:Property("Name", "Text");
Text:Property("BaseStyle", {
	NormalStyle = {
		["display"] = "inline",
	}
});

-- 处理实体字符
local function ReplaceEntityReference(value)
	value = string.gsub(value, "&nbsp;", " ");
	return value;
end

function Text:ctor()
end

-- public:
function Text:Init(xmlNode, window, parent)
	self:InitElement(xmlNode, window, parent);

	-- 处理实体字符
	self:SetValue(self:FormatText(self:GetInnerText()));

	return self;
end

function Text:FormatText(text)
	text = ReplaceEntityReference(text);

	local whiteSpace = self:GetStyle():GetWhiteSpace();

	text = string.gsub(text, "\r\n", "\n");
	if (whiteSpace == "pre") then
	else  -- normal
		text = string.gsub(text, "%s", " ");
	end

	return text;
end

function Text:SetText(value)
	local value = self:FormatText(value);
	if (value == self:GetValue()) then return end
	self:SetValue(value);
	self:UpdateLayout();
end

function Text:GetTextAlign()
	return self:GetStyle():GetTextAlign();
end

local function CalculateTextLayout(self, text, width, left, top)
	TextDebug.Format("CalculateTextLayout, text = %s, width = %s, left = %s, top = %s", text, width, left, top);
	if(not text or text =="") then return 0, 0 end

	local textWidth, textHeight = _guihelper.GetTextWidth(text, self:GetFont()), self:GetLineHeight();
	local remaining_text = nil;

	if(width and width > 0 and textWidth > width) then
		text, remaining_text = _guihelper.TrimUtf8TextByWidth(text, width, self:GetFont())
		textWidth = _guihelper.GetTextWidth(text, self:GetFont());
	end

	TextDebug.Format("text = %s, x = %s, y = %s, w = %s, h = %s", text, left, top, textWidth, textHeight);
	local textObject = {text = text, x = left, y = top, w = textWidth, h = textHeight};
	table.insert(self.texts, textObject);
	
	local textAlign = self:GetTextAlign();
	if(width and width > 0 and width > textWidth and textAlign) then
		if(textAlign == "right") then
			textObject.x = left + width - textWidth;
		elseif(textAlign == "center") then
			textObject.x = left + (width - textWidth) / 2;
		end
	end
	
	if (remaining_text and remaining_text ~= "") then
		local remainingWidth, remainingHeight = CalculateTextLayout(self, remaining_text, width, left, top + textHeight);
		textHeight = textHeight + remainingHeight;
	end

	return textWidth, textHeight;
end

function Text:OnUpdateLayout()
	local layout, style = self:GetLayout(), self:GetStyle();
	local parentLayout = self:GetParentElement():GetLayout();
	local parentContentWidth, parentContentHeight = parentLayout:GetContentWidthHeight();
	local width, height = layout:GetFixedWidthHeight();
	local left, top = 0, 0;
	local textWidth, textHeight = 0, 0;
	local text = self:GetValue();

	self.texts = {};

	-- TextDebug("OnBeforeUpdateChildElementLayout", width, parentContentWidth);
	if (style["text-wrap"] == "none") then
		--  不换行
		local textWidth, textHeight = _guihelper.GetTextWidth(text, self:GetFont()), self:GetLineHeight();
		local textObject = {text = text, x = 0, y = 0, w = textWidth, h = textHeight}
		table.insert(self.texts, textObject);
		height = height or textHeight;
		width = width or textWidth;
		if (width < textWidth) then
			if (style["text-overflow"] == "ellipsis") then
				textObject.text = _guihelper.AutoTrimTextByWidth(text, width - 16, self:GetFont()) .. "...";
			else
				textObject.text = _guihelper.AutoTrimTextByWidth(text, width, self:GetFont());
			end
			textObject.width = width;
		end
	else
		-- 自动换行
		local textlines = commonlib.split(text, "\n");
		for _, textline in ipairs(textlines) do
			local linewidth, lineheight = CalculateTextLayout(self, textline, width or parentContentWidth, left, top);
			textWidth = math.max(linewidth, textWidth);
			textHeight = textHeight + lineheight;
			top = top + lineheight;
		end
		-- TextDebug(text, self.texts);
	end

	-- TextDebug.Format("OnBeforeUpdateChildElementLayout, width = %s, height = %s", width, height);

	self:GetLayout():SetWidthHeight(width or textWidth, height or textHeight);
    return true; 
end

-- 绘制文本
function Text:OnRender(painter)
	local style, layout = self:GetStyle(), self:GetLayout();
	local fontSize = self:GetFontSize(14)
	local lineHeight = self:GetLineHeight();
	local linePadding = (lineHeight - fontSize) / 2 - fontSize / 6;
	local left, top = layout:GetPos();

	painter:SetFont(self:GetFont());
	painter:SetPen(self:GetColor("#000000"));

	for i = 1, #self.texts do
		local obj = self.texts[i];
		local x, y, text = left + obj.x, top + obj.y + linePadding, obj.text;
		painter:DrawText(x, y, text);
	end
end