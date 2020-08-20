function Component:GetXmlNodeScope(xmlNode)
    if (type(xmlNode) ~= "table") then return {} end
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