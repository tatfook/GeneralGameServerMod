--[[
Title: Text
Author(s): wxa
Date: 2020/8/14
Desc: 文本
-------------------------------------------------------
local Text = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/Text.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/Controls/Label.lua");
local Label = commonlib.gettable("System.Windows.Controls.Label");

local Element = NPL.load("../Element.lua", IsDevEnv);

local Text = commonlib.inherit(Element, NPL.export());

Text:Property({"value", nil, "GetValue", "SetValue"})

function Text:ctor()
end

-- public:
function Text:createFromXmlNode(xmlNode)
	local value = (type(xmlNode) == "string" or type(xmlNode) == "number") and tostring(xmlNode) or nil;
	return self:new({name="Text", value = value});
end

function Text:clone()
	local o = Text._super.clone(self)
	o.value = self.value;
	return o;
end

function Text:GetTextTrimmed()
	local value = self.value or self:GetAttributeWithCode("value", nil, true);
	if(value) then
		value = string.gsub(value, "nbsp;", "");
		value = string.gsub(value, "^[%s]+", "");
		value = string.gsub(value, "[%s]+$", "");
	end
	return value;
end

function Text:LoadComponent(parentElem, parentLayout, style)
	local css = self:CreateStyle(mcml:GetStyleItem(self.class_name), style);
	css["text-align"] = css["text-align"] or "left";

	self.value = self:GetTextTrimmed();

	if(not self.value or self.value=="") then return end

	self:EnableSelfPaint(parentElem);

	local font, font_size, scale = css:GetFontSettings();
	local line_padding = 2;
	
	if(css["line-height"]) then
		local line_height = css["line-height"];
		local line_height_percent = line_height:match("(%d+)%%");
		if(line_height_percent) then
			line_height_percent = tonumber(line_height_percent);
			line_padding = math.ceil((line_height_percent*font_size*0.01-font_size)*0.5);
		else
			line_height = line_height:match("(%d+)");
			line_height = tonumber(line_height);
			if(line_height) then
				line_padding = math.ceil((line_height-font_size)*0.5);
			end
		end
	end
	self.font = font;
	self.font_size = font_size;
	self.scale = scale;
	self.line_padding = line_padding;
	self.textflow = css.textflow;
end

local function CalculateTextLayout(self, text, width, left, top)
	if(not text or text =="") then return 0, 0 end

	-- font-family: Arial; font-size: 14pt;font-weight: bold; 
	local scale, font_size, line_padding = self.scale, self.font_size or 14, self.line_padding or 2;
	local textWidth, textHeight = _guihelper.GetTextWidth(text, self.font), font_size;
	local remaining_text = nil;

	if(width and width > 0 and textWidth > width) then
		text, remaining_text = _guihelper.TrimUtf8TextByWidth(text, width, self.font)
		textWidth = _guihelper.GetTextWidth(text, self.font);
	end

	if(scale) then
		textWidth = textWidth * scale;
		textHeight = textHeight * scale;
	end	

	textHeight = textHeight + line_padding + line_padding;

	local _this = Label:new():init();
	_this:SetText(text);
	_this:setGeometry(left, top, textWidth, textHeight);
	self.labels:add(_this);

	local css = self:GetStyle();
	if(css and width and width > 0 and width > textWidth) then
		if(css["text-align"]) then
			if(css["text-align"] == "right") then
				_this:setX(left + width - textWidth);
			elseif(css["text-align"] == "center") then
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

	self.labels = commonlib.Array:new();

	local width, height = CalculateTextLayout(self, self:GetTextTrimmed(), parentWidth, left, top);

	elementLayout:SetWidthHeight(width, height);

    return true; 
end

-- virtual function: 
function Text:paintEvent(painter)
	if(self.labels) then
		local css = self:GetStyle();
		local be_shadow,shadow_offset_x,shadow_offset_y,shadow_color = css:GetTextShadow();
		painter:SetFont(self.font);
		painter:SetPen(css.color or "#000000");
		local textAlignment = css:GetTextAlignment();
		for i = 1, #self.labels do
			local label = self.labels[i];
			if(label) then
				local x = label.crect:x();
				local y = label.crect:y()+self.line_padding;
				local w = label.crect:width();
				local h = label.crect:height()-self.line_padding-self.line_padding;
				local text = label:GetText();

				if(be_shadow) then
					painter:SetPen(shadow_color);
					painter:DrawTextScaledEx(x + shadow_offset_x, y + shadow_offset_y, w, h, text, textAlignment, self.scale);
					painter:SetPen(css.color or "#000000");
				end

				painter:DrawTextScaledEx(x, y, w, h, text, textAlignment, self.scale);
			end
		end
	end
end