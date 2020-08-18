--[[
Title: ui
Author(s): wxa
Date: 2020/6/30
Desc: UI 入口文件, 实现组件化开发
use the lib:
-------------------------------------------------------
local ui = NPL.load("Mod/GeneralGameServerMod/App/ui/ui.lua");
ui:ShowWindow();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/mcml.lua");
NPL.load("(gl)script/ide/System/Windows/Window.lua");
local mcml = commonlib.gettable("System.Windows.mcml");
local Component = NPL.load("./Core/Component.lua");
local App = NPL.load("./Core/App.lua");
local Slot = NPL.load("./Core/Slot.lua");

local ui = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local IsDevEnv = ParaEngine.GetAppCommandLineByParam("IsDevEnv","false") == "true";
local __FILE__ = debug.getinfo(1,'S').source;
local __DIRECTORY__ = string.match(__FILE__, "^.*/");

-- UIWindow
local UIWindow = commonlib.inherit(commonlib.gettable("System.Windows.Window"), {});

UIWindow:Property("UIWindow", true, "IsUIWindow");
UIWindow:Property("UI");

-- 当前窗口
ui.window = nil; 

-- 构造函数
function ui:ctor()
    self.window = nil;
end

-- 获取文件
function ui:GetFilePath(relUiPath)
    return __DIRECTORY__ .. relUiPath;
end

-- 注册组件
function ui:Register(tagname, tagclass)
    return Component:Register(tagname, tagclass);
end

-- 定义组件
function ui:Component(opts)
    return Component:Extend(opts);
end

-- 获取全局表
function ui:GetGlobalTable()
    if (self.global) then return self.global end
    self.global = { ui = self};
    setmetatable(self.global, {__index = _G});
    return self.global;
end

-- 获取窗口
function ui:GetWindow(url, isNewNoExist)
    if (not rawget(self, "window")) then
        self.window = UIWindow:new();
        self.window:Connect("windowClosed", self, "OnWindowClosed", "UniqueConnection");
        self.window:SetUI(self);
    end
    if (IsDevEnv) then self.window.url = nil end
    return self.window;
end

-- 显示窗口
function ui:ShowWindow(params)
    params = params or {};
    local url = params.url or self:GetFilePath("ui.html");
    if (params.alignment == nil) then params.alignment = "_ct" end
    if (params.width == nil) then params.width = 500 end
    if (params.height == nil) then params.height = 400 end
    if (params.left == nil) then params.left = -params.width / 2 end
    if (params.top == nil) then params.top = -params.height / 2 end
    if (params.allowDrag == nil) then params.allowDrag = true end

    params.url = ParaXML.LuaXML_ParseString(params.mcml or string.format([[
        <pe:mcml style="width: %spx; height: %spx;">
            <App filename="%s"></App>
        </pe:mcml>
    ]], params.width, params.height, url));

    -- 关闭销毁
    params.DestroyOnClose = true;
    -- 强制更新全局表
    params.pageGlobalTable = self:GetGlobalTable();

    return self:GetWindow():Show(params);
end

-- 关闭窗口
function ui:CloseWindow()
    if (not self.window) then return end
    self.window:CloseWindow();
end

-- 窗口关闭回调
function ui:OnWindowClosed()
    self.window = nil;
end

-- 静态初始化
local function StaticInit()
    ui:Register("App", App);
    ui:Register("Slot", Slot);

    ui:Register("WindowTitleBar", { filename = ui:GetFilePath("Component/WindowTitleBar.html")});
    ui:Register("UserInfo", { filename = ui:GetFilePath("Component/UserInfo.html")});
    ui:Register("WorksList", { filename = ui:GetFilePath("Component/WorksList.html")});
    ui:Register("Test", { filename = ui:GetFilePath("Component/Test.html")});
end

StaticInit();