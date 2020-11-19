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

function StyleSheet:ctor()
end

function StyleSheet:LoadByString(code)
    code = string.gsub(code,"/%*.-%*/","");
    for selector_str, declaration_str in string.gmatch(code, "([^{}]+){([^{}]+)}") do
        local style = Style.ParseString(declaration_str);
        for selector in string.gmatch(selector_str, "([^,]+),?") do
            selector = string.match(selector, "^%s*(.-)%s*$");
            self[selector] = style;
        end
    end
    return self;
end

-- 设置基础样式表
function StyleSheet:SetInheritStyleSheet(sheet)
    self.InheritStyleSheet = sheet;
end

-- 生效选择器样式
function StyleSheet:ApplySelectorStyle(selector, style)
    -- 选择器默认样式
    local selectorStyle = self[selector];
    if (selectorStyle) then Style.CopyStyle(style:GetNormalStyle(), selectorStyle) end

    -- 选择器激活样式
    selectorStyle = self[selector .. ":active"];
    if (selectorStyle) then Style.CopyStyle(style:GetActiveStyle(), selectorStyle) end

    -- 选择器悬浮样式
    selectorStyle = self[selector .. ":hover"];
    if (selectorStyle) then Style.CopyStyle(style:GetHoverStyle(), selectorStyle) end

    -- 选择器聚焦样式
    selectorStyle = self[selector .. ":focus"];
    if (selectorStyle) then Style.CopyStyle(style:GetFocusStyle(), selectorStyle) end
end

function StyleSheet:ApplyClassSelectorStyle(element, style)
    local function isSelectorElement(selector, element)
        -- 后代选择器 div p

        -- 子选择器 div>p

        -- 后续兄弟选择器 div~p

        -- 相邻兄弟选择器 div+p
    end
    local function ApplyComboClassSelectorStyle(selector, style)
        local selectorLength = string.len(selector);
        -- 组合样式 
        for key, val in pairs(self) do
            local preudo = string.match(key, ":([^:]+)$");
            local preudolen = preudo and (string.len(preudo) + 1) or 0;
            local keylen = string.len(key);
            if (string.sub(keylen - selectorLength - preudolen + 1, keylen - preudolen) == selector) then
                local selector = string.sub(key, 1, keylen - selectorLength - preudolen);
                if (isSelectorElement(selector, element)) then
                    
                end
            end
        end
    end

    local classes = element:GetAttrStringValue("class",  "");
    for class in string.gmatch(classes, "%s*([^%s]+)%s*") do 
        local classSelector = "." .. class;
        
        self:ApplySelectorStyle(classSelector, style);

        ApplyComboClassSelectorStyle(classSelector, style);
    end
end

-- 生效标签名选择器样式
function StyleSheet:ApplyTagNameSelectorStyle(element, style)
    local tagname = string.lower(element:GetTagName() or "");

    self:ApplySelectorStyle(tagname, style);
end

-- 生效ID选择器样式
function StyleSheet:ApplyIdSelectorStyle(element, style)
    local id = element:GetAttrStringValue("id",  "");

    if (type(id) ~= "string" and id ~= "") then 
        self:ApplySelectorStyle("#" .. id, style);
    end
end


function StyleSheet:ApplyElementStyle(element, style)
    local selector = element:GetSelector();
    for key in pairs(selector) do selector[key] = false end
    
    local function ApplyElementStyle(sheet, element, style)
        -- 先生效基类样式
        if (sheet.InheritStyleSheet) then ApplyElementStyle(sheet.InheritStyleSheet, element, style) end

        sheet:ApplyTagNameSelectorStyle(element, style);

        sheet:ApplyClassSelectorStyle(element, style);
    
        sheet:ApplyIdSelectorStyle(element, style);
    end

    ApplyElementStyle(self, element, style);
end

function StyleSheet:Clear()
    for key, val in pairs(self) do
        self[key] = nil;
    end
end