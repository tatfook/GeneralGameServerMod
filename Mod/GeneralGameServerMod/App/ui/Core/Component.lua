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
local mcml = commonlib.gettable("System.Windows.mcml");
local Elements = commonlib.gettable("System.Windows.mcml.Elements");
local Component = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), NPL.export());
local IsDevEnv = ParaEngine.GetAppCommandLineByParam("IsDevEnv","false") == "true";

-- 初始化基本元素
mcml:StaticInit();

-- 全局组件
Component.components = {};  

-- 组件构造函数
function Component:ctor()
    self.scope = nil;
    self.componentScope = nil;
    self.components = self.components or {};  -- 依赖组件
    self.filename = self.filename or nil;   -- 组件文件
    self.name = self.name or "Component";  -- 组件名
end

-- 注册注册组件
function Component:Extend(opts)
    -- 只接受table
    if (type(opts) ~= "table") then return end
    -- 已经是组件直接返回
    if (opts.isa and opts:isa(Component)) then return opts end
    -- 继承Component构造新组件
    local ComponentExtend = commonlib.inherit(Component, opts);
    -- 返回新组件
    return ComponentExtend;
end

-- 注册组件
function Component:Register(tagname, tagclass)
    -- 验证组件类
    tagclass = self:Extend(tagclass);
    -- 注册
    local Register = function (tagname, tagclass)
        if (not tagclass) then
            return self:GetComponentByTagName(tagname);
        end

        self.components[tagname] = tagclass;
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
    return self.components[tagname] or Component.components[tagname] or mcml:GetClassByTagName(tagname);
end


-- 通过xml节点创建页面元素
function Component:createFromXmlNode(o)
    return self:new(o);
end

-- 组件是否有效
function Component:IsValid()
    return if_else(self.element, true, false)
end

-- 设置组件的页元素
function Component:SetElement(element)
    if (element) then
        element.parent = self;
    end

    self.element = element;
end

-- 获取组件页元素
function Component:GetElement()
    return self.element;
end

-- 获取全局表
function Component:GetGlobalTable()
    local page = self:GetPageCtrl();
    local window = page and page:GetWindow();
    local G = window and window:GetUI():GetGlobalTable();
    -- local G = page and page:GetPageGlobalTable();
    return G or _G;
end

-- 获取脚本文件
function Component:ReadLocalScriptFile(filename)
    local text = "";
    if(filename and ParaIO.DoesFileExist(filename)) then
		local file = ParaIO.open(filename, "r");
		if(file:IsValid()) then
			text = file:GetText();
			file:close();
		end
    end
    return text;
end

function Component:PushScope(scope)
    scope = scope or {};
    local meta = getmetatable (scope);
    if not meta then
        meta = {}
        setmetatable (scope, meta);
    end
    meta.__index = self:GetScope();
    self:SetScope(scope);    
    return self:GetScope();
end

function Component:PopScope()
    local scope = self:GetScope();
    local meta = getmetatable (scope);
    self:SetScope(meta and meta.__index);
    return scope;
end

function Component:SetScope(scope)
    self.scope = scope;
end

-- 获取组件Scope
function Component:GetScope()
    if (not self.componentScope) then
        -- 组件scope
        local __this__ = self;
        self.componentScope = {
            ExportScope = function(scope) 
                if (type(scope) ~= "table") then return end
                return __this__:PushScope(scope);
            end
        };   
        setmetatable(self.componentScope, {__index = self:GetGlobalTable()});
    end

    return self.scope or self.componentScope;
end

function Component:SetScopeValue(key, value)
    local scope = self:GetScope();
    scope[key] = value;
end

function Component:GetScopeValue(key)
    local scope = self:GetScope();
    return scope and scope[key];
end

function Component:GetXmlNodeScope(xmlNode)
    if (type(xmlNode) ~= "table") then return end
    xmlNode.scope = xmlNode.scope or {};
    return xmlNode.scope;
end

function Component:SetXmlNodeScopeValue(xmlNode, key, value)
    if (type(xmlNode) ~= "table" or not key) then return end
    xmlNode.scope = xmlNode.scope or {};
    xmlNode.scope[key] = value;
end

function Component:GetXmlNodeScopeValue(xmlNode, key)
    if (type(xmlNode) ~= "table" or not key) then return end
    xmlNode.scope = xmlNode.scope or {};
    return xmlNode.scope[key];
end

