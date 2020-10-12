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
Component:Property("StyleSheet");     -- 组件样式表  <style></style>
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

function Component:Init(xmlNode, window)
    self:InitElement(xmlNode, window);

    self:LoadXmlNode();

    return self;
end

-- 加载文件
function Component:LoadXmlNode()
    -- 开发环境每次重新加载
    if (self.xmlRoot) then return self.htmlNode, self.scriptNode, self.styleNode, self.xmlRoot end
    local src = self:GetAttrStringValue("src");
    ComponentDebug.Format("LoadXmlNode src = %s", src);
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

    -- 解析script
    self:ParseScriptNode(scriptNode);

    -- 解析style
    self:ParseStyleNode(styleNode);

    -- 解析html
    self:ParseXmlNode(htmlNode);

    -- 初始化元素  需要重写创建子元素逻辑
    local oldTagClass = {};
    local ComponentClassMap = self:GetComponents();
    local ElementManager = self:GetWindow():GetElementManager();
    for key, val in pairs(ComponentClassMap) do
        oldTagClass[key] = ElementManager:GetElementByTagName(key);
        ElementManager:RegisterByTagName(key, val);
    end
    self:InitChildElement(htmlNode, self:GetWindow());
    for key, val in pairs(ComponentClassMap) do
        ElementManager:RegisterByTagName(key, oldTagClass[key]);
    end

    -- 解析指令
    Compile(self);

    self.htmlNode, self.scriptNode, self.styleNode, self.xmlRoot = htmlNode, scriptNode, styleNode, xmlRoot

    return htmlNode, scriptNode, styleNode, xmlRoot;
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
function Component:ParseScriptNode(scriptNode)
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

-- 解析样式节点
function Component:ParseStyleNode(styleNode)
    if (not styleNode) then return end
    local mimetype = styleNode.attr and styleNode.attr.type or "text/css";
    local type = string.match(mimetype,"[^/]+/([^/]+)");
    local text = styleNode[1] or "";
    -- 强制使用css样式
    self:SetStyleSheet(self:GetWindow():GetStyleManager():AddStyleSheetByString(text));
end

-- 解析XmlNode
function Component:ParseXmlNode(xmlNode)
    if (not xmlNode) then return end
    local attr = xmlNode.attr or {};
    local curAttr = self:GetAttr();
    curAttr.style, curAttr.class = curAttr.style or "", curAttr.class or "";
    commonlib.mincopy(curAttr, attr);
    curAttr.style = (attr.style or "") .. ";" .. (curAttr.style or "");
    curAttr.class = (attr.class or "") .. (curAttr.class or "");
    return xmlNode;
end

-- 设置引用元素
function Component:SetRef(ref, element)
    self.refs[ref] = element;
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
            return self.refs[refname];
        end
        self.ComponentScope.RegisterComponent = function(tagname, filename)
            Component.Register(tagname, filename, self:GetComponents());
        end
        self.ComponentScope.GetGlobalScope = function()
            return self:GetGlobalScope();
        end
        self.ComponentScope.GetComponent = function() 
            return self;
        end
        self.ComponentScope.__newvalue = function(t, key, val)
        end
        self.ComponentScope:SetMetaTable(self:GetGlobalScope());
    end
    return self.ComponentScope;
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

-- 全局注册组件
function Component.Register(tagname, tagclass, ComponentClassMap)
    -- 验证组件类
    tagclass = Component.Extend(tagclass);

    -- 注册
    local Register = function (tagname, tagclass)
        ComponentClassMap = ComponentClassMap or GlobalComponentClassMap;
        if (not tagclass) then
            return ComponentClassMap[tagname] or mcml:GetClassByTagName(tagname);
        end
        echo("register component: " .. tagname);
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

-- -- 解析组件获取组件的页面元素 PageElement
-- function Component:ParseComponent()
--     -- 获取相应的xml节点
--     local htmlNode, scriptNode, styleNode = self:LoadXmlNode();
--     -- 解析html 生成element
--     self:ParseXmlNode(htmlNode);
--     -- 设置元素
--     self:SetElement(htmlNode and htmlNode.element);
-- end


