--[[
Title: StyleManager
Author(s): wxa
Date: 2020/6/30
Desc: 样式管理类
use the lib:
-------------------------------------------------------
local StyleSheet = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Style/StyleSheet.lua");
-------------------------------------------------------
]]

local Style = NPL.load("./Style.lua", IsDevEnv);
local StyleSheet = commonlib.inherit(nil, NPL.export());
local StyleSheetDebug = GGS.Debug.GetModuleDebug("StyleSheetDebug").Enable();   --Enable  Disable

local function StringTrim(str, ch)
    ch = ch or "%s";
    str = string.gsub(str, "^" .. ch .. "*", "");
    str = string.gsub(str, ch .. "*$", "");
    return str;
end

-- 获取尾部选择器
local function GetTailSelector(comboSelector)
    if (not comboSelector) then return end

    comboSelector = string.gsub(comboSelector, "%s*$", "");
    -- 后代选择器 div p
    local selector = string.match(comboSelector, "%s* ([^%s%+%~%>]-)$");
    if (selector) then return selector, " ", string.gsub(comboSelector, "%s* [^%s%+%~%>]-$", "") end

    -- 子选择器 div>p
    selector = string.match(comboSelector, "%s*%>%s*([^%s%+%~%>]-)$");
    if (selector) then return selector, ">", string.gsub(comboSelector, "%s*%>%s*[^%s%+%~%>]-$", "") end

    -- 后续兄弟选择器 div~p
    selector = string.match(comboSelector, "%s*%~%s*([^%s%+%~%>]-)$");
    if (selector) then return selector, "~", string.gsub(comboSelector, "%s*%~%s*[^%s%+%~%>]-$", "") end

    -- 相邻兄弟选择器 div+p
    selector = string.match(comboSelector, "%s*%+%s*([^%s%+%~%>]-)$");
    if (selector) then return selector, "+", string.gsub(comboSelector, "%s*%+%s*[^%s%+%~%>]-$", "") end

    return nil;
end

-- 是否是有效的元素选择器
local function IsValidElementSelector(selector, element)
    local elementSelector = element:GetSelector();
    if (not selector or not elementSelector[selector]) then return false end
    if ((string.match(selector, ":hover%s*$")) and not element:IsHover()) then return false end
    return true;
end
-- 是否是祖先元素的选择器
local function IsAncestorElementSelector(element, selector)
    local parentElement = element:GetParentElement();
    if (not parentElement) then return false end
    if (IsValidElementSelector(selector, parentElement)) then return true, parentElement end
    return IsAncestorElementSelector(parentElement, selector);
end

-- 是否是元素的选择器
local function IsElementSelector(comboSelector, element)
    local selector, selectorType, newComboSelector = GetTailSelector(comboSelector, element);
    if (not IsValidElementSelector(selector, element)) then return false end
    local newSelector, newSelectorType = GetTailSelector(newComboSelector);
    newSelector = StringTrim(newSelector or newComboSelector);
    -- 后代选择器 div p
    if (selectorType == " ") then
        local isAncestorElementSelector, ancestorElement = IsAncestorElementSelector(element, newSelector);
        if (not isAncestorElementSelector) then return false end
        if (not newSelectorType) then return true end
        return IsElementSelector(newComboSelector, ancestorElement);
    end

    -- 子选择器 div>p
    if (selectorType == ">") then
        local parentElement = element:GetParentElement();
        if (not parentElement) then return false end
        if (not IsValidElementSelector(newSelector, parentElement)) then return false end
        if (not newSelectorType) then return true end
        return IsElementSelector(newComboSelector, parentElement);
    end

    -- 后续兄弟选择器 div~p
    if (selectorType == "~") then
        local prevSiblingElement = element:GetPrevSiblingElement();
        while (prevSiblingElement) do
            if (IsValidElementSelector(newSelector, prevSiblingElement)) then break end
            prevSiblingElement = prevSiblingElement:GetPrevSiblingElement();
        end
        if (not prevSiblingElement) then return false end
        if (not newSelectorType) then return true end
        return IsElementSelector(newComboSelector, prevSiblingElement);
    end

    -- 相邻兄弟选择器 div+p
    if (selectorType == "+") then
        -- StyleSheetDebug.If(element:GetAttrStringValue("id") == "debug", "--------------------------------------1");
        local prevSiblingElement = element:GetPrevSiblingElement();
        if (not prevSiblingElement) then return false end
        -- StyleSheetDebug.If(element:GetAttrStringValue("id") == "debug", "--------------------------------------2", prevSiblingElementSelector, newSelector, newComboSelector, selector, comboSelector);
        if (not IsValidElementSelector(newSelector, prevSiblingElement)) then return false end
        -- StyleSheetDebug.If(element:GetAttrStringValue("id") == "debug", "--------------------------------------3");
        if (not newSelectorType) then return true end
        -- StyleSheetDebug.If(element:GetAttrStringValue("id") == "debug", "--------------------------------------4");
        return IsElementSelector(newComboSelector, prevSiblingElement);
    end

    return false;
