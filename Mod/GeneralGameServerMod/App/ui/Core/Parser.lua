--[[
Title: Directive
Author(s): wxa
Date: 2020/6/30
Desc: 组件指令解析器
use the lib:
-------------------------------------------------------
local Directive = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Directive.lua");
-------------------------------------------------------
]]

local Elements = commonlib.gettable("System.Windows.mcml.Elements");

local Parser = NPL.export();

-- 拷贝属性
local function copy_attr(attr)
    if (type(attr) ~= "table") then return attr end
    local o = {};

    for key, val in pairs(attr) do
        o[key] = val;
    end

    return o;
end

-- 解析开始
local function parse_begin(self, opts)
    local xmlNode, parentElement = opts.xmlNode, opts.parentElement; 
    if (type(xmlNode) ~= "table") then return end
    local element = xmlNode.element;
    if (self:IsComponent(xmlNode.name)) then
        element = element and element:GetElement();
    end
    local control = element and element:GetControl();
    if (control) then control:SetParent(nil) end   -- 将控件从父控件中移除
end

-- 解析结束
local function parse_end(self, opts)
end

-- 是否是文本节点
local function IsTextXmlNode(xmlNode) 
    return type(xmlNode) == "string" or (not xmlNode.name) or xmlNode.name == "";
end

-- 解析Slot节点对应的xmlNode
local function ParseSlotXmlNode(self, opts)
    local xmlNode, parentElement = opts.xmlNode, opts.parentElement; 
    -- 组件子节点列表
    local childXmlNodes = self.childXmlNodes or {};
    -- 获取slot对象xmlnode
    local function GetXmlNodeBySlotName(slotName)
        for i = 1, #childXmlNodes do
            local childNode = childXmlNodes[i];
            local childSlotName = childNode.attr and childNode.attr.name;
            if (string.lower(childNode.name or "") == "slot" and childSlotName == slotName) then
                return childNode.xmlNode;
            end
            if (childNode.slotName == slotName) then
                return childNode;
            end
        end
    end

    -- 解析slot的对应的xmlnode
    local function ParseSlotXmlNodeRecursive(self, opts, xmlNode)
        -- echo({"parser", "parse slot xml node", xmlNode and xmlNode.name or "nil"});
        if (IsTextXmlNode(xmlNode)) then return end
        if (string.lower(xmlNode.name) == "slot") then
            xmlNode.xmlNode = GetXmlNodeBySlotName(xmlNode.attr and xmlNode.attr.name);
            return;  -- <slot></slot> 内部节点忽略           
        end
        for i = 1, #xmlNode do
            ParseSlotXmlNodeRecursive(self, opts, xmlNode[i]);
        end
    end

    ParseSlotXmlNodeRecursive(self, opts, xmlNode);
end

-- 解析文本节点生成文本页面元素
local function ParseTextXmlNode(self, opts)
    local xmlNode, parentElement = opts.xmlNode, opts.parentElement; 
    -- 非文本节点直接返回
    if (type(xmlNode) ~= "string" and xmlNode.name ~= nil) then return end

    -- 内联文本
    local text, element = "", nil;
    if (type(xmlNode) == "string") then
        text = xmlNode;
    else
        text = xmlNode.text;
        element = xmlNode.element;
    end 
    -- 解析文本
    text = string.gsub(text, "{{(.-)}}", function(code)
        return self:ExecTextCode(code, true) or "";
    end);
    
    element = element or Elements.pe_text:createFromString(text);
    element:SetValue(text);
    
    if (parentElement) then 
        table.insert(parentElement, element);
        element.parent = parentElement;
        element.index = #parentElement;
    else
        element.parent = self;
    end
    
    xmlNode.element = element;

    return true;
end

