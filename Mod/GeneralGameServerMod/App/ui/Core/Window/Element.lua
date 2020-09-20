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
local Layout = NPL.load("./layout.lua", IsDevEnv);
local ElementUI = NPL.load("./ElementUI.lua", IsDevEnv);
local Element = commonlib.inherit(ElementUI, NPL.export());

local ElementDebug = GGS.Debug.GetModuleDebug("ElementDebug");

Element:Property("Window");     -- 元素所在窗口
Element:Property("Attr");       -- 元素属性
Element:Property("XmlNode");    -- 元素XmlNode
Element:Property("ParentElement");                        -- 父元素
Element:Property("Style", {});                            -- 样式
Element:Property("BaseStyle");                            -- 默认样式, 基本样式
Element:Property("Rect", Rect:new():init(0,0,0,0));       -- 元素几何区域矩形
Element:Property("Name");                                 -- 元素名
Element:Property("TagName");                              -- 标签名

-- 构造函数
function Element:ctor()
    self:SetName("Element");
    self.childrens = {};   -- 子元素列表

    -- 设置布局
    self:SetLayout(Layout:new():Init(self));
end

-- 获取元素
function Element:GetElementByTagName(tagname)
    return self:GetWindow():GetElementManager():GetElementByTagName(tagname);
end

-- 元素初始化
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
    for i, childXmlNode in ipairs(xmlNode) do
        if (type(childXmlNode) ~= "table") then 
            childXmlNode = {name = "Text", attr = {value = tostring(childXmlNode)}};
            xmlNode[i] = childXmlNode;
        end
        local PageElement = self:GetElementByTagName(childXmlNode.name);
        local childElement = PageElement:new():Init(childXmlNode, uiwindow);
        -- self:InsertChildElement(childElement);
        table.insert(self.childrens, childElement);
        childElement:SetParentElement(self);
    end

    return self;
end

-- 添加子元素
function Element:InsertChildElement(pos, childElement)
    local element = childElement or pos;
    -- 验证元素的有效性
    if (type(element) ~= "table" or not element.isa or not childElement:isa(Element)) then return end
    -- 添加子元素
    table.insert(self.childrens, pos, childElement);
    -- 设置子元素的父元素
    element:SetParentElement(self);
    -- 更新元素布局
end

-- 移除子元素
function Element:RemoveChildElement(pos)
    pos = pos or self:GetChildElementCount();
    if (type(pos) ~= "number" or pos < 1 or pos > self:GetChildElementCount()) then return end
    local element = self.childrens[pos];
    table.remove(self.childrens, pos);
    if (element) then element:SetParentElement(nil) end
end

-- 获取子元素数量
function Element:GetChildElementCount()
    return #self.childrens;
end

-- 获取子元素列表
function Element:GetChildElementList()
    return self.childrens;
end

-- 遍历 默认渲染序  false 事件序
function Element:ChildElementIterator(isRender)
    local i, size, childrens， list = 0, self:GetChildElementCount() or 0, self:GetChildElementList(), {};
    for i = 1, #childrens do  list[i] = childrens[i] end
    local function comp(child1, child2)
        local zindex1 = (child1:GetStyle())["z-index"] or 0;
        local zindex2 = (child2:GetStyle())["z-index"] or 0;
        return (isRender or isRender == nil) and (zindex1 <= zindex2) or (zindex1 > zindex2);
    end
    table.sort(list, comp);
    return function() 
        i = i + 1;
        if (i > size) then return end
        return list[i];
    end
end

-- 元素布局更新前回调
function Element:OnBeforeUpdateLayout()
end
-- 子元素布局更新前回调
function Element:OnBeforeUpdateChildLayout()
end
-- 子元素布局更新后回调
function Element:OnAfterUpdateChildLayout()
end
-- 元素布局更新后回调
function Element:OnAfterUpdateLayout()
end
-- 更新布局, 先进行子元素布局, 再布局当前元素
function Element:UpdateLayout()
    local layout = self:GetLayout();
    if (self:OnBeforeUpdateLayout()) then return end

    -- 准备布局
    layout:PrepareLayout();

    -- 是否布局
    if (not layout:IsLayout()) then return end

    -- 子元素布局更新前回调
    local isUpdatedChildLayout = self:OnBeforeUpdateChildLayout();

    -- 执行子元素布局  子元素布局未更新则进行更新
	if (not isUpdatedChildLayout) then
		for childElement in self:ChildElementIterator() do
			childElement:UpdateLayout();
		end
    end
    
	-- 执行子元素布局后回调
    self:OnAfterUpdateChildLayout();

    -- 更新元素布局
    layout:Update();

    -- 元素布局更新后回调
    self:OnAfterUpdateLayout();

    -- 设置几何图形大小
    local left, top = layout:GetPos();
    local width, height = layout:GetWidthHeight();
	self:SetGeometry(left, top, width, height);
end

-- 加载元素样式相关属性
function Element:LoadComponent()
    ElementDebug("LoadComponent: " .. self:GetName());

    self:SetStyle(self:CreateStyle());

    self:OnLoadComponentBeforeChild();

	self:OnLoadChildrenComponent();
	
    self:OnLoadComponentAfterChild();
    
    self:MergePseudoClassStyle(); -- 合并伪类样式

end

-- 子元素加载前
function Element:OnLoadComponentBeforeChild(parentElement, parentLayout, style)
end

-- 加载子元素
function Element:OnLoadChildrenComponent(parentElement, parentLayout, style)
    for childElement in self:ChildElementIterator() do
        childElement:LoadComponent(parentElement, parentElement, style);
    end
end

-- 子元素加载后
function Element:OnLoadComponentAfterChild(parentElement, parentLayout, style)
end

-- 创建样式
function Element:CreateStyle(baseStyle, inheritStyle)
    local baseStyle = self:GetBaseStyle();
    local inheritStyle = self:GetParentElement() and self:GetParentElement():GetStyle();

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

-- 获取属性值
function Element:GetAttrValue(attrName, defaultValue)
    local attr = self:GetAttr();
    if (not attr) then return defaultValue end
    return attr[attrName] or defaultValue;
end




