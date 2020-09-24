--[[
Title: ElementManager
Author(s): wxa
Date: 2020/6/30
Desc: 元素管理器
use the lib:
-------------------------------------------------------
local ElementManager = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/ElementManager.lua");
-------------------------------------------------------
]]
-- NPL.load("(gl)script/ide/System/Windows/mcml/mcml.lua");
-- local mcml = commonlib.gettable("System.Windows.mcml");
-- -- 初始化基本元素
-- mcml:StaticInit();

local Element = NPL.load("./Element.lua", IsDevEnv);
local Html = NPL.load("./Elements/Html.lua", IsDevEnv);
local Div = NPL.load("./Elements/Div.lua", IsDevEnv);
local Text = NPL.load("./Elements/Text.lua", IsDevEnv);
local Button = NPL.load("./Elements/Button.lua", IsDevEnv);

local ElementManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

ElementManager.ScrollBar = NPL.load("./Controls/ScrollBar.lua", IsDevEnv);

local ElementClassMap = {};

function ElementManager:ctor()
    -- 注册元素
    ElementManager:RegisterByTagName("Html", Html);
    ElementManager:RegisterByTagName("Div", Div);
    ElementManager:RegisterByTagName("Text", Text);
    ElementManager:RegisterByTagName("Button", Button);
end

function ElementManager:RegisterByTagName(tagname, class)
    ElementClassMap[string.lower(tagname)] = class;
end

function ElementManager:GetElementByTagName(tagname)
    return ElementClassMap[string.lower(tagname)] or Element;
end


-- 初始化成单列模式
ElementManager:InitSingleton();