-- 解析节点生成相应的页面元素
local function ParseXmlNode(self, opts)
    local xmlNode, parentElement = opts.xmlNode, opts.parentElement; 
    if (type(xmlNode) ~= "table") then return end

    local element = nil;
    local attr = copy_attr(xmlNode.attr);   -- v-attr 会常更新, 生成元素需要用最新的attr集 否则可能使用旧的缓存属性集
    if (xmlNode.element) then
        element = xmlNode.element;
        for i = #element, 1, -1 do
            local childElement = element[i];
            local childElementControl = childElement and childElement:GetControl();
            if (childElementControl) then childElementControl:SetParent(nil) end   -- 将控件从父控件中移除
            table.remove(element, i);
        end
    else
        element = {name = xmlNode.name, xmlNode = xmlNode};
        local ElementClass = self:GetComponentByTagName(if_else(parentElement == nil and xmlNode.name == "template", "div", xmlNode.name or "text")); -- template => div
        -- 新建元素
        if (type(ElementClass) == "table" and ElementClass.new) then
            element = ElementClass:new(element);
        elseif (type(ElementClass) == "function") then
            element = ElementClass(element);
        else 
            return LOG.std(nil, "warn", "Component", "can not find tag name %s", xmlNode.name or "");
        end
        if (self:IsComponent(xmlNode.name)) then
            echo({"----------------------------Create Element:", xmlNode.name});
        end
    end

    if (not element) then
        echo("[parser] [error] generate page element failed:" .. xmlNode.name);
        return true;
    end

    element.attr = attr;

    -- echo("[parser] [info] generate page element:" .. element.name);
    -- echo({"[parser] [info] element attr:", element.attr});

    -- 添加到父元素中
    if (parentElement) then 
        table.insert(parentElement, element);
        element.parent = parentElement;
    else
        element.parent = self;
    end
    
    xmlNode.element = element;
end

