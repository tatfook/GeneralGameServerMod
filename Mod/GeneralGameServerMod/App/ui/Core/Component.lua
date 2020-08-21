--[[
Title: Component
Author(s): wxa
Date: 2020/6/30
Desc: 组件基类
use the lib:
-------------------------------------------------------
local Component = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Component.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/mcml.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/Style.lua");
local Style = commonlib.gettable("System.Windows.mcml.Style");
local mcml = commonlib.gettable("System.Windows.mcml");
local Elements = commonlib.gettable("System.Windows.mcml.Elements");
local Component = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), NPL.export());
local Helper = NPL.load("./Helper.lua");
local Scope = NPL.load("./Scope.lua");
local Parser = NPL.load("./Parser.lua");
local IsDevEnv = ParaEngine.GetAppCommandLineByParam("IsDevEnv","false") == "true";

Component:Property("Element");        -- 组件页面元素
Component:Property("Components");     -- 组件依赖组件集
Component:Property("ComponentStyle"); -- 组件样式表  <style></style>
Component:Property("AutoRefresh", true, "IsAutoRefresh");  -- 是否自动刷新
-- 全局组件
local GlobalComponentClassMap = {};

-- 初始化基本元素
mcml:StaticInit();
Component.name = "Component";

-- 组件构造函数
function Component:ctor()
    self.scope = nil;                   -- 当前scope
    self.ComponentScope = nil;          -- 组件scope
    self:SetComponents({});             -- 依赖组件集
    self:SetComponentStyle(Style:new():init(self:GetPageCtrl()));   -- 构建组件样式表

    print("-----------------create component: ", self.name);
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

    -- 类属性
    ComponentExtend.name = ComponentExtend.name or "ComponentExtend";     -- 组件名
    ComponentExtend.filename = ComponentExtend.filename or "";            -- 组件文件
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
        mcml:RegisterPageElement(tagname, tagclass);

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

-- 获取组件类
function Component:GetComponentByTagName(tagname)
    if (not tagname) then return nil end
    local Components = self:GetComponents() or GlobalComponentClassMap;
    return Components[tagname] or mcml:GetClassByTagName(tagname);
end

-- 通过xml节点创建页面元素
function Component:createFromXmlNode(o)
    return self:new(o);
end

-- 组件是否有效
function Component:IsValid()
    return if_else(self:GetElement(), true, false)
end

-- 获取UI实例
function Component:GetUI()
    local page = self:GetPageCtrl();
    local window = page and page:GetWindow();
    return window and window:GetUI();
end

-- 获取全局表
function Component:GetGlobalScope()
    local ui = self:GetUI();
    local G = ui and ui:GetGlobalScope();
    if (G == nil) then echo("-----------------self define global scope not exist--------------------") end
    return G or _G;
end

function Component:PushScope(scope)
    scope = Scope.New(scope);
    scope:SetMetaTable(self:GetScope());
    self:SetScope(scope);
    echo({"--------------------push scope", scope:GetID()});
    return scope;
end

function Component:PopScope()
    local scope = self:GetScope();
    if (scope == self.ComponentScope) then 
        echo("---------------------------pop scope error !!!");
        return nil 
    end
    echo({"--------------------pop scope", scope:GetID()});
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
        self.ComponentScope.RegisterComponent = function(tagname, filename)
            Component.Register(tagname, filename, self:GetComponents());
        end
        self.ComponentScope.__newvalue = function(t, key, val)
            print(string.format("[component:%s] [info] set component scope value, key = %s, ", self.name, key));
            if (not self:IsAutoRefresh()) then return end
            self:GetUI():RefreshWindow();
        end
        self.ComponentScope:SetMetaTable(self:GetGlobalScope());
    end
    return self.ComponentScope;
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

-- 解析元素属性
function Component:ParseXmlNodeAttr(xmlNode)
    if (type(xmlNode) ~= "table" or type(xmlNode.attr) ~= "table") then return end

    local attr = xmlNode.attr;            -- 原生属性
    local vattr = xmlNode.vattr or {};    -- 指令属性
    local nattr = {};                     -- 新增属性

    for key, val in pairs(attr) do
        -- v-bind 指令
        local realKey = string.match(key, "^v%-bind:(.+)");
        if (realKey and realKey ~= "") then
            -- vattr[key] = val;
            local realVal = self:ExecTextCode(val, true);
            nattr[realKey] = realVal;
        end
        -- v-on 指令
        realKey = string.match(key, "^v%-on:(.+)");
        if (realKey and realKey ~= "") then
            -- vattr[key] = val;
            local realVal = string.gsub(val, "^%s*(.-)[;%s]*$", "%1");
            local isFuncCall = string.match(realVal, "%S+%(.*%)$");
            if (not isFuncCall) then 
                -- 不是函数调用则获取函数
                realVal = self:ExecTextCode(realVal, true);
                if (not realVal) then echo("invalid function listen") end
            else
                -- 函数调用则返回字符串函数
                local code_func, errmsg = loadstring(realVal);
                if (code_func) then
                    -- 这里使用合适的作用作用域
                    setfenv(code_func, self:GetScope());
                    realVal = code_func;
                else
                    realVal = function() echo("null function") end;
                end
            end
            nattr["on" .. realKey] = realVal;
        end
    end
    for key, val in pairs(nattr) do
        attr[key] = val;
    end
    -- xmlNode.vattr = vattr;
    return attr;
