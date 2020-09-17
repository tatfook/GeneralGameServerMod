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
NPL.load("(gl)script/ide/System/Windows/mcml/mcml.lua");
local mcml = commonlib.gettable("System.Windows.mcml");
-- 初始化基本元素
mcml:StaticInit();

local Html = NPL.load("./Elements/Html.lua", true);
local Text = NPL.load("./Elements/Text.lua", true);
local Button = NPL.load("./Elements/Button.lua", true);

local ElementManager = NPL.export();
local ElementClassMap = {};

function ElementManager.StaticInit()
    -- 注册元素
    ElementManager.RegisterByTagName("Html", Html);
    ElementManager.RegisterByTagName("Text", Text);
    ElementManager.RegisterByTagName("Button", Button);
end

function ElementManager.RegisterByTagName(tagname, class)
    ElementClassMap[tagname] = class;
    -- mcml:RegisterPageElement(tagname, class);
end

function ElementManager.GetElementByTagName(tagname)
    return ElementClassMap[tagname] or mcml:GetClassByTagName(tagname);
end

ElementManager.StaticInit();