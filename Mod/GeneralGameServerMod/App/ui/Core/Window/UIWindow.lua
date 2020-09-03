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
-- local UIWindow = commonlib.inherit(commonlib.gettable("System.Windows.Window"), NPL.export());
-- local ElementLayout = NPL.load("./ElementLayout.lua");
local UIWindow = commonlib.inherit(commonlib.gettable("System.Windows.Window"), commonlib.gettable("UIWindow"));

UIWindow:Property("UIWindow", true, "IsUIWindow");
UIWindow:Property("UI");

-- function UIWindow:UpdateLayout(pageLayout, rootElement)
--     local ElementLayout = commonlib.gettable("ElementLayout");
--     -- 获取窗体宽高
--     local width, height = self:width(), self:height();
--     -- 顶层布局
--     local rootParentElementLayout = ElementLayout:new():Init(nil);
--     -- 设置宽高
--     rootParentElementLayout:SetWidthHeight(width, height);
--     -- 更新元素布局
--     rootParentElementLayout:UpdateElementLayout(rootElement);
-- end