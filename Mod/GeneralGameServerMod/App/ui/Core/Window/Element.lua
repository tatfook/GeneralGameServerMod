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

NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
local Element = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), NPL.export());

local ElementManager = nil;

function Element.SetElementManager(elementManager)
    ElementManager = elementManager;
end

function Element:createFromXmlNode(xmlNode)
    element = self:new(xmlNode);
    for i, childXmlNode in ipairs(xmlNode) do
        local TagElement = ElementManager.GetElementByTagName(type(childXmlNode) == "table" and childXmlNode.name or "Text");
        local childElement = TagElement:createFromXmlNode(childXmlNode);
        element[i] = childElement;
        childElement.parent = element;
    end
	return element;
end

-- 加载元素
function Element:LoadComponent(parentElem, parentLayout, styleItem)
    Element._super.LoadComponent(self, self:GetControl() or parentElem, parentLayout, styleItem);
end
