--[[
Title: Element
Author(s): wxa
Date: 2020/6/30
Desc: 元素类
use the lib:
-------------------------------------------------------
local Element = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Element.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/Rect.lua");
NPL.load("(gl)script/ide/math/Point.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");
local Rect = commonlib.gettable("mathlib.Rect");
local Point = commonlib.gettable("mathlib.Point");

local Style = NPL.load("./style.lua", IsDevEnv);
local ElementBase = NPL.load("./ElementBase.lua", IsDevEnv);
local Element = commonlib.inherit(ElementBase, NPL.export());

local ElementDebug = GGS.Debug.GetModuleDebug("ElementDebug");

Element:Property("Window");     -- 元素所在窗口
Element:Property("Attr");       -- 元素属性
Element:Property("XmlNode");    -- 元素XmlNode
Element:Property("ParentElement");         -- 父元素
Element:Property("ChildrenElementList");   -- 子元素列表
Element:Property("ChildrenElementCount");  -- 子元素的个数
Element:Property("Style");      -- 样式
Element:Property("BaseStyle");  -- 默认样式, 基本样式
Element:Property("Rect");       -- 元素几何区域矩形
Element:Property("TagName");    -- 标签名


function Element:ctor()
    self:SetName("Element");
    self:SetChildrenElementList({});
    self:SetStyle({});
    self:SetRect(Rect:new():init(0,0,0,0));
end

function Element:Init(xmlNode, uiwindow)
    -- 设置窗口
    self:SetWindow(uiwindow);
    
    -- 文本节点直接转换格式
    if (type(xmlNode) ~= "table") then xmlNode = {name = "Text", attr = {value = tostring(xmlNode)}} end
    
    -- 设置元素属性
    self:SetTagName(xmlNode.name);
    self:SetAttr(xmlNode.attr);
    self:SetXmlNode(xmlNode);

    -- 创建子元素
    local children = self:GetChildrenElementList();
    for i, childXmlNode in ipairs(xmlNode) do
        if (type(childXmlNode) ~= "table") then 
            childXmlNode = {name = "Text", attr = {value = tostring(childXmlNode)}};
            xmlNode[i] = childXmlNode;
        end
        local PageElement = self:GetElementByTagName(childXmlNode.name);
        local childElement = PageElement:new():Init(childXmlNode, uiwindow);
        childElement:SetParentElement(self);
        children[i] = childElement;
    end
    -- 设置子元素的数量
    self:SetChildrenElementCount(#xmlNode);

    return self;
end

-- 获取元素
function Element:GetElementByTagName(tagname)
    return self:GetWindow():GetElementManager():GetElementByTagName(tagname);
end

-- 加载元素
function Element:LoadComponent(parentElement, parentLayout, parentStyle)
    ElementDebug("LoadComponent: " .. self:GetName());

    self:SetStyle(self:CreateStyle(self:GetBaseStyle(), parentStyle));

    self:OnLoadComponentBeforeChild(parentElement, parentLayout, self:GetStyle());

	self:OnLoadChildrenComponent(parentElement, parentLayout, self:GetStyle());
	
    self:OnLoadComponentAfterChild(parentElement, parentLayout, self:GetStyle());
    
    self:MergePseudoClassStyle(); -- 合并伪类样式
end

-- 子元素加载前
function Element:OnLoadComponentBeforeChild(parentElement, parentLayout, style)
end

-- 加载子元素
function Element:OnLoadChildrenComponent(parentElement, parentLayout, style)
    for childElement in self:ChildrenElementIterator() do
        childElement:LoadComponent(parentElement, parentElement, style);
    end
end

-- 子元素加载后
function Element:OnLoadComponentAfterChild(parentElement, parentLayout, style)
end

-- 创建样式
function Element:CreateStyle(baseStyle, inheritStyle)
    local style = Style:new():Init(baseStyle);
    
    -- inherit style
    style:MergeInheritable(inheritStyle);
    -- class style

    -- inline style
    style:AddString(self:GetAttrValue("style"));

    return style;
end

-- 合并伪类样式
function Element:MergePseudoClassStyle()
    local style = self:GetStyle();
    local activeStyle, hoverStyle = style:GetActiveStyle(), style:GetHoverStyle();
    activeStyle:Merge(style);
    hoverStyle:Merge(style);
end

-- 获取当前样式
function Element:GetCurrentStyle()
    local style = self:GetStyle();
    local activeStyle, hoverStyle = style:GetActiveStyle(), style:GetHoverStyle();
    if (self:IsHover()) then return hoverStyle end
    if (self:IsActive()) then return activeStyle end
    return style;
end

-- -- 应用样式
-- function UIElement:ApplyStyle(style)
-- 	if(style["background-color"]) then self:SetBackgroundColor(style["background-color"]) end	
-- 	if(style.background) then
-- 		local wnd = self:GetWindow()
-- 		if(wnd) then
-- 			self:SetBackground(wnd:FilterImage(style.background));
-- 		else
-- 			self:SetBackground(style.background);
-- 		end
-- 	end
-- 	if(style.transform) then self.transform = {rotate = style.transform.rotate, scale = style.transform.scale, origin = style["transform-origin"]} end
-- 	if(style["background-animation"]) then
-- 		local anim_file = string.gsub(style["background-animation"], "url%((.*)%)", "%1");
-- 		local fileName,animName = string.match(anim_file, "^([^#]+)#(.*)$");
-- 		if(fileName and animName) then
-- 			NPL.load("(gl)script/ide/UIAnim/UIAnimManagerEx.lua");
-- 			UIAnimManagerEx.PlayUIAnimationSequence(self, fileName, animName, true);
-- 		end
-- 	end
-- end

-- 获取属性值
function Element:GetAttrValue(attrName, defaultValue)
    local attr = self:GetAttr();
    if (not attr) then return defaultValue end
    return attr[attrName] or defaultValue;
end

-- 遍历
function Element:ChildrenElementIterator()
    local i, size, children = 0, self:GetChildrenElementCount() or 0, self:GetChildrenElementList();
    return function() 
        i = i + 1;
        if (i > size) then return end
        return children[i];
    end
end


