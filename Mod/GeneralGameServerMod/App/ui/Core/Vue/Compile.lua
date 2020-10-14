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

local Scope = NPL.load("./Scope.lua");

local Compile = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local CompileDebug = GGS.Debug.GetModuleDebug("CompileDebug").Enable();   --Enable  Disable

Compile:Property("Component");

local function GenerateDependItem(obj, key)
    if (key == nil) then return tostring(obj) end
    return  tostring(obj) .. "[" .. tostring(key) .. "]";
end
-- local EventNameMap = {["onclick"] = true, ["onmousedown"] = true, ["onmousemove"] = true, ["onmouseup"] = true};
local DependItems = {};
local AllDependItemWatch = {};
local DependItemUpdateQueue = {};
local DependItemUpdateQueueTimer = nil;

Scope.__SetIndex(function(obj, key)
    -- CompileDebug.Format("__Index key = %s", key);
    DependItems[GenerateDependItem(obj, key)] = true;
end)

Scope.__SetNewIndex(function(obj, key, newVal, oldVal)
    -- CompileDebug.Format("__NewIndex key = %s, newVal = %s, oldVal = %s", key, newVal, oldVal);
    local dependItem = GenerateDependItem(obj, key);
    if (not AllDependItemWatch[dependItem]) then return end
    table.insert(DependItemUpdateQueue, dependItem)

    if (DependItemUpdateQueueTimer) then return end
    DependItemUpdateQueueTimer = commonlib.TimerManager.SetTimeout(function()  
        for _, dependItem in ipairs(DependItemUpdateQueue) do
            local objects = AllDependItemWatch[dependItem];
            for key, watchs in pairs(objects) do
                for exp, func in pairs(watchs) do
                    func();
                end
            end
        end
        DependItemUpdateQueue = {};
        DependItemUpdateQueueTimer = nil;
    end, 10)
end)

function Compile:ExecCode(code, object, watch, isExecWatch)
    if (type(code) ~= "string" or code == "") then return end

    local code_func, errmsg = loadstring("return (" .. code .. ")");
    if (not code_func) then return CompileDebug("Exec Code Error: " .. errmsg) end

    setfenv(code_func, self:GetComponent():GetScope());

    DependItems = {};   -- 清空依赖集
    local oldVal = code_func();
    -- CompileDebug.If(code == "List", code, DependItems);
    if (object and type(watch) == "function") then
        for dependItem in pairs(DependItems) do
            AllDependItemWatch[dependItem] = AllDependItemWatch[dependItem] or {};  -- 依赖项的对象集
            AllDependItemWatch[dependItem][object] = AllDependItemWatch[dependItem][object] or {};  -- 对象的监控集
            AllDependItemWatch[dependItem][object][code] = function()  -- 监控集项
                local newVal = code_func();
                if (type(newVal) ~= "table" and newVal == oldVal) then return end
                watch(newVal, oldVal);
                oldVal = newVal;
            end
        end
        if (isExecWatch) then watch(oldVal) end
    end

    return oldVal;
end

-- 移除监控
function Compile:UnWatch(element)
    if (not object) then return end
    for key, watch in pairs(AllDependItemWatch) do
        AllDependItemWatch[key][object] = nil;
    end
    for childElement in element:ChildElementIterator() do
        self:UnWatch(childElement);
    end
end

-- text
function Compile:Text(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "string") then return end
    local function watch()
        local text = string.gsub(xmlNode, "{{(.-)}}", function(code)
            return self:ExecCode(code, element, watch) or "";
        end)
        element:SetText(text)
    end
    watch();
end

-- ref
function Compile:Ref(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr or xmlNode.attr["ref"] == nil) then return end
    self:GetComponent():SetRef(xmlNode.attr["ref"], element);
end

-- v-if
function Compile:VIf(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr or xmlNode.attr["v-if"] == nil) then return end
    self:ExecCode(xmlNode.attr["v-if"], element, function(val)
        element:SetVisible(val and true or false);
    end, true);
end