end

-- 解析样式节点
function Component:ParseStyleNode(styleNode)
    if (not styleNode) then return end
    local mimetype = styleNode.attr and styleNode.attr.type or "text/css";
    local type = string.match(mimetype,"[^/]+/([^/]+)");
    local text = styleNode[1] or "";
    -- 强制使用css样式
    self:GetComponentStyle():LoadFromString(text, "css");
end

-- 执行文本代码
function Component:ExecTextCode(code, isAddReturn, scope) 
    if (type(code) ~= "string" or code == "") then return end
    if (isAddReturn) then 
        code = "return (" .. code .. ")";
    end
    local code_func, errmsg = loadstring(code);
    if (not code_func) then return echo("Error: " .. errmsg) end
    setfenv(code_func, scope or self:GetScope());
    return code_func();
end

-- 加载文件
function Component:LoadXmlNode()
    -- 开发环境每次重新加载
    if (self.xmlRoot) then return self.xmlRoot end

    -- 从字符串加载
    local xmlRoot = nil;
    if (self.template and self.template ~= "") then
        xmlRoot = ParaXML.LuaXML_ParseString(self.template);
    elseif (self.filename and self.filename ~= "") then
        self.template = Helper.ReadFile(self.filename) or "";
        self.template = string.gsub(self.template, "<!%-%-.-%-%->", "");
        self.template = string.gsub(self.template, "[\r\n]<script(.-)>(.-)[\r\n]</script>", "<script%1>\n<![CDATA[\n%2\n]]>\n</script>");
        -- xmlRoot = ParaXML.LuaXML_ParseFile(self.template);
        xmlRoot = ParaXML.LuaXML_ParseString(self.template);
    end

    -- echo("-----------------------------------component template---------------------------------")
    -- print(self.template);

    local htmlNode = xmlRoot and commonlib.XPath.selectNode(xmlRoot, "//template");
    local scriptNode = xmlRoot and commonlib.XPath.selectNode(xmlRoot, "//script");
    local styleNode = xmlRoot and commonlib.XPath.selectNode(xmlRoot, "//style");

    -- 解析并执行脚本
    self:ParseScriptNode(scriptNode);

    -- 解析style
    self:ParseStyleNode(styleNode);

    self.xmlRoot = xmlRoot;
    self.xmlNode = htmlNode;

    -- echo("-------------------------------------LoadXmlNode-----------------------------------------");
    return xmlRoot;
end