-- 解析脚本节点
function Component:ParseScriptNode(scriptNode)
    if (not scriptNode) then return end
    local scriptFile = scriptNode.attr and scriptNode.attr.src;
    local scriptText = scriptNode[1] or "";
    scriptText = self:ReadLocalScriptFile(scriptFile) .. "\n" .. scriptText;
    local code_func, errormsg = loadstring(scriptText);
    if (not code_func) then 
        return LOG.std(nil, "error", "Component", "<Runtime error> syntax error while loading code in url:%s\n%s", src, tostring(errormsg));
    end
    -- 设置脚本执行环境
    setfenv(code_func, self:GetScope());
    -- 执行脚本
    code_func();
end

-- 解析文本节点
function Component:ParseXmlTextNode(xmlNode, parentXmlNode)
    local code = string.match(xmlNode, "^{{(.*)}}$");
    return self:ExecTextCode(code, true) or xmlNode; 
end

-- 解析元素属性
function Component:ParseXmlNodeAttr(xmlNode, parentXmlNode)
    if (type(xmlNode) ~= "table") then return end

    local attr = xmlNode and xmlNode.attr;
    if (not attr) then return end
    local realAttr = {};
    local directive = {};
    for key, val in pairs(attr) do
        echo(key);
        -- v-bind 指令
        local realKey = string.match(key, "^v%-bind:(.+)");
        if (realKey and realKey ~= "") then
            directive[key] = val;
            local realVal = self:ExecTextCode(val, true) or val;
            realAttr[realKey] = realVal;
        end
        -- v-on 指令
        realKey = string.match(key, "^v%-on:(.+)");
        if (realKey and realKey ~= "") then
            directive[key] = val;
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
            realAttr["on" .. realKey] = realVal;
        end
    end
    commonlib.partialcopy(attr, realAttr);
    -- 清除已解析的指令
    for key, val in pairs(directive) do
        attr[key] = nil;
    end
    return attr;
end

-- 递归解析节点属性
function Component:ParseXmlNodeAttrRecursive(xmlNode, parentXmlNode)
    if (type(xmlNode) ~= "table") then return end

    self:PushScope(self:GetXmlNodeScope(xmlNode));

    self:ParseXmlNodeAttr(xmlNode, parentXmlNode);

    for i = 1, #xmlNode do
        if (type(xmlNode[i]) == "string") then
            xmlNode[i] = self:ParseXmlTextNode(xmlNode[i], xmlNode);
        else 
            self:ParseXmlNodeAttrRecursive(xmlNode[i], xmlNode);
        end
    end

    self:PopScope();
end

-- 解析v-for指令
function Component:ParseVForDirective(xmlNode, parentXmlNode)
    if (not parentXmlNode or not xmlNode or type(xmlNode) == "string") then return end
    local v_for = xmlNode.attr and xmlNode.attr["v-for"];
    if (not v_for or v_for == "") then return end
    local keyexp, list = string.match(v_for, "%(?(%a[%w%s,]*)%)?%s+in%s+(%w*)");
    if (not keyexp) then return end
    local val, key = string.match(keyexp, "(%a%w-)%s*,%s*(%a%w-)");
    if (not val) then val = keyexp end
    list = self:ExecTextCode(list, true);
    xmlNode.attr["v-for"] = nil;
    local index = 0;
    for i = 1, #(parentXmlNode.childNodes) do
        if (parentXmlNode.childNodes[i] == xmlNode) then
            index = i;
            break;
        end
    end
    -- 移除当前节点
    if (index > 0) then
        table.remove(parentXmlNode.childNodes, index);
    else
        index = #(parentXmlNode.childNodes) + 1;
    end

    local count = 0;

    if (type(list) == "number") then
        count = list;
    elseif (type(list) == "table") then
        count = #list;
    else
        return ;
    end

    -- 拷贝当前节点
    for i = 1, count do
        local cloneNode = commonlib.copy(xmlNode);
        if (type(list) == "table") then
            self:SetXmlNodeScopeValue(cloneNode, val, list[i]);
        else 
            self:SetXmlNodeScopeValue(cloneNode, val, i);
        end
        self:SetXmlNodeScopeValue(cloneNode, key, i);
        table.insert(parentXmlNode.childNodes, index, cloneNode);
        index = index + 1;
    end
end

-- 递归解析v-for指令
function Component:ParseVForDirectiveRecursive(xmlNode, parentXmlNode)
    if (parentXmlNode) then
        table.insert(parentXmlNode.childNodes, xmlNode);
        self:ParseVForDirective(xmlNode, parentXmlNode);
    end

    if (type(xmlNode) == "string") then return end

    self:PushScope(self:GetXmlNodeScope(xmlNode));
    xmlNode.childNodes = {};
    local childNodeCount = #xmlNode;
    for i = 1, childNodeCount do
        self:ParseVForDirectiveRecursive(xmlNode[i], xmlNode);
    end
    for i = childNodeCount, 1, -1 do
        table.remove(xmlNode, i);
    end
    for i = 1, #(xmlNode.childNodes) do
        table.insert(xmlNode, xmlNode.childNodes[i]);
    end
    xmlNode.childNodes = nil;
    self:PopScope();
