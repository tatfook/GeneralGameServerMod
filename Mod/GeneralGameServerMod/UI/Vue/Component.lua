--[[
Title: Component
Author(s): wxa
Date: 2020/6/30
Desc: 组件基类
use the lib:
-------------------------------------------------------
local Component = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Vue/Component.lua");
-------------------------------------------------------
]]
local Element = NPL.load("../Window/Element.lua", IsDevEnv);

local Component = commonlib.inherit(Element, NPL.export());
local Helper = NPL.load("./Helper.lua", IsDevEnv);
local Scope = NPL.load("./Scope.lua", IsDevEnv);
local ComponentScope = NPL.load("./ComponentScope.lua", IsDevEnv);
local Compile = NPL.load("./Compile.lua", IsDevEnv);
local ComponentDebug = GGS.Debug.GetModuleDebug("Component");

Component:Property("Components");             -- 组件依赖组件集
Component:Property("ParentComponent");        -- 父组件
Component:Property("ChildrenComponentList");  -- 子组件列表
Component:Property("Scope");                  -- 组件当前Scope
Component:Property("ComponentScope");         -- 组件Scope 
-- 全局组件
local GlobalComponentClassMap = {};
local XmlFileCache = {};

local function LoadXmlFile(filename)
    -- if (XmlFileCache[filename]) then return XmlFileCache[filename] end

    local template = Helper.ReadFile(filename) or "";
    -- 移除xml注释
    template = string.gsub(template, "<!%-%-.-%-%->", "");
    -- 维持脚本原本格式
    template = string.gsub(template, "[\r\n]<script(.-)>(.-)[\r\n]</script>", "<script%1>\n<![CDATA[\n%2\n]]>\n</script>");
    -- 缓存
    -- XmlFileCache[filename] = template;
    
    return template;
end

-- 是否是组件
function  Component:IsComponent()
    return true;
end

-- 组件构造函数
function Component:ctor()
    self:SetName("Component");

    self:SetComponents({});             -- 依赖组件集
    self.refs = {};
    self.slotXmlNodes = {};
    self:SetChildrenComponentList({});
end

-- 初始化
function Component:Init(xmlNode, window, parent)
    self:InitSlotXmlNode(xmlNode);

    local htmlNode, scriptNode, styleNode, xmlRoot = self:LoadXmlNode(xmlNode);
    self:SetWindow(window);
    -- 加载组件样式
    self:InitByStyleNode(styleNode);
    -- 合并XmlNode
    self:InitByXmlNode(xmlNode, htmlNode);
    -- 初始化元素
    self:InitElement(xmlNode, window, parent);
    -- 初始化组件
    self:InitComponent(xmlNode);
    -- 解析script
    self:InitByScriptNode(scriptNode);
    -- 初始化子元素  需要重写创建子元素逻辑
    self:InitChildElement(htmlNode, window);
    -- 根组件直接编译
    if (not self:GetParentComponent()) then 
        self:Compile();
    else
        -- 非根组件等待编译完成
    end
    return self;
end

-- 初始化Slot
function Component:InitSlotXmlNode(xmlNode)
    -- slot attr 
    local slotXmlNodes = self.slotXmlNodes;
    local defaultSlot = {name = "template"};
    for _, childXmlNode in ipairs(xmlNode) do
        local slot = type(childXmlNode) == "table" and childXmlNode.attr and childXmlNode.attr.slot;
        if (slot) then
            slotXmlNodes[string.lower(slot)] = childXmlNode;
        else
            table.insert(defaultSlot, childXmlNode);
        end
    end
    slotXmlNodes.default = slotXmlNodes.default or defaultSlot;

    -- 设置Slot元素所属组件
    local function Slot(xmlNode)
        if (type(xmlNode) ~= "table") then return end
        if (string.lower(xmlNode.name) == "slot") then
            xmlNode.component = self;
        end
        for _, childXmlNode in ipairs(xmlNode) do
            Slot(childXmlNode);
        end
    end 
    Slot(xmlNode);