-- 解析xml子节点
local function ParseChildXmlNode(self, opts)
    local xmlNode, parentElement = opts.xmlNode, opts.parentElement; 
    if (type(xmlNode) ~= "table") then return end

    local element = xmlNode.element;
    -- 节点元素没有生成, 无法解析子元素
    if (not element) then
        echo("[ParseChildXmlNode] [Error]: element not exist, name = " .. xmlNode.name);
        return 
    end

    -- 解析子节点
    -- echo("---------------------child node count:" .. tostring(#xmlNode));
    local isComponent = self:IsComponent(xmlNode and xmlNode.name);
    if (isComponent) then element.childXmlNodes = {}; end
    for i = 1, #xmlNode do
        if (type(xmlNode[i]) == "string") then xmlNode[i] = {text = xmlNode[i]} end
        if (isComponent) then
            -- 组件, 备份子节点, 以便内部<slot></slot>替换
            table.insert(element.childXmlNodes, xmlNode[i]);
        else
            -- 非组件
            Parser(self, {xmlNode = xmlNode[i], parentElement = element});
        end
    end

    -- 如果是组件, 解析slot节点对应的xmlnode
    if (isComponent) then
        ParseSlotXmlNode(self, opts);
    end
end

-- 解析v-slot指令
local function v_slot(self, opts)
    local xmlNode, parentElement = opts.xmlNode, opts.parentElement; 
    -- v-slot只能用于组件的直接子元素
    if (type(xmlNode) ~= "table" or not self:IsComponent(xmlNode.name)) then return end
    -- 不解析slot组件的v-slot命令
    if (string.lower(xmlNode.name) == "slot") then return end

    -- echo({"Parser", "v-slot", xmlNode.name});

    -- 设置子节点的slotname
    for i = 1, #xmlNode do
        local childNode = xmlNode[i];
        -- 转换文本节点
        if (type(childNode) == "string") then
            childNode = {text = childNode}
            xmlNode[i] = childNode;
        end
        childNode.scope = self:GetScope();              -- 获取当前栈顶Scope  支持v-for嵌套
        if (childNode.attr) then
            for key, val in pairs(childNode.attr) do
                local slotName = string.match(key, "v-slot:(%w+)");
                if (slotName) then
                    childNode.slotName = slotName;
                    childNode.slotScope = val;
                end
            end
        end 
    end
end

-- 解析ref属性  应放在元素解析完成后解析
local function ref_attr(self, opts)
    local xmlNode, parentElement = opts.xmlNode, opts.parentElement; 
    if (type(xmlNode) ~= "table" or type(xmlNode.attr) ~= "table" or type(xmlNode.attr["ref"]) ~= "string" or not xmlNode.element) then return end
    self.refs[xmlNode.attr["ref"]] = xmlNode.element;
end

-- 合并样式属性
local function merge_style_attr(attr, style)
    attr.rawStyel = attr.rawStyel or attr.style or "";
    -- 重置最初样式
    attr.style = attr.rawStyel .. ";";

    if (type(style) == "string") then 
        attr.style = attr.style .. style;
    elseif (type(style) == "table") then
        for key, val in pairs(style) do
            if (type(key) == "string" and type(val) == "string") then
                attr.style = attr.style .. key .. ":" .. val .. ";";
            end
        end        
    else
    end
end

-- 合并类属性
local function merge_class_attr(attr, class)
    attr.rawClass = attr.rawClass or attr.class or "";
    attr.class = attr.rawClass .. " ";

    if (type(class) == "string") then
        attr.class = attr.class .. class;
    elseif (type(class == "table")) then
        for key, value in pairs(class) do
            if (type(key) == "number" and type(val) == "string") then
                attr.class = attr.class .. val .. " ";
            elseif (type(key) == "string" and type(val) == "boolean" and val) then
                attr.class = attr.class .. key .. " ";
            end
        end
    end
end

-- 解析v-bind指令
local function v_attr(self, opts)
    local xmlNode, parentElement = opts.xmlNode, opts.parentElement; 
    if (type(xmlNode) ~= "table" or type(xmlNode.attr) ~= "table") then return end

    -- 已经解析直接返回
    if (xmlNode.v_attr_parsed) then return end

    local attr = xmlNode.attr;            -- 原生属性
    local vattr = {};                     -- 指令属性
    local vbind = {};                     -- 绑定变量属性
    local von = {};                       -- 绑定事件属性

    for key, val in pairs(attr) do
        -- v-bind 指令
        local realKey = string.match(key, "^v%-bind:(.+)");
        local realVal = nil;
        if (realKey and realKey ~= "") then
            realVal = self:ExecTextCode(val, true);
            vattr[key] = val;
            vbind[realKey] = realVal;
            -- echo({"---------------------v-bind:", key, val, realKey, realVal, self:GetScope():GetRawData()});
        end

        -- v-on 指令
        realKey = string.match(key, "^v%-on:(.+)");
        if (realKey and realKey ~= "") then
            vattr[key] = val;
            -- 以括号结束则当做函数调用  
            local isFuncCall = string.match(val, "%S+%(.*%)[;%s]*$");
            if (not isFuncCall) then 
                -- 不是函数调用则获取函数
                realVal = self:ExecTextCode(val, true);
                if (not realVal) then echo("invalid function listen") end
            else
                -- 函数调用则返回字符串函数
                local code_func, errmsg = loadstring(val);
                if (code_func) then
                    -- 这里使用合适的作用作用域
                    setfenv(code_func, self:GetScope());
                    realVal = code_func;
                else
                    realVal = function() echo("null function") end;
                end
            end
            von[realKey] = realVal;
        end
    end
    
    for key, val in pairs(vbind) do
        if (key == "style") then
            merge_style_attr(attr, val);
        elseif (key == "class") then
            merge_class_attr(attr, val);
        else 
            attr[key] = val;
        end
    end

    for key, val in pairs(von) do
        if (key == "click" or key == "change" or key == "mouseover") then
            attr["on" .. key] = val;  -- 标准事件加上 on 前缀
        else
            attr[key] = val;
        end
    end

    xmlNode.vattr, xmlNode.vbind, xmlNode.von = vattr, vbind, von;
    -- xmlNode.v_attr_parsed = true;

    return ;
end

-- 解析v-if指令
local function v_if(self, opts)
    local xmlNode, parentElement = opts.xmlNode, opts.parentElement; 
    if (type(xmlNode) ~= "table" or type(xmlNode.attr) ~= "table") then return end
    local attr = xmlNode and xmlNode.attr;
    if (not attr or not attr["v-if"]) then return end
    return not self:ExecTextCode(attr["v-if"], true);  -- v_if 为假 元素移除 返回真
end

-- 解析v-for指令
local function v_for(self, opts)
    local xmlNode, parentElement = opts.xmlNode, opts.parentElement; 
    if (type(xmlNode) ~= "table" or type(xmlNode.attr) ~= "table") then return end

    local attr = xmlNode and xmlNode.attr;
    if (not attr or not attr["v-for"]) then return end

    local v_for = attr["v-for"] or "";
    local keyexp, list = string.match(v_for, "%(?(%a[%w%s,]*)%)?%s+in%s+(%w*)");
    if (not keyexp) then return end

    local val, key = string.match(keyexp, "(%a%w-)%s*,%s*(%a%w-)");
    if (not val) then val = keyexp end

    list = self:ExecTextCode(list, true);
    local count = type(list) == "number" and list or (type(list) == "table" and #list or 0);

    local cloneXmlNodes = xmlNode.cloneXmlNodes or {};
    local cloneXmlNodeCount = xmlNode.cloneXmlNodeCount or 0;
    local function copyXmlNode(xmlNode)
        local o = { name = xmlNode.name, attr = copy_attr(xmlNode.attr)};
        for i = 1, #xmlNode do
            table.insert(o, type(xmlNode[i]) == "table" and copyXmlNode(xmlNode[i]) or xmlNode[i]);
        end
        return o;
    end

    echo({"-------------------------v-for", count, cloneXmlNodeCount, #cloneXmlNodes});
    for i = 1, count do
        local cloneNode = i <= cloneXmlNodeCount and cloneXmlNodes[i] or copyXmlNode(xmlNode); -- 大于上次数量新增, 小于复用
        cloneXmlNodes[i] = cloneNode;
        cloneNode.attr["v-for"] = nil;

        -- v-for 产生新scope
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
        Parser(self, {xmlNode = cloneNode, parentElement = parentElement});
        -- 弹出scope栈
        self:PopScope();
    end
    xmlNode.cloneXmlNodes = cloneXmlNodes;
    xmlNode.cloneXmlNodeCount = count;

    -- 返回 true 表名解析完成
    return true;
end

function Parser.Parse(self, opts)
    -- 优先级高的放前面, 特殊性的放前面
    local parser_list = {
        {name="begin", parse = parse_begin},
        {name="v-slot", parse = v_slot},
        {name="v-for", parse = v_for},
        {name="v-if", parse = v_if},
        -- 通用属性解析
        {name="v-attr", parse = v_attr},
        -- 文本元素解析
        {name="text-xml-node", parse = ParseTextXmlNode},
        -- {name="slot-xml-node", parse = ParseSlotXmlNode},
        -- 通用元素解析
        {name="xml-node", parse = ParseXmlNode},
        -- 特殊属性
        {name="ref-attr", parse = ref_attr},
        -- 子元素
        {name="child-xml-node", parse = ParseChildXmlNode},
        {name="end", parse = parse_end},
    }

    for i = 1, #parser_list do
        local parser = parser_list[i];
        -- echo("[parser] parse: " .. parser.name);
        if (parser.parse(self, opts)) then
            return true;
        end
    end

end

setmetatable(Parser, {
    __call = function(parser, component, opts)
        return Parser.Parse(component, opts);
    end
})
