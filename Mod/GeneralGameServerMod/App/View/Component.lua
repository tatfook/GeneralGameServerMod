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
local IsDevEnv = ParaEngine.GetAppCommandLineByParam("IsDevEnv","false") == "true";

-- 初始化基本元素
mcml:StaticInit();

-- 组件构造函数
function Component:ctor()
    self.components = {};  -- 组件类
    self.filename = "Mod/GeneralGameServerMod/App/View/Component.html";
end

-- 获取组件类
function Component:GetClassByTagName(name)
    if (not name) then return nil end

    return self.components[name] or mcml:GetClassByTagName(name);
end

-- 通过xml节点创建页面元素
function Component:createFromXmlNode(o)
    o = self:new(o);

    o.childNodes = {};
    -- 解析slot节点
    for i, childNode in ipairs(o) do
        o.childNodes[i] = childNode;
    end

    return o;
end

-- 静态初始化
function Component:Register(tagname)
    self.tagname = tagname;
    -- 标记为组件
    self.isComponent = true;

    -- 注册组件
    if (type(self.tagname) == "string") then
        self:RegisterAs(self.tagname);
    elseif (type(self.tagname) == "table") then
        for i, tagname in ipairs(self.tagname) do
            self:RegisterAs(tagname);
        end
    else
        LOG:warn("无效组件:" .. tostring(self.tagname));
    end
    
    return self;
end

-- 组件是否有效
function Component:IsValid()
    return if_else(self.element, true, false)
end

-- 设置组件的页元素
function Component:SetElement(element)
    self.element = element;
end

-- 获取组件页元素
function Component:GetElement()
    return self.element;
end

-- 解析组件获取组件的页面元素 PageElement
function Component:ParseComponent()
    -- 开发环境每次重新解析
    if (not IsDevEnv and self:IsValid()) then return end

    local xmlRoot = self.filename and ParaXML.LuaXML_ParseFile(self.filename);
    local xmlNode = xmlRoot and commonlib.XPath.selectNode(xmlRoot, "//pe:mcml");
    local class_type = xmlNode and self:GetClassByTagName(xmlNode.name);
    self:SetElement(class_type and class_type:createFromXmlNode(xmlNode));
end

-- 查找父组件 
function Component:GetParentComponent(bReset)
    if (not bReset and self.parentComponent) then return self.parentComponent end

    local parent = self.parent;
    while (parent and not parent:isa(Component)) do
        echo(parent.name);
        parent = parent.parent;
    end
    echo(parent and parent.name);
    self.parentComponent = parent;

    return parent;
end

-- 加载组件
function Component:LoadComponent(parentElem, parentLayout, style)
    -- 设置父组件
    self:GetParentComponent(true);
    -- 合并组件
    self:MergeComponents();
    -- 解析组件
    self:ParseComponent();
    -- 组件是否有效
    if (not self:IsValid()) then return end
    -- 设置父元素
    self:GetElement().parent = self;
    -- 组件加载前
    self:OnLoadComponentBeforeChild(parentElem, parentLayout, style);
    -- 真实组件加载
    self:GetElement():LoadComponent(parentElem, parentLayout, style);
    -- 组件加载后 合并样式
    self:OnLoadComponentAfterChild(parentElem, parentLayout, style);
end

function Component:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
    if (not self:IsValid()) then return end
end

function Component:OnLoadComponentAfterChild(parentElem, parentLayout, css)
    if (not self:IsValid()) then return end
    local defaultStyle = self:GetStyle();
    local componentStyle = self:GetElement():GetStyle();
    for key, val in pairs(defaultStyle) do
        if (componentStyle[key] == nil) then
            componentStyle[key] = val;
        end
    end
end

function Component:UpdateLayout(layout)
    if (not self:IsValid()) then return end
    self:OnBeforeChildLayout(layout);
    self:GetElement():UpdateLayout(layout);
    self:OnAfterChildLayout(layout);
end 

function Component:OnBeforeChildLayout(layout)
    if (not self:IsValid()) then return end
end

function Component:OnAfterChildLayout(layout, left, top, right, bottom)
    if (not self:IsValid()) then return end
end

function Component:paintEvent(painter)
    if (not self:IsValid()) then return end
    self:GetElement():paintEvent(painter);
end


-- 合并组件
function Component:MergeComponents()
    local parentComponent = self:GetParentComponent();
    if (not parentComponent) then return end
    for key, val in pairs(parentComponent.components) do
        if (self.components[key] == nil) then
            self.components[key] = val;
        end
    end
end

Component:Register({"pe:component", "Component"});