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

-- 是否是组件
function  Component:IsComponent(tagname)
    local ComponentClass = self:GetComponentByTagName(tagname);
    if (ComponentClass and ComponentClass.isa and ComponentClass:isa(Component)) then
        return true;
    end
    return false;
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
    -- if (G == nil) then echo("-----------------self define global scope not exist--------------------") end
    return G or _G;
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
        self.ComponentScope.RegisterComponent = function(tagname, filename)
            Component.Register(tagname, filename, self:GetComponents());
        end
        self.ComponentScope.GetGlobalScope = function()
            return self:GetGlobalScope();
        end
        self.ComponentScope.__newvalue = function(t, key, val)
            if (not self:IsAutoRefresh() or key == "__newvalue") then return end
            print(string.format("[component:%s] [info] set component scope value, key = %s, ", self.name, key));
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
    if (self.xmlRoot) then return self.htmlNode, self.scriptNode, self.styleNode, self.xmlRoot end

    -- 从字符串加载
    local xmlRoot = nil;
    if (self.template and self.template ~= "") then
        xmlRoot = ParaXML.LuaXML_ParseString(self.template);
    elseif (self.filename and self.filename ~= "") then
        self.template = Helper.ReadFile(self.filename) or "";
        -- 移除xml注释
        self.template = string.gsub(self.template, "<!%-%-.-%-%->", "");
        -- 维持脚本原本格式
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
    self.htmlNode = htmlNode;
    self.scriptNode = scriptNode;
    self.styleNode = styleNode;
    -- echo("-------------------------------------LoadXmlNode-----------------------------------------");
    return htmlNode, scriptNode, styleNode, xmlRoot;
end

-- 解析XmlNode
function Component:ParseXmlNode(xmlNode)
    if (not xmlNode) then return end
    Parser(self, {xmlNode = xmlNode});
    return xmlNode;
end


-- 解析组件获取组件的页面元素 PageElement
function Component:ParseComponent()
    -- 获取相应的xml节点
    local htmlNode, scriptNode, styleNode = self:LoadXmlNode();
    -- 解析html 生成element
    self:ParseXmlNode(htmlNode);
    -- 设置元素
    self:SetElement(htmlNode and htmlNode.element);
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
    -- 执行组件OnRefresh回调
    self:ExecTextCode([[if (type(OnRefresh) == "function") then OnRefresh() end]]);
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
        if (type(val) ~= "table") then
            ElementStyle[key] = val;
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