end

-- 解析v-if
function Component:ParseVIfDirective(xmlNode, parentXmlNode)
    if (not parentXmlNode or not xmlNode or type(xmlNode) == "string") then return end
    local v_if = xmlNode.attr and xmlNode.attr["v-if"];
    if (not v_if or v_if == "") then return end
    if (v_if == "true") then return end
    v_if = if_else(v_if == "false", false, self:ExecTextCode(v_if, true));
    if (v_if) then return end
    -- 条件为假则移除元素
    for i = 1, #(parentXmlNode.childNodes) do
        if (parentXmlNode.childNodes[i] == xmlNode) then
            table.remove(parentXmlNode.childNodes, i);
            return ;
        end
    end
end

-- 递归解析v-for指令
function Component:ParseVIfDirectiveRecursive(xmlNode, parentXmlNode)
    if (parentXmlNode) then 
        table.insert(parentXmlNode.childNodes, xmlNode);
        self:ParseVIfDirective(xmlNode, parentXmlNode);
    end

    if (type(xmlNode) == "string") then return end
    
    self:PushScope(self:GetXmlNodeScope(xmlNode));
    xmlNode.childNodes = {};
    local childNodeCount = #xmlNode;
    for i = 1, childNodeCount do
        self:ParseVIfDirectiveRecursive(xmlNode[i], xmlNode);
    end
    for i = childNodeCount, 1, -1 do
        table.remove(xmlNode, i);
    end
    for i = 1, #(xmlNode.childNodes) do
        table.insert(xmlNode, xmlNode.childNodes[i]);
    end
    xmlNode.childNodes = nil;
    self:PopScope();
end

-- 解析html
function Component:ParseXmlNode(xmlNode)
    if (not xmlNode) then return end

    -- v-for 指令解析
    self:ParseVForDirectiveRecursive(xmlNode);
    -- v-if 指令解析
    self:ParseVIfDirectiveRecursive(xmlNode);
    -- 解析常规属性
    self:ParseXmlNodeAttrRecursive(xmlNode);

    return xmlNode;
end

-- xmlNode to pageElemetn
function Component:XmlNodeToPageElement(xmlNode, isComponentRoot)
    if (not xmlNode) then return end
    -- 元素类不存在
    local ElementClass = self:GetComponentByTagName(isComponentRoot and "div" or xmlNode.name); -- template => div
    -- 新建元素
    local element = nil;
    if (type(ElementClass) == "table" and ElementClass.new) then
        element = ElementClass:new(xmlNode);
    elseif (type(ElementClass) == "function") then
        element = ElementClass(xmlNode);
    else 
        LOG.std(nil, "warn", "Component", "can not find tag name %s", xmlNode.name or "")
    end
    if (not element) then return end
    -- 解析子元素
    local validIndex = 1;
    local childCount = #(element);
    for i = 1, childCount do
        local child = element[i];
        local childElement = nil;
        element[i] = nil;
        if(type(child) == "table") then
            childElement = self:XmlNodeToPageElement(child);
            if(not childElement) then LOG.std(nil, "warn", "Component", "can not find tag name %s", child.name or ""); end
        else
            -- for inner text of xml
            local code = string.match(child, "^{{(.*)}}$");
            local text = self:ExecTextCode(code, true) or child; 
            childElement = Elements.pe_text:createFromString(text);
        end
        if (childElement) then
            childElement.parent = element;
            childElement.index = validIndex;
            element[validIndex] = childElement;
            validIndex = validIndex + 1;
        end
    end
    return element;
end

-- 解析样式节点
function Component:ParseStyleNode()
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

-- 解析组件获取组件的页面元素 PageElement
function Component:ParseComponent()
    -- 开发环境每次重新解析
    if (not IsDevEnv and self.isParsed) then return end

    -- 获取相应的xml节点
    local xmlRoot = self.filename and ParaXML.LuaXML_ParseFile(self.filename);
    local htmlNode = xmlRoot and commonlib.XPath.selectNode(xmlRoot, "//template");
    local scriptNode = xmlRoot and commonlib.XPath.selectNode(xmlRoot, "//script");
    local styleNode = xmlRoot and commonlib.XPath.selectNode(xmlRoot, "//style");
    -- 解析并执行脚本
    self:ParseScriptNode(scriptNode);
    -- 解析html 生成element
    self:SetElement(self:XmlNodeToPageElement(self:ParseXmlNode(htmlNode), true));
    -- 解析style
    self:ParseStyleNode(styleNode);
    -- 标记已经解析
    self.isParsed = true;
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


