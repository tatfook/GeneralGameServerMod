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

local StyleSheetId = 0;
function StyleSheet:ctor()
    StyleSheetId = StyleSheetId + 1;
    self.id = StyleSheetId;
    self.selectors = {};
end

function StyleSheet:LoadByString(code)
    code = string.gsub(code,"/%*.-%*/","");
    for selector_str,declaration_str in string.gmatch(code,"([^{}]+){([^{}]+)}") do
        local style = Style.ParseString(declaration_str);
        for selector in string.gmatch(selector_str,"([^,]+),?") do
            selector = string.match(selector,"^%s*(.-)%s*$");
            self.selectors[selector] = style;
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
