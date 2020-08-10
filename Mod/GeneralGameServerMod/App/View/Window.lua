--[[
Title: window
Author(s): wxa
Date: 2020/6/30
Desc: 视图基类
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/App/View/Window.lua");
local Window = commonlib.gettable("Mod.GeneralGameServerMod.App.View.Window");
-------------------------------------------------------
]]
-- load component
NPL.load("Mod/GeneralGameServerMod/App/View/Component.lua");

NPL.load("(gl)script/ide/System/Windows/Window.lua");
local SystemWindow = commonlib.gettable("System.Windows.Window")

local Window = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.App.View.Window"));
local IsDevEnv = ParaEngine.GetAppCommandLineByParam("IsDevEnv","false") == "true";

Window.window = nil;

function Window:ctor()
end

function Window:Show(params)
    if (not self.window) then
        self.window = SystemWindow:new();
    end
    
    -- 开发环境强制重新加载页面
    if (IsDevEnv) then self.window.url = nil end

    if (params.url == nil) then params.url = "Mod/GeneralGameServerMod/App/View/Window.html" end
    if (params.alignment == nil) then params.alignment = "_ct" end
    if (params.width == nil) then params.width = 500 end
    if (params.height == nil) then params.height = 400 end
    if (params.left == nil) then params.left = -params.width / 2 end
    if (params.top == nil) then params.top = -params.height / 2 end
    if (params.allowDrag == nil) then params.allowDrag = true end

    return self.window:Show(params);
end

function Window:Close()
    if (not self.window) then return end
    
    self.window:CloseWindow();
end

function Window.OnClose()
    Window:Close();
end

Window:InitSingleton();