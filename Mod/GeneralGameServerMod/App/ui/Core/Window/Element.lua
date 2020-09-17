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

local Style = NPL.load("./style.lua");
local Element = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Element:Property("Window");     -- 元素所在窗口
Element:Property("Attr");       -- 元素属性
Element:Property("XmlNode");    -- 元素XmlNode
Element:Property("ParentElement");         -- 父元素
Element:Property("ChildrenElementList");   -- 子元素列表
Element:Property("ChildrenElementCount");  -- 子元素的个数
Element:Property("Control");    -- 控件
Element:Property("Style");      -- 样式

-- 获取元素
function Element:GetElementByTagName(tagname)
    return self:GetWindow():GetElementManager():GetElementByTagName(tagname);
end

function Element:ctor()
    self:SetChildrenElementList({});
    self:SetStyle({});
end

function Element:Init(xmlNode, uiwindow)
    -- 设置窗口
    self:SetWindow(uiwindow);
    
    -- 文本节点直接转换格式
    if (type(xmlNode) ~= "table") then xmlNode = {name = "Text", attr = {value = tostring(xmlNode)}} end
    
    -- 设置元素属性
    self:SetName(xmlNode.name);
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

-- 加载元素
function Element:LoadComponent(parentElement, parentLayout, parentStyle)
    self:SetStyle(self:CreateStyle(nil, parentStyle));
end

-- 创建样式
function Element:CreateStyle(baseStyle, inheritStyle)
    -- base style
    self:SetStyle(Style:new():Init(baseStyle));
    -- inherit style
    self:GetStyle():MergeInheritable(inheritStyle);
    -- class style

    -- inline style
    self:GetStyle():AddString(self:GetAttrValue("style"));
end

-- 获取属性值
function Element:GetAttrValue(attrName, defaultValue)
    local attr = self:GetAttr();
    if (not attr) then return defaultValue end
    return attr[attrName] or defaultValue;
end

-- 遍历
function Element:Next()
    local i, size, children = 0, self:GetChildrenElementCount(), self:GetChildrenElementList();
    return function() 
        i = i + 1;
        if (i > size) then return end
        return children[i];
    end
end