end

-- 初始化组件
function Component:InitComponent(xmlNode)
    -- 初始化组件Scope
    local scope = ComponentScope.New(self);
    self:SetComponentScope(scope);
    self:SetScope(scope);

    -- 设置父组件
    local parentComponent = self:GetParentElement();
    while (parentComponent and not parentComponent:isa(Component)) do
        parentComponent = parentComponent:GetParentElement();
    end
    self:SetParentComponent(parentComponent);
    if (parentComponent) then
        table.insert(parentComponent:GetChildrenComponentList(), self);
    end
end

-- 初始化子元素
function Component:InitChildElement(xmlNode, window)
    -- ComponentDebug("====================Component:InitChildElement========================");
    local oldElementClass = {};
    local ComponentClassMap = self:GetComponents();
    local ElementManager = self:GetWindow():GetElementManager();
    for key, val in pairs(ComponentClassMap) do
        oldElementClass[key] = ElementManager:GetElementByTagName(key);
        ElementManager:RegisterByTagName(key, val);
    end
    Component._super.InitChildElement(self, xmlNode, window);
    for key, val in pairs(ComponentClassMap) do
        ElementManager:RegisterByTagName(key, oldElementClass[key]);
    end
end

-- 加载文件
function Component:LoadXmlNode(xmlNode)
    -- 开发环境每次重新加载
    if (self.xmlRoot) then return self.htmlNode, self.scriptNode, self.styleNode, self.xmlRoot end
    -- local src = self:GetAttrStringValue("src");
    local src = xmlNode.attr and xmlNode.attr.src or self.filename;
    -- ComponentDebug.Format("LoadXmlNode src = %s", src);
    -- 从字符串加载
    local xmlRoot = nil;
    if (self.template and self.template ~= "") then
        xmlRoot = ParaXML.LuaXML_ParseString(self.template);
    elseif (src and src ~= "") then
        local template = LoadXmlFile(src);
        -- 解析template
        xmlRoot = ParaXML.LuaXML_ParseString(template);
        -- 类存在放在类中, 避免重复读取, 不存在放在示例中
        -- self._super.template = template;
    end
    -- print(self.template);

    local htmlNode = xmlRoot and commonlib.XPath.selectNode(xmlRoot, "//template");
    local scriptNode = xmlRoot and commonlib.XPath.selectNode(xmlRoot, "//script");
    local styleNode = xmlRoot and commonlib.XPath.selectNode(xmlRoot, "//style");

    self.htmlNode, self.scriptNode, self.styleNode, self.xmlRoot = htmlNode, scriptNode, styleNode, xmlRoot;
    return htmlNode, scriptNode, styleNode, xmlRoot;
end

-- 加载组件样式
function Component:InitByStyleNode(styleNode)
    if (not styleNode) then return end
    local mimetype = styleNode.attr and styleNode.attr.type or "text/css";
    local type = string.match(mimetype,"[^/]+/([^/]+)");
    local text = styleNode[1] or "";
    -- 强制使用css样式
    self:SetStyleSheet(self:GetWindow():GetStyleManager():GetStyleSheetByString(text));
end

-- 合并XmlNode
function Component:InitByXmlNode(elementXmlNode, componentXmlNode)
    if (not elementXmlNode or not componentXmlNode) then return end
    local componentAttr = componentXmlNode.attr or {};
    local elementAttr = elementXmlNode.attr or {};
    elementAttr.style, elementAttr.class = elementAttr.style or "", elementAttr.class or "";
    commonlib.mincopy(elementAttr, componentAttr);
    elementAttr.style = (componentAttr.style or "") .. ";" .. (elementAttr.style or "");
    elementAttr.class = (componentAttr.class or "") .. (elementAttr.class or "");
    elementXmlNode.attr = elementAttr;
    return elementXmlNode;
end

