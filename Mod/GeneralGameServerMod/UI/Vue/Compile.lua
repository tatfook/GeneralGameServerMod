--[[
Title: Directive
Author(s): wxa
Date: 2020/6/30
Desc: 组件指令解析器
use the lib:
-------------------------------------------------------
local Compile = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Vue/Compile.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");

local Scope = NPL.load("./Scope.lua");
local Compile = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local CompileDebug = GGS.Debug.GetModuleDebug("CompileDebug").Enable();   --Enable  Disable

Compile:Property("Component");

-- local EventNameMap = {["onclick"] = true, ["onmousedown"] = true, ["onmousemove"] = true, ["onmouseup"] = true};
local DependItems = {};
local AllDependItemWatch = {};
local DependItemUpdateQueue = {};
local DependItemUpdateQueueTimer = nil;

local function GenerateDependItem(obj, key)
    if (key == nil) then return tostring(obj) end
    return  tostring(obj) .. "[" .. tostring(key) .. "]";
end

Scope.__set_global_index__(function(obj, key)
    -- CompileDebug.Format("__Index key = %s, obj = %s", key, tostring(obj));
    DependItems[GenerateDependItem(obj, key)] = true;
end)

Scope.__set_global_newindex__(function(obj, key, newVal, oldVal)
    local dependItem = GenerateDependItem(obj, key);
    -- CompileDebug.Format("__NewIndex key = %s, dependItem = %s, newVal = %s, oldVal = %s", key, dependItem, newVal, oldVal);
    if (not AllDependItemWatch[dependItem]) then return end
    -- CompileDebug.Format("__NewIndex key = %s, dependItem = %s, newVal = %s, oldVal = %s", key, dependItem, newVal, oldVal);
    DependItemUpdateQueue[dependItem] = true;
    -- table.insert(DependItemUpdateQueue, dependItem)
    if (DependItemUpdateQueueTimer) then return end
    DependItemUpdateQueueTimer = commonlib.TimerManager.SetTimeout(function()  
        DependItemUpdateQueueTimer = nil;   -- 定时并行执行的
        local DependItemUpdateMap  = {};
        for dependItem in pairs(DependItemUpdateQueue) do DependItemUpdateMap[dependItem] = true end
        for dependItem in pairs(DependItemUpdateMap) do
            DependItemUpdateQueue[dependItem] = nil;
            local objects = AllDependItemWatch[dependItem];
            for key, watchs in pairs(objects) do
                for exp, func in pairs(watchs) do
                    func();
                end
            end
        end
    end, 20)
end)

local function ExecCode(code, func, object, watch)
    DependItems = {};   -- 清空依赖集
    local oldVal = func();
    -- CompileDebug.If(code == "UserDetail", code, DependItems);

    if (object and type(watch) == "function") then
        local OldDependItems = {};
        for dependItem in pairs(DependItems) do
            OldDependItems[dependItem] = true;   -- 备份依赖项 
            AllDependItemWatch[dependItem] = AllDependItemWatch[dependItem] or {};  -- 依赖项的对象集
            AllDependItemWatch[dependItem][object] = AllDependItemWatch[dependItem][object] or {};  -- 对象的监控集
            AllDependItemWatch[dependItem][object][code] = function()  -- 监控集项
                -- 先清除
                for dependItem in pairs(OldDependItems) do
                    AllDependItemWatch[dependItem] = AllDependItemWatch[dependItem] or {};  -- 依赖项的对象集
                    AllDependItemWatch[dependItem][object] = AllDependItemWatch[dependItem][object] or {};  -- 对象的监控集
                    AllDependItemWatch[dependItem][object][code] = nil;
                end
                -- 获取新值
                local newVal = ExecCode(code, func, object, watch);
                -- 相同退出
                if (type(newVal) ~= "table" and newVal == oldVal) then return end
                -- if (newVal == oldVal and type(newVal) ~= "table" or #newVal == #oldVal) then return end
                -- 不同触发回调
                watch(newVal, oldVal);
            end
        end
    end
    return oldVal;
end

function Compile:GetScope()
    return self:GetComponent():GetScope();
end

function Compile:ExecCode(code, object, watch, isExecWatch)
    if (type(code) ~= "string" or code == "") then return end

    local func, errmsg = loadstring("return (" .. code .. ")");
    if (not func) then return CompileDebug("Exec Code Error: " .. errmsg) end

    setfenv(func, self:GetScope());

    local val = ExecCode(code, func, object, watch);
    if (isExecWatch and type(watch) == "function") then watch(val) end

    return val;
end

-- 移除监控
function Compile:UnWatch(object)
    if (not object) then return end
    for key, watch in pairs(AllDependItemWatch) do
        AllDependItemWatch[key][object] = nil;
    end
end

-- 移除元素的监控
function Compile:UnWatchElement(element)
    self:UnWatch(element);
    for childElement in element:ChildElementIterator() do
        self:UnWatchElement(childElement);
    end
end

-- text
function Compile:Text(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "string") then return end
    local args = ""
    local text = string.gsub(xmlNode, "{{(.-)}}", function(code)
        args = args .. ", " .. code;
        return "%s";
    end)
    local code = string.format([[string.format("%s"%s)]], text, args);
    self:ExecCode(code, element, function(value)
        element:SetText(value);
    end, true);
end

-- ref
function Compile:Ref(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr or xmlNode.attr["ref"] == nil) then return end
    self:GetComponent():SetRef(xmlNode.attr["ref"], element);
end

-- v-show 
function Compile:VShow(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr or xmlNode.attr["v-show"] == nil) then return end
    self:ExecCode(xmlNode.attr["v-show"], element, function(val)
        element:SetVisible(val and true or false);
        local parentElement = element:GetParentElement();
        if (parentElement) then parentElement:UpdateLayout() end
    end, true);
end

-- v-if
function Compile:VIf(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr or xmlNode.attr["v-if"] == nil) then return end
    local vif = true;
    local curElement = element;
    local parentElement = element:GetParentElement();
    local ifComponent = self:GetComponent();
    self:ExecCode(xmlNode.attr["v-if"], element, function(val)
        val = val and true or false;
        if (val) then
            if (not vif) then
                local newElement = curElement:Clone();
                parentElement:ReplaceChildElement(curElement, newElement);
                curElement = newElement;
                local oldComponent = self:GetComponent();
                self:SetComponent(ifComponent);
                self:CompileElement(curElement);
                self:SetComponent(oldComponent);
            end
            curElement:SetVisible(true);
        else
            curElement:SetVisible(false);
        end
        vif = val;
        if (parentElement) then parentElement:UpdateLayout(true) end
    end, true);
end

-- v-for
function Compile:VFor(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr or xmlNode.attr["v-for"] == nil) then return end
    local vfor = xmlNode.attr["v-for"];

    local keyexp, listexp = string.match(vfor, "%(?(%a[%w%s,]*)%)?%s+in%s+(%w*)");
    if (not keyexp) then return end

    local val, key = string.match(keyexp, "(%a%w-)%s*,%s*(%a%w+)");
    if (not val) then val = string.gsub(keyexp, "[,%s]*$", "") end

    local lastCount, clones, scopes = 0, {}, {};
    local parentElement = element:GetParentElement();
    local pos = parentElement:GetChildElementPos(element);
    local forComponent = self:GetComponent();

    element:SetVisible(false);
    self:ExecCode(listexp, element, function(list)
        local count = type(list) == "number" and list or (type(list) == "table" and #list or 0);
        -- CompileDebug.Format("VFor ComponentTagName = %s, ComponentId = %s, key = %s, val = %s, listexp = %s, List Count = %s", forComponent:GetTagName(), forComponent:GetAttrValue("id"), key, val, listexp, count);
        local oldComponent = self:GetComponent();
        self:SetComponent(forComponent)
        for i = 1, count do
            clones[i] = clones[i] or element:Clone();
            local clone = clones[i];

            clone:GetXmlNode().attr["v-for"] = nil;
            self:UnWatch(clone);
            if (i > lastCount) then parentElement:InsertChildElement(pos + i, clone) end

            local scope = scopes[i] or {};
            scope[key or "index"] = i;
            if (type(list) == "table") then
                scope[val] = list[i];
            else
                scope[val] = i; 
            end

            -- 产生新scope压入scope栈
            scopes[i] = self:GetComponent():PushScope(scope);

            -- 解析当前节点重新
            self:CompileElement(clone);

            -- 弹出scope栈
            self:GetComponent():PopScope();
        end
        -- 移除多余元素
        for i = count + 1, lastCount do
            self:UnWatch(clones[i]);
            parentElement:RemoveChildElement(clones[i]);
        end
        lastCount = count;
        parentElement:UpdateLayout(true);
        self:SetComponent(oldComponent);
    end, true);

    return true;
end

-- v-on:event=function
function Compile:VOn(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr) then return end
    for key, val in pairs(xmlNode.attr) do
        local realKey = string.match(key, "^v%-on:(%S+)");
        local realVal = val;
        if (not realKey or realKey == "") then realKey = string.match(key, "^on(%S+)") end
        if (realKey and realKey ~= "" and type(val) == "string") then
            -- 以括号结束则当做函数调用  
            local isFuncCall = string.match(val, "%S+%(.*%)[;%s]*$");
            if (not isFuncCall) then 
                -- 不是函数调用则获取函数
                realVal = self:ExecCode(val);
                if (type(realVal) ~= "function") then CompileDebug.Format("invalid function listen, realKey = %s, realVal = %s, key = %s, val = %s", realKey, realVal, key, val) end
            else
                -- 函数调用则返回字符串函数
                local code_func, errmsg = loadstring(val);
                if (code_func) then
                    -- 这里使用合适的作用作用域
                    setfenv(code_func, self:GetComponent():GetScope());
                    realVal = code_func;
                else
                    realVal = function() echo("null function") end;
                end
            end
            element:SetAttrValue("on" .. realKey, realVal);
        end
    end
end

-- v-bind
function Compile:VBind(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr) then return end
    for key, val in pairs(xmlNode.attr) do
        local realKey = string.match(key, "^v%-bind:(.+)");
        local realVal = nil;
        if (realKey and realKey ~= "") then
            self:ExecCode(val, element, function(realVal)
                if (type(realVal) == "table" and realVal.__get_raw_data__) then realVal = realVal:__get_raw_data__() end
                element:SetAttrValue(realKey, realVal);
            end, true);
        end
    end
end

-- v-model
function Compile:VModel(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr or xmlNode.attr["v-model"] == nil) then return end
    local vmodel = xmlNode.attr["v-model"];
    if (not string.match(vmodel, "^%a%w*$")) then return end
    local scope = self:GetScope();
    self:ExecCode(vmodel, element, function(val)
        element:SetAttrValue("value", val);
    end, true);
    -- 注意死循环
    element:SetAttrValue("onchange", function(val)
        scope[vmodel] = val;
    end)
end

function Compile:IsComponent(element)
    return element.IsComponent and element:IsComponent();
end

function Compile:CompileElement(element)
    local isComponent = self:IsComponent(element);
    local isCurrentComponentElement = self:GetComponent() == element;
    if (not isCurrentComponentElement) then
        
        if (self:VFor(element)) then return end

        self:Text(element);
        self:Ref(element);
        self:VShow(element);  
        self:VIf(element);  
        self:VOn(element);
        self:VBind(element);
        self:VModel(element);
    end

    if (isComponent and not isCurrentComponentElement) then return end

    -- 编译子元素
    for childElement in element:ChildElementIterator() do
        self:CompileElement(childElement);
    end
end

function Compile:Compile(compoent)
    self:SetComponent(compoent);
    self:CompileElement(compoent);
end

local metatable = getmetatable(Compile);
metatable.__call = function(self, ...)
    self:Compile(...);
end

-- 初始化成单列模式
Compile:InitSingleton();