-- v-for
function Compile:VFor(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr or xmlNode.attr["v-for"] == nil) then return end
    local vfor = xmlNode.attr["v-for"];
    element:SetVisible(false);

    local keyexp, listexp = string.match(vfor, "%(?(%a[%w%s,]*)%)?%s+in%s+(%w*)");
    if (not keyexp) then return end

    local val, key = string.match(keyexp, "(%a%w-)%s*,%s*(%a%w-)");
    if (not val) then val = keyexp end

    local lastCount, clones, scopes = 0, {}, {};
    local parentElement = element:GetParentElement();
    local pos = parentElement:GetChildElementPos(element);
    self:ExecCode(listexp, element, function(list)
        local count = type(list) == "number" and list or (type(list) == "table" and #list or 0);
        -- CompileDebug.Format("VFor List Count = %s", count);
        for i = 1, count do
            if (not clones[i]) then 
                local cloneXmlNode = commonlib.deepcopy(xmlNode);
                cloneXmlNode.attr["v-for"] = nil;
                clones[i] = element:CreateFromXmlNode(cloneXmlNode, element:GetWindow(), parentElement);
            end
            self:UnWatch(clones[i]);
            if (i > lastCount) then
                parentElement:InsertChildElement(pos + i, clones[i]);
            end
            -- v-for 产生新scope
            local scope = scopes[i] or {};
            scope[key or "key"] = i;
            if (type(list) == "table") then
                scope[val] = list[i];
            else
                scope[val] = i; 
            end
            -- 产生新scope压入scope栈
            scopes[i] = self:GetComponent():PushScope(scope);
            -- 解析当前节点重新
            self:CompileElement(clones[i]);
            -- 弹出scope栈
            self:GetComponent():PopScope();
        end
        -- 移除多余元素
        for i = count + 1, lastCount do
            self:UnWatch(clones[i]);
            parentElement:RemoveChildElement(clones[i]);
        end
        lastCount = count;
        parentElement:UpdateLayout();
    end, true);
end

-- v-on:event=function
function Compile:VOn(element)
    local xmlNode = element:GetXmlNode();
    if (type(xmlNode) ~= "table" or not xmlNode.attr) then return end
    for key, val in pairs(xmlNode.attr) do
        local realKey = string.match(key, "^v%-on:(%S+)");
        local realVal = val;
        if (not realKey or realKey == "") then realKey = string.match(key, "on(%S+)") end
        if (realKey and realKey ~= "" and type(val) == "string") then
            -- 以括号结束则当做函数调用  
            local isFuncCall = string.match(val, "%S+%(.*%)[;%s]*$");
            if (not isFuncCall) then 
                -- 不是函数调用则获取函数
                realVal = self:ExecCode(val);
                if (type(realVal) ~= "function") then echo("invalid function listen") end
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
            realVal = self:ExecCode(val);
            element:SetAttrValue(realKey, realVal);
        end
    end
end

function Compile:IsComponent(element)
    return element.IsComponent and element:IsComponent();
end

function Compile:CompileElement(element, isSkipComponentElement)
    local isComponent = self:IsComponent(element);
    if (isComponent) then element:OnBeforeCompile() end

    if (not isComponent or not isSkipComponentElement) then
        self:VFor(element);
        self:Text(element);
        self:Ref(element);
        self:VIf(element);  
        self:VOn(element);
        self:VBind(element);
    end
    -- 是组件且不为当前组件, 则编译子组件
    if (isComponent and self:GetComponent() ~= element) then
        self:Compile(element, true);
    else 
        -- 编译子元素
        for childElement in element:ChildElementIterator() do
            self:CompileElement(childElement);
        end
    end
    
    if (isComponent) then element:OnAfterCompile() end
end

function Compile:Compile(compoent, isSkipComponentElement)
    self:SetComponent(compoent);
    self:CompileElement(compoent, isSkipComponentElement);

    -- 执行组件OnRefresh回调
    self:ExecCode([[type(OnReady) == "function" and OnReady()]]);
end

local metatable = getmetatable(Compile);
metatable.__call = function(self, ...)
    self:Compile(...);
end

-- 初始化成单列模式
Compile:InitSingleton();