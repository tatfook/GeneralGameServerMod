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
local Compile = NPL.load("./Compile.lua", IsDevEnv);
local ComponentDebug = GGS.Debug.GetModuleDebug("Component");

Component:Property("Components");     -- 组件依赖组件集
Component:Property("ParentComponent");-- 父组件
Component:Property("Queue");          -- 更新队列

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

    self.scope = nil;                   -- 当前scope
    self.ComponentScope = nil;          -- 组件scope
    self:SetComponents({});             -- 依赖组件集
    self.refs = {};
end

-- 初始化
function Component:Init(xmlNode, window, parent)
    local htmlNode, scriptNode, styleNode, xmlRoot = self:LoadXmlNode(xmlNode);
    self:SetWindow(window);
    -- 加载组件样式
    self:LoadStyle(styleNode);
    -- 合并XmlNode
    self:MergeXmlNode(xmlNode, htmlNode);
    -- 初始化元素
    self:InitElement(xmlNode, window, parent);
    -- 初始化组件
    self:InitComponent();
    -- 解析script
    self:LoadScript(scriptNode);
    -- 初始化子元素  需要重写创建子元素逻辑
    self:InitChildElement(htmlNode, window);
    -- 根组件直接编译
    if (not self:GetParentComponent()) then 
        Compile(self);
    else
        -- 非根组件等待编译完成
    end
    return self;
end

-- 初始化组件
function Component:InitComponent()
    -- 初始化组件Scope
    self:InitComponentScope();
    -- 设置父组件
    local parentComponent = self:GetParentElement();
    while (parentComponent and not parentComponent:isa(Component)) do
        parentComponent = parentComponent:GetParentElement();
    end
    self:SetParentComponent(parentComponent);
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
function Component:LoadStyle(styleNode)
    if (not styleNode) then return end
    local mimetype = styleNode.attr and styleNode.attr.type or "text/css";
    local type = string.match(mimetype,"[^/]+/([^/]+)");
    local text = styleNode[1] or "";
    -- 强制使用css样式
    self:SetStyleSheet(self:GetWindow():GetStyleManager():GetStyleSheetByString(text));
end

-- 合并XmlNode
function Component:MergeXmlNode(elementXmlNode, componentXmlNode)
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

function Component:OnBeforeCompile()
end

function Component:OnAfterCompile()
end

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

-- 执行代码
function Component:ExecCode(code, isAddReturn, scope) 
    if (type(code) ~= "string" or code == "") then return end
    if (isAddReturn) then code = "return (" .. code .. ")" end
    local code_func, errmsg = loadstring(code);
    if (not code_func) then return echo("Exec Code Error: " .. errmsg) end
    setfenv(code_func, scope or self:GetScope());
    return code_func();
end

-- 解析脚本节点
function Component:LoadScript(scriptNode)
    if (not scriptNode) then return end
    local scriptFile = scriptNode.attr and scriptNode.attr.src;
    local scriptText = scriptNode[1] or "";
    scriptText = (Helper.ReadFile(scriptFile) or "") .. "\n" .. scriptText;
    local code_func, errormsg = loadstring(scriptText);
    if (not code_func) then 
        return LOG.std(nil, "error", "Component", "<Runtime error> syntax error while loading code in url:%s\n%s", src, tostring(errormsg));
    end
    -- 设置脚本执行环境
    setfenv(code_func, self:GetScope());
    -- 执行脚本
    code_func();
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
        G.GlobalScope = Scope:New();
        G.GlobalScope:SetMetaTable(G);
    end
    return G;
end

function Component:PushScope(scope)
    scope = Scope.New(scope);
    scope:SetMetaTable(self:GetScope());
    self:SetScope(scope);
    -- echo({"--------------------push scope", scope:GetID()});
    return scope;
end

function Component:PopScope()
    local scope = self:GetScope();
    if (scope == self.ComponentScope) then 
        -- echo("---------------------------pop scope error !!!");
        return nil 
    end
    -- echo({"--------------------pop scope", scope:GetID()});
    scope = scope:GetMetaTable();
    self:SetScope(scope);
    return scope;
end

function Component:SetScope(scope)
    self.scope = scope;
end

function Component:GetScope()
    return self.scope or self:GetComponentScope();
end

-- 获取组件Scope
function Component:GetComponentScope()
    if (not self.ComponentScope) then
        -- 组件scope
        self.ComponentScope = Scope.New();  -- 用自身的attr作为scope
        self.ComponentScope.self = self.ComponentScope; 
        self.ComponentScope.GetRef = function(refname) 
            return self:GetRef(refname);
        end
        self.ComponentScope.RegisterComponent = function(tagname, filename)
            self:Register(tagname, filename);
        end
        self.ComponentScope.GetGlobalScope = function()
            return self:GetGlobalScope();
        end
        self.ComponentScope.GetComponent = function() 
            return self;
        end
        self.ComponentScope:SetMetaTable(self:GetGlobalScope());
    end
    return self.ComponentScope;
end

-- 将组件属性附加在组件Scope上
function Component:InitComponentScope()
    local scope = self:GetComponentScope();
    local attrs = self:GetAttr();
    for key, val in pairs(attrs) do
        if (key ~= "style" and key ~= "class") then
            scope[key] = val;
        end
    end
end

-- 设置属性值
function Component:SetAttrValue(attrName, attrValue)
    Component._super.SetAttrValue(self, attrName, attrValue);
    self:GetComponentScope():Set(attrName, attrValue);
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