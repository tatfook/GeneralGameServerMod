--[[
Title: Style
Author(s): wxa
Date: 2020/6/30
Desc: 样式类
use the lib:
-------------------------------------------------------
local Style = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Style.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/LocalCache.lua");
local LocalCache = commonlib.gettable("System.Windows.mcml.LocalCache");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");

local type = type;
local tonumber = tonumber;
local string_gsub = string.gsub;
local string_lower = string.lower
local string_match = string.match;
local string_find = string.find;

local Style = commonlib.inherit(nil, NPL.export());

local remoteTextrue = {};

function Style:ctor()
end

function Style:Init(style)
    self:Merge(style);

    return self;
end

function Style:Merge(style)
    if(type(style) ~= "table") then return end 
    
    for key, value in pairs(style) do
        self[key] = value;
    end
    
    return self;
end

local inheritable_fields = {
	["color"] = true,
	["font-family"] = true,
	["font-size"] = true,
	["font-weight"] = true,
	["text-shadow"] = true,
	["shadow-color"] = true,
	["text-shadow-offset-x"] = true,
	["text-shadow-offset-y"] = true,
	["text-align"] = true,
	["line-height"] = true,
	["caret-color"] = true,
	["text-singleline"] = true,
	["base-font-size"] = true,
};

-- only merge inheritable style like font, color, etc. 
function Style:MergeInheritable(style)
    if(type(style) ~= "table") then return end 

    for field, _ in pairs(inheritable_fields) do
        self[field] = self[field] or style[field];
    end
end

local reset_fields = 
{
	["height"] = true,
	["min-height"] = true,
	["max-height"] = true,
	["width"] = true,
	["min-width"] = true,
	["max-width"] = true,
	["left"] = true,
	["top"] = true,

	["margin"] = true,
	["margin-left"] = true,
	["margin-top"] = true,
	["margin-right"] = true,
	["margin-bottom"] = true,

	["padding"] = true,
	["padding-left"] = true,
	["padding-top"] = true,
	["padding-right"] = true,
	["padding-bottom"] = true,
}

local number_fields = {
	["height"] = true,
	["min-height"] = true,
	["max-height"] = true,
	["width"] = true,
	["min-width"] = true,
	["max-width"] = true,
	["left"] = true,
	["top"] = true,
	["font-size"] = true,
	["spacing"] = true,
	["base-font-size"] = true,
	["border-width"] = true,
	["shadow-quality"] = true,
	["text-shadow-offset-x"] = true,
	["text-shadow-offset-y"] = true,
};

local color_fields = {
	["color"] = true,
	["border-color"] = true,
	["background-color"] = true,
	["shadow-color"] = true,
	["caret-color"] = true,
};

local image_fields = 
{
	["background"] = true,
	["background2"] = true,
	["background-image"] = true,
}
-- these fields are made up of the other simple fields.
local complex_fields = {
    ["border"] = "border-width border-style border-color",
    ["padding"] = "padding-top padding-right padding-left padding-bottom",
    ["margin"] = "margin-top margin-right margin-left margin-bottom",
};

local transform_fields = {
	["transform"] = true,
	["transform-origin"] = true,
};

function Style.isResetField(name)
	return reset_fields[name];
end

-- @param style_code: mcml style attribute string like "background:url();margin:10px;"
function Style:AddString(style_code)
	local name, value;
	for name, value in string.gfind(style_code or "", "([%w%-]+)%s*:%s*([^;]*)[;]?") do
		name = string_lower(name);
		value = string_gsub(value, "%s*$", "");
		if(complex_fields[name]) then
			self:AddComplexField(name, value);
		else
			self:AddItem(name,value);
		end
	end
end

function Style:AddComplexField(name, value)
	local names = commonlib.split(complex_fields[name], "%s");
    local values = commonlib.split(value, "%s");
    
    if (name == "padding" or name == "margin") then
        values[4] = values[4] or values[2] or values[1];
        values[3] = values[3] or values[1];
        values[2] = values[2] or values[1];
    end
    
    for i = 1, #names do
		self:AddItem(names[i], values[i]);
	end
end

function Style:AddItem(name,value)
	if(not name or not value) then
		return;
	end
	name = string_lower(name);
	value = string_gsub(value, "%s*$", "");
    if(number_fields[name] or string_find(name,"^margin") or string_find(name,"^padding")) then
        local isPercentage = string.match(value, "^[%+%-]?%d+%%$");
        if (not isPercentage) then
            local _, _, selfvalue = string_find(value, "([%+%-]?%d+)");
            value = tonumber(selfvalue);
        end
	elseif(color_fields[name]) then
		value = StyleColor.ConvertTo16(value);
	elseif(transform_fields[name]) then
		if(name == "transform") then
			local transform = self.transform
			local degree = value:match("^%s*rotate%(%s*(%-?%d+)")
			if(degree) then
				transform = transform or {};
				transform.rotate = tonumber(degree);
			else
				local scaleX, scaleY = value:match("^%s*scale%(%s*(%d+)[%s,]*(%d+)")
				if(scaleX and scaleY) then
					transform = transform or {};
					transform.scale = {tonumber(scaleX), tonumber(scaleY)};
				end
			end
			value = transform;
		elseif(name == "transform-origin") then
			local values = {}
			for v in value:gmatch("%-?%d+") do
				values[#values+1] = tonumber(v);
			end
			if(values[1]) then
				values[2] = values[2] or 0;
				value = values;
			else
				value = nil;
			end
		end
	elseif(string_match(name, "^background[2]?$") or name == "background-image") then
		value = string_gsub(value, "url%((.*)%)", "%1");
		value = string_gsub(value, "#", ";");
	end
	self[name] = value;
end

-- the user may special many font size, however, some font size is simulated with a base font and scaling. 
-- @return font, base_font_size, font_scaling: font may be nil if not specified. font_size is the base font size.
function Style:GetFontSettings()
	local font;
	local scale;
	local font_size = 12;
	if(self["font-family"] or self["font-size"] or self["font-weight"])then
		local font_family = self["font-family"] or "System";
		-- this is tricky. we convert font size to integer, and we will use scale if font size is either too big or too small. 
		font_size = math.floor(tonumber(self["font-size"] or 12));

		if(self["base-font-size"]) then
			local baseFontSize = tonumber(self["base-font-size"]) or 12;
			if(font_size>baseFontSize) then
				scale = font_size / baseFontSize;
				font_size = baseFontSize;
			end
			if(font_size<baseFontSize) then
				scale = font_size / baseFontSize;
				font_size = baseFontSize;
			end			
		end

		local font_weight = self["font-weight"] or "norm";
		font = string.format("%s;%d;%s", font_family, font_size, font_weight);
	else
		font = string.format("%s;%d;%s", "System", font_size, "norm");
	end
	return font, font_size, scale;
end

function Style:TextShadow()
	return self["text-shadow"] or false;
end

function Style:TextShadowOffsetX()
	return self["text-shadow-offset-x"] or 1;
end

function Style:TextShadowOffsetY()
	return self["text-shadow-offset-y"] or 1;
end

function Style:TextShadowColor()
	return self["shadow-color"] or "#00000088";
end

function Style:GetTextShadow()
	return self:TextShadow(), self:TextShadowOffsetX(), self:TextShadowOffsetY(), self:TextShadowColor();
end

function Style:GetTextAlignment(defaultAlignment)
	local alignment = defaultAlignment or 1;	-- center align
	if(self["text-align"]) then
		if(self["text-align"] == "right") then
			alignment = 2;
		elseif(self["text-align"] == "left") then
			alignment = 0;
		end
	end
	if(self["text-singleline"] ~= "false") then
		alignment = alignment + 32;
	else
		if(self["text-wordbreak"] == "true") then
			alignment = alignment + 16;
		end
	end
	if(self["text-noclip"] ~= "false") then
		alignment = alignment + 256;
	end
	if(self["text-valign"] ~= "top") then
		alignment = alignment + 4;
	end
	return alignment;
end