-- 解析脚本节点
function Component:InitByScriptNode(scriptNode)
    if (not scriptNode) then return end
    local scriptFile = scriptNode.attr and scriptNode.attr.src;
    local scriptText = scriptNode[1] or "";
    scriptText = (Helper.ReadFile(scriptFile) or "") .. "\n" .. scriptText;
    self:ExecCode(scriptText);
end

-- 编译组件
function Component:Compile()
    self:OnBeforeCompile();

    self:OnCompile();

    local childrenComponentList = self:GetChildrenComponentList();
    for _, childrenComponent in ipairs(childrenComponentList) do
        childrenComponent:Compile();
    end

    self:OnAfterCompile();
end

-- 编译回调
function Component:OnCompile()
    Compile(self);
end

-- 编译前回调
function Component:OnBeforeCompile()
end

-- 编译后回调
function Component:OnAfterCompile()
    self:ExecCode([[return type(OnReady) == "function" and OnReady()]]);
end

-- 设置引用元素
function Component:SetRef(ref, element)
    self.refs[ref] = element;
end
-- 获取引用元素
function Component:GetRef(ref)
    return self.refs[ref];
end

-- 获取全局Scope
function Component:GetGlobalScope()
    local G = self:GetWindow():GetG();
    if (not G.GlobalScope) then
        G.GlobalScope = Scope:__new__();
        G.GlobalScope:__set_metatable_index__(G);
    end
    return G.GlobalScope;
end

function Component:PushScope(scope)
    scope = Scope:__new__(scope);
    scope:__set_metatable_index__(self:GetScope());
    self:SetScope(scope);
    return scope;
end

function Component:PopScope()
    local scope = self:GetScope();
    if (scope == self:GetComponentScope()) then return end
    scope = scope:__get_metatable_index__();
    self:SetScope(scope);
    return scope;
end

-- 执行代码
function Component:ExecCode(code) 
    if (type(code) ~= "string" or code == "") then return end
    local func, errmsg = loadstring(code);
    if (not func) then 
        return ComponentDebug("===============================Exec Code Error=================================", errmsg);
    end
    setfenv(func, self:GetComponentScope());
    return func();
end

-- 设置属性值
function Component:SetAttrValue(attrName, attrValue)
    local oldAttrValue = self:GetAttrValue(attrName);
    Component._super.SetAttrValue(self, attrName, attrValue);
    self:OnAttrValueChange(attrName, attrValue, oldAttrValue);
    -- self:GetComponentScope():Set(attrName, attrValue);
end

-- 属性值更新
function Component:OnAttrValueChange(attrName, attrValue)
    self:ExecCode(string.format([[return type(OnAttrValueChange) == "function" and OnAttrValueChange("%s", GetAttrValue("%s"))]], attrName, attrName));
end

-- 全局注册组件
function Component:Register(tagname, tagclass)
    -- 验证组件类
    tagclass = Component.Extend(tagclass);

    -- 注册
    local Register = function (tagname, tagclass)
        tagname = string.lower(tagname);
        local ComponentClassMap = self:GetComponents();
        if (not tagclass) then
            return ComponentClassMap[tagname] or self:GetElementByTagName(tagname);
        end
        ComponentClassMap[tagname] = tagclass;
        return tagclass;
    end

    if (type(tagname) == "string") then
        tagclass = Register(tagname, tagclass) or tagclass;
    elseif (type(tagname) == "table") then
        for i, tag in ipairs(tagname) do
            tagclass = Register(tag, tagclass) or tagclass;
        end
    else
        LOG:warn("无效组件:" .. tostring(tagname));
    end

    return tagclass
end

-- 定义组件
function Component.Extend(opts)
    -- 为字符串则默认为文件名
    if (type(opts) == "string") then opts = {filename = opts} end;
    -- 只接受table
    if (type(opts) ~= "table") then return end
    -- 已经是组件直接返回
    if (opts.isa and opts:isa(Component)) then return opts end
    -- 继承Component构造新组件
    local ComponentExtend = commonlib.inherit(Component, opts);

    -- 返回新组件
    return ComponentExtend;
end