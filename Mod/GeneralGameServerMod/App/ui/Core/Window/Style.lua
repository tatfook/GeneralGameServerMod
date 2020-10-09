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

local pseudo_class_fields = {
	["RawStyle"] = true,
	["NormalStyle"] = true,
	["ActiveStyle"] = true,
	["HoverStyle"] = true,
}
-- 拷贝样式
local function CopyStyle(dst, src)
	if (type(src) ~= "table") then return dst end
	for key, value in pairs(src) do
		if (not pseudo_class_fields[key]) then
			dst[string.lower(key)] = Style.GetStyleValue(key, value);
		end
	end
	return dst;
end

-- 布局字段
local layout_fields = {
	["width"] = true,
	["height"] = true,
	["max-width"] = true,
	["max-height"] = true,
	["min-width"] = true,
	["min-height"] = true,
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
	["border-size"] = true,
	["border-left-size"] = true,
	["border-right-size"] = true,
	["border-top-size"] = true,
	["border-bottom-size"] = true,
	["left"] = true,
	["top"] = true,
	["right"] = true,
	["bottom"] = true,

	["float"] = true,
	["position"] = true,
	["box-sizing"] = true,
}

-- 是否需要重新布局
local function IsRefreshLayout(style)
	if (type(style) ~= "table") then return false end
	for key, val in pairs(style) do
		if (layout_fields[key]) then
			return true;
		end
	end
	return false;
end

function Style:ctor()
	self.RawStyle = {};             -- 原始样式
	self.NormalStyle = {};          -- 普通样式

	-- 伪类样式
	self.ActiveStyle = {};          -- 激活样式
	self.HoverStyle = {};           -- 鼠标悬浮样式
	self.FocusStyle = {};           -- 聚焦样式
end

function Style:Init(style)
    self:Merge(style);
    return self;
end

-- 是否需要刷新布局
function Style:IsNeedRefreshLayout(style)
	return IsRefreshLayout(style);
end

-- 选择默认样式
function Style:SelectNormalStyle()
	return CopyStyle(self, self.NormalStyle);
end

-- 选择激活样式
function Style:SelectActiveStyle()
	return CopyStyle(self, self.ActiveStyle);
end

-- 选择悬浮样式
function Style:SelectHoverStyle()
	return CopyStyle(self, self.HoverStyle);
end

-- 选择聚焦样式
function Style:SelectFocusStyle()
	return CopyStyle(self, self.FocusStyle);
end

-- 选择默认样式
function Style:GetNormalStyle()
	return self.NormalStyle;
end

-- 选择激活样式
function Style:GetActiveStyle()
	return self.ActiveStyle;
end

-- 选择悬浮样式
function Style:GetHoverStyle()
	return self.HoverStyle;
end

-- 选择聚焦样式
function Style:GetFocusStyle()
	return self.FocusStyle;
end

-- 合并样式
function Style:Merge(style)			
    if(type(style) ~= "table") then return end 

	CopyStyle(self, style);                              -- 计算样式
	CopyStyle(self.RawStyle, style.RawStyle);
	CopyStyle(self.NormalStyle, style.NormalStyle);
	CopyStyle(self.ActiveStyle, style.ActiveStyle);
	CopyStyle(self.HoverStyle, style.HoverStyle);
	
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
        self.NormalStyle[field] = self.NormalStyle[field] or style[field];
    end
end

local dimension_fields = {
	["height"] = true, ["min-height"] = true, ["max-height"] = true,
	["width"] = true, ["min-width"] = true, ["max-width"] = true,
	["left"] = true, ["top"] = true, ["right"] = true, ["bottom"] = true,
	["padding"] = true, ["padding-top"] = true, ["padding-right"] = true, ["padding-bottom"] = true, ["padding-left"] = true, 
	["margin"] = true, ["margin-top"] = true, ["margin-right"] = true, ["margin-bottom"] = true, ["margin-left"] = true, 
	["border-width"] = true, ["border-top-wdith"] = true, ["border-right-wdith"] = true, ["border-bottom-wdith"] = true, ["border-left-wdith"] = true, 

	["spacing"] = true,
	["shadow-quality"] = true,
	["text-shadow-offset-x"] = true,
	["text-shadow-offset-y"] = true,
}

local number_fields = {
	["border-top-width"] = true, ["border-right-width"] = true, ["border-bottom-width"] = true, ["border-left-width"] = true, ["border-width"] = true,
	["outline-width"] = true, 

	["font-size"] = true, ["base-font-size"] = true,
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

local image_fields = {
	["background"] = true,
	["background-image"] = true,
}

local transform_fields = {
	["transform"] = true,
	["transform-origin"] = true,
};

function Style.IsPx(value)
	return string.match(value or "", "^[%+%-]?%d+px$");
end

function Style.GetPxValue(value)
	if (type(value) ~= "string") then return value end
	return tonumber(string.match(value, "[%+%-]?%d+"));
end

function Style.IsNumber(value)
	return string.match(value or "", "[%+%-]?%d+%.?%d*$");
end

function Style.GetNumberValue(value)
	return tonumber(value);
end

function Style.GetStyleValue(name,value)
	if (type(name) ~= "string") then return end
	if (type(value) == "number" and (dimension_fields[name] or number_fields[name])) then return value end
	if (type(value) ~= "string") then return end
	
	name = string_lower(name);
	value = string_gsub(value, "%s*$", "");
    if(dimension_fields[name]) then
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
	elseif(image_fields[name]) then
		value = string_gsub(value, "url%((.*)%)", "%1");
		value = string_gsub(value, "#", ";");
	end
	return value;
end

-- 缩写字段
local complex_fields = {
	["border"] = "border-width border-style border-color",
	["border-width"] = "border-top-width border-right-width border-bottom-width border-left-width",
    ["padding"] = "padding-top padding-right padding-left padding-bottom",
	["margin"] = "margin-top margin-right margin-left margin-bottom",
	["overflow"] = "overflow-x, overflow-y",
};


local function AddStyleItem(style, name, value)
	value = Style.GetStyleValue(name, value);
	if (not value) then return end
	style[string.lower(name)] = value;
	-- self.NormalStyle[string.lower(name)] = value;
end

local function AddComplexStyleItem(style, name, value)
	local names = commonlib.split(complex_fields[name], "%s");
    local values = commonlib.split(value, "%s");
    
    if (name == "padding" or name == "margin" or name == "border-width") then
		values[1] = values[1] or 0;
		values[4] = values[4] or values[2] or values[1];
        values[3] = values[3] or values[1];
		values[2] = values[2] or values[1];
	elseif (name == "border") then
		values[1] = values[1] or 0;
		values[2] = values[2] or "solid";
		values[3] = values[3] or "#000000";
	elseif (name == "overflow") then
		values[1] = values[1] or "hidden";
		values[2] = values[2] or values[1];
    end
    
    for i = 1, #names do
		AddStyleItem(style, names[i], values[i]);
	end
end


function Style.ParseString(style_code)
	local style, name, value = {};
	for name, value in string.gfind(style_code or "", "([%w%-]+)%s*:%s*([^;]*)[;]?") do
		name = string_lower(name);
		value = string_gsub(value, "%s*$", "");
		if(complex_fields[name]) then
			AddComplexStyleItem(style, name, value);
		else
			AddStyleItem(style, name, value);
		end
	end
	return style;
end

-- 添加样式代码: mcml style attribute string like "background:url();margin:10px;"
function Style:AddString(style_code)
	local style = Style.ParseString(style_code);
	for key, val in pairs(style) do
		self.NormalStyle[key] = val;
	end
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
