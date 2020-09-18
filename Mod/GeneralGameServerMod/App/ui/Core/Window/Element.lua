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
local Element = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local ElementDebug = GGS.Debug.GetModuleDebug("ElementDebug");

Element:Property("Window");     -- 元素所在窗口
Element:Property("Attr");       -- 元素属性
Element:Property("XmlNode");    -- 元素XmlNode
Element:Property("ParentElement");         -- 父元素
Element:Property("ChildrenElementList");   -- 子元素列表
Element:Property("ChildrenElementCount");  -- 子元素的个数
Element:Property("Control");    -- 控件
Element:Property("Style");      -- 样式
Element:Property("Rect");       -- 元素区域矩形
Element:Property("TagName");    -- 标签名

Element:Property("BackgroundColor");  -- 背景颜色

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

    self:SetStyle(self:CreateStyle(nil, parentStyle));

    self:OnLoadComponentBeforeChild(parentElement, parentLayout, self:GetStyle());

	self:OnLoadChildrenComponent(parentElement, parentLayout, self:GetStyle());
	
	self:OnLoadComponentAfterChild(parentElement, parentLayout, self:GetStyle());
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

-- 是否需要
function Element:IsRender()
    local style = self:GetStyle();
    if (self.isRender or not style or style.display == "none" or style.visibility == "hidden" or self:GetWidth() == 0 or self:GetHeight() == 0) then return true end
    return false;
end

-- 元素渲染
function Element:Render(painterContext)
	if (self:IsRender()) then return end

    self.isRender = true;  -- 设置渲染标识 避免递归渲染
    -- if(self.transform) then self:applyRenderTransform(painterContext, self.transform) end

    self:OnRender(painterContext);  -- 渲染元素

    self.isRender = false; -- 清除渲染标识

    -- 渲染子元素
    painterContext:Translate(self:GetX(), self:GetY());
    for childElement in self:ChildrenElementIterator() do
        childElement:Render(painterContext);
    end
    painterContext:Translate(-self:GetX(), -self:GetY());

	-- if(self.transform) then painterContext:Restore() end
end

-- 绘制元素
function Element:OnRender(painter)
    local style = self:GetStyle();
    local background, backgroundColor = style:GetBackground(), style:GetBackgroundColor("#ffffff");
    local x, y, w, h = self:GetGeometry();

	painter:SetPen(backgroundColor);
	painter:DrawRectTexture(x, y, w, h, background);
end

-- 元素布局完成
-- function Element:OnAfterUpdateElementLayout(elementLayout, parentElementLayout)

-- end

-- 元素位置
function Element:SetGeometry(x, y, w, h)
    self:GetRect():setRect(x, y, w, h);
end

function Element:GetGeometry()
    return self:GetRect():getRect();
end

function Element:GetX()
	return self:GetRect():x();
end

function Element:GetY()
	return self:GetRect():y();
end

function Element:SetX(x)
	self:GetRect():setX(x);
end

function Element:SetY(y)
	self:GetRect():setY(y);
end

function Element:GetWidth()
	return self:GetRect():width();
end

function Element:GetHeight()
	return self:GetRect():height();
end

function Element:SetWidth(w)
    self:GetRect():setWidth(w);
end

function Element:SetHeight(h)
    self:GetRect():setHeight(h);
end

function Element:SetPosition(x, y)
    self:GetRect():setPosition(x, y);
end

function Element:SetSize(w, h)
    self:GetRect():setSize(w, h);
end