-- -- 查找父组件 
-- function Component:GetParentComponent(bReset)
--     if (not bReset and self.parentComponent) then return self.parentComponent end

--     local parent = self.parent;
--     while (parent and not parent:isa(Component)) do
--         parent = parent.parent;
--     end
--     self.parentComponent = parent;

--     return parent;
-- end

-- -- 将组件属性附加在组件Scope上
-- function Component:InitComponentScope()
--     if (self.attr) then
--         self:SetAutoRefresh(false);
--         local scope = self:GetComponentScope();
--         for key, val in pairs(self.attr) do
--             if (key ~= "style" and key ~= "class") then
--                 scope[key] = val;
--             end
--         end
--         self:SetAutoRefresh(true);
--     end  
-- end

-- -- 合并组件
-- function Component:MergeComponents()
--     local parentComponent = self:GetParentComponent();
--     local parentComponents = parentComponent and parentComponent:GetComponents();
--     local components = self:GetComponents();
--     local meta = getmetatable(components);
--     if not meta then
--         meta = {}
--         setmetatable (components, meta);
--     end
--     meta.__index = parentComponents or GlobalComponentClassMap;
-- end

-- -- 初始化组件
-- function Component:Init()
--     -- 初始化组件Scope
--     self:InitComponentScope();
--     -- 设置父组件
--     self:GetParentComponent(true);
--     -- 设置依赖组件链
--     self:MergeComponents();
-- end

-- -- 加载组件
-- function Component:LoadComponent(parentElem, parentLayout, style)
--     -- echo({"----------------------LoadComponent:", self.name, "scope id", self:GetScope():GetID()});
--     -- 初始化
--     self:Init();
--     -- 解析组件
--     self:ParseComponent();
--     -- 组件是否有效
--     if (not self:IsValid()) then return end
    
--     -- 组件加载前
--     self:OnLoadComponentBeforeChild(parentElem, parentLayout, style);
--     -- 真实组件加载
--     self:GetElement():LoadComponent(parentElem, parentLayout, style);
--     -- 组件加载后 合并样式
--     self:OnLoadComponentAfterChild(parentElem, parentLayout, style);

--     -- 执行组件OnRefresh回调
--     self:ExecTextCode([[if (type(OnRefresh) == "function") then OnRefresh() end]]);
-- end

-- function Component:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
--     if (not self:IsValid()) then return end
--     self:GetPageStyle():AddReference(self:GetComponentStyle(), "css");
-- end

-- function Component:OnLoadComponentAfterChild(parentElem, parentLayout, css)
--     if (not self:IsValid()) then return end
--     self:GetPageStyle():RemoveReference(self:GetComponentStyle(), "css");

--     local ComponentStyle = self:GetStyle();
--     local ElementStyle = self:GetElement():GetStyle();
--     for key, val in pairs(ComponentStyle) do
--         if (type(val) ~= "table") then
--             ElementStyle[key] = val;
--         end
--     end
-- end

-- function Component:UpdateLayout(layout)
--     if (not self:IsValid()) then return end
--     self:OnBeforeChildLayout(layout);
--     self:GetElement():UpdateLayout(layout);
--     self:OnAfterChildLayout(layout);
-- end 

-- function Component:OnBeforeChildLayout(layout)
--     if (not self:IsValid()) then return end
-- end

-- function Component:OnAfterChildLayout(layout, left, top, right, bottom)
--     if (not self:IsValid()) then return end
-- end

-- function Component:OnBeforeUpdateElementLayout(elementLayout, parentElementLayout)
--     elementLayout:UpdateElementLayout(self:GetElement(), parentElementLayout);
--     return true;
-- end

-- function Component:paintEvent(painter)
--     if (not self:IsValid()) then return end
--     self:GetElement():paintEvent(painter);
-- end