end

function StyleSheet:ctor()
    self.SelectorStyle = {};
end

function StyleSheet:LoadByString(code)
    code = string.gsub(code,"/%*.-%*/","");
    for selector_str, declaration_str in string.gmatch(code, "([^{}]+){([^{}]+)}") do
        local style = Style.ParseString(declaration_str);
        for selector in string.gmatch(selector_str, "([^,]+),?") do
            selector = string.match(selector, "^%s*(.-)%s*$");
            self.SelectorStyle[selector] = style;
        end
    end
    return self;
end

-- 设置基础样式表
function StyleSheet:SetInheritStyleSheet(sheet)
    self.InheritStyleSheet = sheet;
end

-- 生效选择器样式
function StyleSheet:ApplySelectorStyle(selector, style, element)
    -- 选择器默认样式
    local selectorStyle = self.SelectorStyle[selector];
    if (selectorStyle) then Style.CopyStyle(style:GetNormalStyle(), selectorStyle) end

    -- 选择器激活样式
    selectorStyle = self.SelectorStyle[selector .. ":active"];
    if (selectorStyle) then Style.CopyStyle(style:GetActiveStyle(), selectorStyle) end
    -- 选择器悬浮样式
    selectorStyle = self.SelectorStyle[selector .. ":hover"];
    if (selectorStyle) then Style.CopyStyle(style:GetHoverStyle(), selectorStyle) end

    -- 选择器聚焦样式
    selectorStyle = self.SelectorStyle[selector .. ":focus"];
    if (selectorStyle) then Style.CopyStyle(style:GetFocusStyle(), selectorStyle) end

    -- 标记选择器
    local elementSelector = element:GetSelector();
    elementSelector[selector] = true;
    elementSelector[selector .. ":active"] = true;
    elementSelector[selector .. ":hover"] = true;
    elementSelector[selector .. ":focus"] = true;
end

-- 生效类选择器样式
function StyleSheet:ApplyClassSelectorStyle(element, style)
    local classes = element:GetAttrStringValue("class",  "");
    for class in string.gmatch(classes, "%s*([^%s]+)%s*") do 
        self:ApplySelectorStyle("." .. class, style, element);
    end
end

-- 生效组合选择器样式
function StyleSheet:ApplyComboSelectorStyle(element, style)
    -- 组合样式 
    for selector in pairs(self.SelectorStyle) do
        if (IsElementSelector(selector, element)) then
            self:ApplySelectorStyle(selector, style, element);
        end
    end
end

-- 生效标签名选择器样式
function StyleSheet:ApplyTagNameSelectorStyle(element, style)
    local tagname = string.lower(element:GetTagName() or "");

    self:ApplySelectorStyle(tagname, style, element);
end

-- 生效ID选择器样式
function StyleSheet:ApplyIdSelectorStyle(element, style)
    local id = element:GetAttrStringValue("id",  "");

    if (type(id) ~= "string" and id ~= "") then 
        self:ApplySelectorStyle("#" .. id, style, element);
    end
end

-- 应用元素样式
function StyleSheet:ApplyElementStyle(element, style)
    local elementSelector = element:GetSelector();
    for key in pairs(elementSelector) do elementSelector[key] = false end
    
    local function ApplyElementStyle(sheet, element, style)
        -- 先生效基类样式
        if (sheet.InheritStyleSheet) then ApplyElementStyle(sheet.InheritStyleSheet, element, style) end

        -- 通配符*选择器
        sheet:ApplySelectorStyle("*", style, element);

        -- 便签选择器
        sheet:ApplyTagNameSelectorStyle(element, style);

        -- 类选择器
        sheet:ApplyClassSelectorStyle(element, style);
    
        -- ID选择器
        sheet:ApplyIdSelectorStyle(element, style);

        -- 选择器组合
        sheet:ApplyComboSelectorStyle(element, style);
    end

    ApplyElementStyle(self, element, style);
end

function StyleSheet:Clear()
    self.SelectorStyle = {};
end