function Component:ParseXmlNodeRecursive(xmlNode, parentElement)
    if (not xmlNode) then return end

    -- 文本节点
    if (type(xmlNode) == "string" or xmlNode.name == nil) then
        -- for inner text of xml
        local text, element = "", nil;
        if (type(xmlNode) == "string") then
            text = xmlNode;
        else
            text = xmlNode.text;
            element = xmlNode.element;
        end 
        -- 解析文本
        text = string.gsub(text, "{{(.-)}}", function(code)
            return self:ExecTextCode(code, true);
        end);
        element = element or  Elements.pe_text:createFromString(text);
        element.parent = parentElement;
        element:SetValue(text);
        if (parentElement) then table.insert(parentElement, element) end
        xmlNode.element = element;
        return;
    end
    
    xmlNode.attr = xmlNode.attr or {};

    -- echo({"-----------xmlnode:",xmlNode.name, xmlNode.attr});
    local element = nil;
    local name = xmlNode.name;
    local attr = commonlib.copy(xmlNode.attr);
   
    if (xmlNode.element) then
        element = xmlNode.element;
        for i = #element, 1, -1 do
            element[i]:DeleteControls();
            table.remove(element, i)
        end
        xmlNode.element = nil;
    else
        element = {name = name, attr = attr};
        local ElementClass = self:GetComponentByTagName(if_else(parentElement == nil and xmlNode.name == "template", "div", xmlNode.name)); -- template => div
        -- 新建元素
        if (type(ElementClass) == "table" and ElementClass.new) then
            element = ElementClass:new(element);
        elseif (type(ElementClass) == "function") then
            element = ElementClass(element);
        else 
            return LOG.std(nil, "warn", "Component", "can not find tag name %s", xmlNode.name or "");
        end
    end

    -- v-for 指令
    local v_for = attr["v-for"] or "";
    local keyexp, list = string.match(v_for, "%(?(%a[%w%s,]*)%)?%s+in%s+(%w*)");
    attr["v-for"] = nil;
    if (keyexp) then         
        local val, key = string.match(keyexp, "(%a%w-)%s*,%s*(%a%w-)");
        if (not val) then val = keyexp end
        list = self:ExecTextCode(list, true);
        local count = type(list) == "number" and list or (type(list) == "table" and #list or 0);
        echo({"-------------------------v-for", count})
        -- 弹出scope
        -- self:PopScope();
        for i = 1, count do
            local cloneNode = commonlib.copy(xmlNode);
            cloneNode.attr["v-for"] = nil;
            local scope = {};
            scope[key or "key"] = i;
            if (type(list) == "table") then
                scope[val] = list[i];
            else
                scope[val] = i; 
            end
            -- 产生新scope压入scope栈
            self:PushScope(scope);
            -- 解析当前节点重新
            self:ParseXmlNodeRecursive(cloneNode, parentElement);
            -- 弹出scope栈
            self:PopScope();
        end
        return nil;  -- v-for 节点返回nil
    end

    -- v-if 指令
    local v_if = attr["v-if"];
    attr["v-if"] = nil;
    if (v_if) then
        v_if = self:ExecTextCode(v_if, true);
        if (not v_if) then return end
    end
    
    -- 解析节点属性
    self:ParseXmlNodeAttr(element);
    
    -- 添加到父元素中
    if (parentElement) then 
        table.insert(parentElement, element);
        element.parent = parentElement;
    else
        element.parent = self;
    end

    -- 解析子节点
    -- echo("---------------------child node count:" .. tostring(#xmlNode));
    for i = 1, #xmlNode do
        if (type(xmlNode[i]) == "string") then xmlNode[i] = {text = xmlNode[i]} end
        self:ParseXmlNodeRecursive(xmlNode[i], element);
    end

    -- 缓存元素
    xmlNode.element = element;

    -- 返回元素
    return element;
end

-- 解析组件获取组件的页面元素 PageElement
function Component:ParseComponent()
    -- 获取相应的xml节点
    self:LoadXmlNode();
    -- 解析html 生成element
    -- self:SetElement(self:ParseXmlNodeRecursive(self.xmlNode));

    Parser(self, {xmlNode = self.xmlNode});
    self:SetElement(self.xmlNode.element);
end


-- 查找父组件 
function Component:GetParentComponent(bReset)
    if (not bReset and self.parentComponent) then return self.parentComponent end

    local parent = self.parent;
    while (parent and not parent:isa(Component)) do
        parent = parent.parent;
    end
    self.parentComponent = parent;

    return parent;
end

-- 将组件属性附加在组件Scope上
function Component:InitComponentScope()
    if (self.attr) then
        self:SetAutoRefresh(false);
        local scope = self:GetComponentScope();
        for key, val in pairs(self.attr) do
            if (key ~= "style" and key ~= "class") then
                scope[key] = val;
            end
        end
        self:SetAutoRefresh(true);
    end  
end

-- 合并组件
function Component:MergeComponents()
    local parentComponent = self:GetParentComponent();
    local parentComponents = parentComponent and parentComponent:GetComponents();
    local components = self:GetComponents();
    local meta = getmetatable(components);
    if not meta then
        meta = {}
        setmetatable (components, meta);
    end
    meta.__index = parentComponents or GlobalComponentClassMap;
end

-- 初始化组件
function Component:Init()
    -- 初始化组件Scope
    self:InitComponentScope();
    -- 设置父组件
    self:GetParentComponent(true);
    -- 设置依赖组件链
    self:MergeComponents();
end

-- 加载组件
function Component:LoadComponent(parentElem, parentLayout, style)
    -- echo({"----------------------LoadComponent:", self.name, "scope id", self:GetScope():GetID(), "scope", self:GetScope():GetRawData()});
    echo({"----------------------LoadComponent:", self.name, "scope id", self:GetScope():GetID()});
    -- 初始化
    self:Init();
    -- 解析组件
    self:ParseComponent();
    -- 组件是否有效
    if (not self:IsValid()) then return end
    -- 组件加载前
    self:OnLoadComponentBeforeChild(parentElem, parentLayout, style);
    -- 真实组件加载
    self:GetElement():LoadComponent(parentElem, parentLayout, style);
    -- 组件加载后 合并样式
    self:OnLoadComponentAfterChild(parentElem, parentLayout, style);
end

function Component:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
    if (not self:IsValid()) then return end
    self:GetPageStyle():AddReference(self:GetComponentStyle(), "css");
end

function Component:OnLoadComponentAfterChild(parentElem, parentLayout, css)
    if (not self:IsValid()) then return end
    self:GetPageStyle():RemoveReference(self:GetComponentStyle(), "css");

    local ComponentStyle = self:GetStyle();
    local ElementStyle = self:GetElement():GetStyle();
    for key, val in pairs(ComponentStyle) do
        ElementStyle[key] = val;
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



