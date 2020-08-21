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
        return self:ExecTextCode(code, true);
    end);
    
    element = element or Elements.pe_text:createFromString(text);
    element:SetValue(text);
    
    if (parentElement) then 
        table.insert(parentElement, element);
        element.parent = parentElement;
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
    local attr = commonlib.copy(xmlNode.attr);   -- v-atrr 会常更新, 生成元素需要用最新的attr集 否则可能使用旧的缓存属性集
    if (xmlNode.element) then
        element = xmlNode.element;
        for i = #element, 1, -1 do
            element[i]:DeleteControls();  -- 无需移除子元素
            -- element[i]:GetControl():SetParent(nil);
            table.remove(element, i);
        end
    else
        element = {name = xmlNode.name};
        local ElementClass = self:GetComponentByTagName(if_else(parentElement == nil and xmlNode.name == "template", "div", xmlNode.name or "text")); -- template => div
        -- 新建元素
        if (type(ElementClass) == "table" and ElementClass.new) then
            element = ElementClass:new(element);
        elseif (type(ElementClass) == "function") then
            element = ElementClass(element);
        else 
            return LOG.std(nil, "warn", "Component", "can not find tag name %s", xmlNode.name or "");
        end
    end

    if (not element) then
        echo("[parser] [error] generate page element failed:" .. xmlNode.name);
        return true;
    end

    element.attr = attr;
    echo("[parser] [info] generate page element:" .. element.name);
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
    for i = 1, #xmlNode do
        if (type(xmlNode[i]) == "string") then xmlNode[i] = {text = xmlNode[i]} end
        Parser(self, {xmlNode = xmlNode[i], parentElement = element});
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
        attr[key] = val;
    end
    for key, val in pairs(von) do
        if (key == "click" or key == "mouseover") then
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
        local o = { name = xmlNode.name, attr = commonlib.copy(xmlNode.attr)};
        for i = 1, #xmlNode do
            table.insert(o, type(xmlNode[i]) == "table" and copyXmlNode(xmlNode[i]) or xmlNode[i]);
        end
        return o;
    end

    echo({"-------------------------v-for", count})
    for i = 1, count do
        local cloneNode = i < cloneXmlNodeCount and cloneXmlNodes[i] or copyXmlNode(xmlNode); -- 大于上次数量新增, 小于复用
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
        self:ParseXmlNodeRecursive(cloneNode, parentElement);
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
        {name="v-for", parse = v_for},
        {name="v-if", parse = v_if},
        {name="v-attr", parse = v_attr},
        {name="text-xml-node", parse = ParseTextXmlNode},
        {name="xml-node", parse = ParseXmlNode},
        {name="child-xml-node", parse = ParseChildXmlNode},
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
