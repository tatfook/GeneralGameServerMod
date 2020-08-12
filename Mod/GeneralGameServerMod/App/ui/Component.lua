--[[
Title: Component
Author(s): wxa
Date: 2020/6/30
Desc: 组件基类
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/App/ui/Component.lua");
local Component = commonlib.gettable("Mod.GeneralGameServerMod.App.ui.Component");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/mcml.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");

local mcml = commonlib.gettable("System.Windows.mcml");
local Elements = commonlib.gettable("System.Windows.mcml.Elements");
local Component = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("Mod.GeneralGameServerMod.App.ui.Component"));
local IsDevEnv = ParaEngine.GetAppCommandLineByParam("IsDevEnv","false") == "true";

-- 初始化基本元素
mcml:StaticInit();
-- 全局组件
local GlobalComponentMap = {};  

-- 获取全局组件表
function Component.GetGlobalComponentMap()
    return GlobalComponentMap;
end

-- 组件构造函数
function Component:ctor()
    self.components = {};  -- 组件类
    self.filename = nil;
end

-- 初始化函数
function Component:Init(opts)
    self.filename = opts.filename;
    return self;
end

-- 获取组件类
function Component:GetClassByTagName(name)
    if (not name) then return nil end

    return self.components[name] or GlobalComponentMap[name] or mcml:GetClassByTagName(name);
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
    -- return nil;
    return _G;
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
    local meta = getmetatable (scope);
    if not meta then
        meta = {}
        setmetatable (scope, meta)
    end
    meta.__index = self:GetScope();
    self:SetScope(scope);    
    return self:GetScope();
end

function Component:PopScope()
    local meta = getmetatable (self:GetScope());
    if (not meta) then return nil end
    self:SetScope(meta.__index);
    return self:GetScope();
end

function Component:SetScope(scope)
    self.scope = scope;
end

-- 获取组件Scope
function Component:GetScope()
    if (self.scope) then return self.scope end
    local __this__ = self;
    self.scope = {
        ExportScope = function(scope) 
            if (type(scope) ~= "table") then return end
            return __this__:PushScope(scope);
        end
    };
    setmetatable(self.scope, {__index = self:GetGlobalTable()});
    return self.scope;
end

-- 解析脚本节点
function Component:ParseScriptNode(scriptNode)
    if (not scriptNode) then return end
    local scriptFile = scriptNode.attr and scriptNode.attr.src;
    local scriptText = scriptNode[1] or "";
    scriptText = self:ReadLocalScriptFile(scriptFile) .. "\n" .. scriptText;
    local code_func, errormsg = loadstring(scriptText);
    if (not code_func) then 
        return LOG.std(nil, "error", "pe_sComponentcript", "<Runtime error> syntax error while loading code in url:%s\n%s", src, tostring(errormsg));
    end
    -- 设置脚本执行环境
    setfenv(code_func, self:GetScope());
    -- 执行脚本
    code_func();
end

-- 解析元素属性
function Component:ParseElementAttr(element)
    local attr = element and element.attr;
    if (not attr) then return end
    local realAttr = {};
    for key, val in pairs(attr) do
        -- v-bind 指令
        local realKey = string.match(key, "^v-bind:(.+)");
        if (realKey and realKey ~= "") then
            local realVal = self:ExecTextCode(val, true) or val;
            realAttr[realKey] = realVal;
        end
        -- v-on 指令
        realKey = string.match(key, "^v-on:(.+)");
        if (realKey and realKey ~= "") then
            local realVal = string.gsub(val, "^%s*(.-)[;%s]*$", "%1");
            local isFuncCall = string.match(realVal, "%S+%(.*%)$");
            if (not isFuncCall) then 
                -- 不是函数调用则获取函数
                realVal = self:ExecTextCode(realVal, true);
            else
                -- 函数调用则返回字符串函数
                local code_func, errmsg = loadstring(realVal);
                if (code_func) then
                    -- 这里使用合适的作用作用域
                    setfenv(code_func, self:GetScope());
                    realVal = code_func;
                else
                    realVal = function() end;
                end
            end
            realAttr[realKey] = realVal;
        end
    end
    commonlib.partialcopy(attr, realAttr);
end

-- 解析html
function Component:ParseHtmlNode(htmlNode, isRoot)
    if (not htmlNode) then return end
    -- 元素类不存在
    local ElementClass = self:GetClassByTagName(isRoot and "div" or htmlNode.name); -- template => div
    -- 新建元素
    local element = nil;
    if (type(ElementClass) == "table" and ElementClass.new) then
        element = ElementClass:new(htmlNode);
    elseif (type(ElementClass) == "function") then
        element = ElementClass(htmlNode);
    else 
        LOG.std(nil, "warn", "Component", "can not find tag name %s", htmlNode.name or "")
    end
    if (not element) then return end
    -- 解析元素属性
    self:ParseElementAttr(element);
    -- 解析子元素
    local validIndex = 1;
    local childCount = #(element);
    for i = 1, childCount do
        local child = element[i];
        local childElement = nil;
        element[i] = nil;
        if(type(child) == "table") then
            childElement = self:ParseHtmlNode(child);
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

function Component:ParseStyleNode()
end

-- 执行文本代码
function Component:ExecTextCode(code, isAddReturn) 
    if (type(code) ~= "string" or code == "") then return end
    if (isAddReturn) then 
        code = "return (" .. code .. ")";
    end
    local code_func, errmsg = loadstring(code);
    if (not code_func) then return echo("Error: " .. errmsg) end
    setfenv(code_func, self:GetScope());
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
    -- 解析html
    self:SetElement(self:ParseHtmlNode(htmlNode));
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
