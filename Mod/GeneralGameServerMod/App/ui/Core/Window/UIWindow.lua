--[[
Title: ui
Author(s): wxa
Date: 2020/6/30
Desc: UI Window
use the lib:
-------------------------------------------------------
local UIWindow = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/UIWindow.lua");
-------------------------------------------------------
]]
-- UIWindow

local Element = NPL.load("./Element.lua", IsDevEnv and true or nil);
local ElementLayout = NPL.load("./ElementLayout.lua", IsDevEnv and true or nil);
local ElementManager = NPL.load("./ElementManager.lua", IsDevEnv and true or nil);
local UIWindow = commonlib.inherit(commonlib.gettable("System.Windows.Window"), NPL.export());

Element.SetElementManager(ElementManager);            -- 设置元素管理器

UIWindow:Property("UIWindow", true, "IsUIWindow");    -- 是否是UIWindow
UIWindow:Property("UI");                              -- 窗口绑定的UI对象
UIWindow:Property("EnableElementLayout", false, "IsEnableElementLayout");   -- 是否启用元素布局

function UIWindow:ctor()
end

function UIWindow:UpdateLayout(pageLayout, rootElement)
    -- 获取窗体宽高
    local width, height = self:width(), self:height();
    -- 顶层布局
    local rootParentElementLayout = ElementLayout:new():Init(nil, nil, self);
    -- 设置宽高
    rootParentElementLayout:SetWidthHeight(width, height);
    -- 更新元素布局
    rootParentElementLayout:UpdateElementLayout(rootElement);
end


function UIWindow:Show(params)
    -- if (IsDevEnv) then self:SetEnableElementLayout(true) end

    UIWindow._super.Show(self, params);
end

function UIWindow:CloseWindow()
    UIWindow._super.CloseWindow(self);
end