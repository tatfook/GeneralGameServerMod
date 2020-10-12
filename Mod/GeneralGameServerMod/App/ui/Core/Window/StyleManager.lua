--[[
Title: StyleManager
Author(s): wxa
Date: 2020/6/30
Desc: 样式管理类
use the lib:
-------------------------------------------------------
local StyleManager = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/StyleManager.lua");
-------------------------------------------------------
]]

local Style = NPL.load("./Style.lua", IsDevEnv);
local StyleManager = commonlib.inherit(nil, NPL.export());
local StyleSheet = commonlib.inherit(nil, {});

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
end

function StyleManager:ctor()
    self.styleSheets = {};  -- 样式表集
end

function StyleManager:AddStyleSheetByString(code)
    local styleSheet = StyleSheet:new();
    styleSheet:LoadByString(code);
    self:AddStyleSheet(styleSheet);
    return styleSheet;
end

function StyleManager:AddStyleSheet(styleSheet)
    table.insert(self.styleSheets, styleSheet);
    self.styleSheets[styleSheet] = styleSheet;
end

function StyleManager:RemoveStyleSheet(styleSheet)
    for i, sheet in ipairs(self.styleSheets) do
        if (sheet == styleSheet) then
            table.remove(self.styleSheets, i);
            break;
        end
    end
end

function StyleManager:Clear()
    self.styleSheets = {};
end

function StyleManager:ApplyClassStyle(classes, style, element)
    local styleSheets = self.styleSheets;

    local function isSelectorElement(selector, element)
        -- 后代选择器 div p

        -- 子选择器 div>p

        -- 后续兄弟选择器 div~p

        -- 相邻兄弟选择器 div+p
    end
    local function applyClassStyle(class, style)
        class = "." .. class;
        for _, sheet in ipairs(styleSheets) do
            -- 默认样式
            Style.CopyStyle(style:GetNormalStyle(), sheet[class]);
            
            -- 伪类样式

            -- 激活样式
            Style.CopyStyle(style:GetActiveStyle(), sheet[class .. ":active"]);
            -- 悬浮样式
            Style.CopyStyle(style:GetHoverStyle(), sheet[class .. ":hover"]);
            -- 聚焦样式
            Style.CopyStyle(style:GetFocusStyle(), sheet[class .. ":focus"]);

            local classlen = string.len(class);
            -- 组合样式 
            for key, val in pairs(sheet) do
                local preudo = string.match(key, ":([^:]+)$");
                local preudolen = preudo and (string.len(preudo) + 1) or 0;
                local keylen = string.len(key);
                if (string.sub(keylen - classlen - preudolen + 1, keylen - preudolen) == class) then
                    local selector = string.sub(key, 1, keylen - classlen - preudolen);
                    if (isSelectorElement(selector, element)) then
                        
                    end
                end
            end

        end
    end
    for class in string.gmatch(classes, "%s*([^%s]+)%s*") do 
        applyClassStyle(class, style);
    end
end
