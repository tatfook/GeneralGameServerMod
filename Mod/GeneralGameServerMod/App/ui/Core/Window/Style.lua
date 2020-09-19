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

-- 伪类字段
local pseudo_class_fields = {
	["active"] = true,
	["hover"] = true,
}

function Style:ctor()
	self.RawStyle = {};             -- 原始样式
end

function Style:Init(style)
    self:Merge(style);

	-- 伪类样式
	self.ActiveStyle = Style:new();  -- 激活样式
	self.HoverStyle = Style:new();   -- 鼠标悬浮样式

	-- 合并伪类样式
	if (type(style) == "table") then
		self.ActiveStyle:Merge(style.ActiveStyle);
		self.HoverStyle:Merge(style.HoverStyle);
	end
	
    return self;
end

-- 获取激活样式
function Style:GetActiveStyle()
	return self.ActiveStyle;
end

-- 获取悬浮样式
function Style:GetHoverStyle()
	return self.HoverStyle;
end

-- 合并样式
function Style:Merge(style)			
    if(type(style) ~= "table") then return end 
    
	for key, value in pairs(style) do
		key = string.lower(key);
		if (not pseudo_class_fields[key]) then
			self[key] = value;
		end
    end
    
    return self;
end


-- 继承字段
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

local dimension_fields = {
	["height"] = true,
	["min-height"] = true,
	["max-height"] = true,
	["width"] = true,
	["min-width"] = true,
	["max-width"] = true,
	["left"] = true,
	["top"] = true,
	["spacing"] = true,
	
	["shadow-quality"] = true,
	["text-shadow-offset-x"] = true,
	["text-shadow-offset-y"] = true,
}

local number_fields = {
	["border-top-width"] = true,
	["border-right-width"] = true,
	["border-bottom-width"] = true,
	["border-left-width"] = true,
	["border-width"] = true,
	["outline-width"] = true, 

	["font-size"] = true,
	["base-font-size"] = true,
	["z-index"] = true,
	["scale"] = true,
};

local color_fields = {
	["color"] = true,
	["border-color"] = true,
	["outline-color"] = true,
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

function Style.IsPx(value)
	return string.match(value or "", "^[%+%-]?%d+px$");
end

function Style.GetPxValue(value)
	return tonumber(string.match(value or "", "^([%+%-]?%d+)px$"));
end

function Style.IsNumber(value)
	return string.match(value or "", "[%+%-]?%d+%.?%d*$");
end

function Style.GetNumberValue(value)
	return tonumber(value);
end

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
    if(dimension_fields[name] or string_find(name,"^margin") or string_find(name,"^padding")) then
		local isPercentage = string.match(value, "^[%+%-]?%d+%%$");
		if (string.match(value, "^[%+%-]?%d+px$")) then   -- 像素值
			value = tonumber(string.match(value, "^([%+%-]?%d+)px$"));
		elseif (string.match(value, "^[%+%-]?%d+%%$")) then  -- 百分比
			value = value;
		else 
			value = tonumber(value);
		end
	elseif (number_fields[name]) then
		value = tonumber(string.match(value, "[%+%-]?%d+"));
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

-- 获取字体
function Style:GetFont()
	return string.format("%s;%d;%s", self:GetFontFamily(), self:GetFontSize(), self:GetFontWeight());
end

function Style:GetFontFamily(defaultValue)
	return self["font-family"] or defaultValue or "System";
end

function Style:GetFontWeight(defaultValue)
	return self["font-weight"] or defaultValue or "norm";
end

function Style:GetFontSize(defaultValue)
	return self["font-size"] or defaultValue or 14;
end

function Style:GetScale(defaultValue)
	return self.scale or (self["font-size"] and self["base-font-size"] and self["font-size"] / self["base-font-size"]) or defaultValue;
end

function Style:GetColor(defaultValue)
	return self.color or defaultValue;
end

function Style:GetBackgroundColor(defaultValue)
	return self["background-color"] or defaultValue;
end

function Style:GetBackground(defaultValue)
	return self["background"] or defaultValue;
end

function Style:GetLineHeight(defaultValue)
	local lineHeight = self["line-height"];
	if (type(lineHeight) == "number") then return lineHeight end

	if (self.IsPx(lineHeight)) then 
		lineHeight = self.GetPxValue(lineHeight);
	elseif (self.IsNumber(lineHeight)) then 
		lineHeight = math.floor(self.GetNumberValue(lineHeight) * self:GetFontSize());
	else
		lineHeight = defaultValue or math.floor(1.4 * self:GetFontSize());
	end

	self["line-height"] = lineHeight;

	return lineHeight; 
end

function Style:GetOutlineWidth(defaultValue)
	return self["outline-width"] or defaultValue;
end

function Style:GetOutlineColor(defaultValue)
	return self["outline-color"] or defaultValue;
end
