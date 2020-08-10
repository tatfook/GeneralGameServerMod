--[[
Title: Component
Author(s): wxa
Date: 2020/6/30
Desc: 组件基类
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/App/View/Component.lua");
local Window = commonlib.gettable("Mod.GeneralGameServerMod.App.View.Component");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/mcml.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");

local mcml = commonlib.gettable("System.Windows.mcml");
local Component = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("Mod.GeneralGameServerMod.App.View.Component"));

-- 初始化基本元素
mcml:StaticInit();

function Component:ctor()
end

function Component:Init(tagname, filename)
    self:RegisterAs(tagname or "unknow");

    local xmlRoot = ParaXML.LuaXML_ParseFile(filename or "Mod/GeneralGameServerMod/App/View/Component.html");
    local xmlNode = xmlRoot and commonlib.XPath.selectNode(xmlRoot, "//pe:mcml");
    local class_type = xmlNode and mcml:GetClassByTagName(xmlNode.name or "div");
    self.element = class_type and class_type:createFromXmlNode(xmlNode);
    echo(self.element);
    return self;
end

function Component:LoadComponent(parentElem, parentLayout, style)
    local _this = nil;
    if (self.element) then
        self.element:LoadComponent(parentElem, parentLayout, style);
        _this = self.element:GetControl();
    end

	Component._super.LoadComponent(self, _this, parentLayout, style);
end

function Component:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
    if (self.element) then
        self.element:OnLoadComponentBeforeChild(parentElem, parentLayout, css);
    end 
end

function Component:OnLoadComponentAfterChild(parentElem, parentLayout, css)
    if (self.element) then
        self.element:OnLoadComponentAfterChild(parentElem, parentLayout, css);
    end
end

function Component:UpdateLayout(layout)
    if (self.element) then
        self.element:UpdateLayout(layout);
    end
end 

function Component:OnBeforeChildLayout(layout)
    if (self.element) then
        self.element:OnBeforeChildLayout(layout);
    end
end

function Component:OnAfterChildLayout(layout, left, top, right, bottom)
    if (self.element) then
        self.element:OnAfterChildLayout(layout, left, top, right, bottom);
    end
end

function Component:paintEvent(painter)
    if (self.element) then
        self.element:paintEvent(painter);
    end
end

-- 初始化成单列模式
Component:InitSingleton():Init("pe:component", nil);