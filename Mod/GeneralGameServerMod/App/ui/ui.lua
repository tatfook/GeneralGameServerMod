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
local UIWindow = NPL.load("./Core/Window/UIWindow.lua");
local Component = NPL.load("./Core/Component.lua");
local App = NPL.load("./Core/App.lua");
local Slot = NPL.load("./Core/Slot.lua");
local Helper = NPL.load("./Core/Helper.lua");
local Scope = NPL.load("./Core/Scope.lua");
local ui = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local IsDevEnv = ParaEngine.GetAppCommandLineByParam("IsDevEnv","false") == "true";
local __FILE__ = debug.getinfo(1,'S').source;
local __DIRECTORY__ = string.match(__FILE__, "^(.*)/");

function _G.TraceStack(dept)
    dept = dept or 50;
    for i = 1, dept do
        local lastInfo = debug.getinfo(i - 1);
        local info = debug.getinfo(i);
        if info then
            print("TraceStack",info.source, info.currentline, lastInfo and lastInfo.name);
        else
            break;
        end
    end
end

-- 当前窗口
ui.window = nil; 

-- 构造函数
function ui:ctor()
    self.window = nil;
    self.global = nil;

    GameLogic:Connect("WorldUnloaded", self, self.CloseWindow, "UniqueConnection");
end

-- 获取文件
function ui:GetFilePath(relUiPath)
    return __DIRECTORY__ .. "/".. relUiPath;
end

-- 注册组件
function ui:Register(tagname, tagclass)
    return Component.Register(tagname, tagclass);
end

-- 定义组件
function ui:Component(opts)
    return Component.Extend(opts);
end

-- 获取全局表
function ui:GetGlobalTable(G, bReset)
    if (self.global and not bReset) then return self.global end
    self.global = {};
    setmetatable(self.global, {__index = _G});
    if (type(G) == "table") then
        for key, val in pairs(G) do 
            self.global[key] = val;
        end
    end
    self.global.ui = self;
    self.global._G = self.global;
    self.global.self = self.global;

    -- 更新全局Scope的元表
    self:GetGlobalScope():SetMetaTable(self.global);

    return self.global;
end

-- 获取全局Scope支持响应式, 全局表不支持响应式
function ui:GetGlobalScope()
    if (self.globalScope) then return self.globalScope end
    self.globalScope = Scope.New();
    self.globalScope:SetMetaTable(self:GetGlobalTable());
    self.globalScope.__newvalue = function(_, key, val) 
        if (key == "__newvalue") then return end;
        -- print("[ui] [info] set global scope value, key = ", key);
        self:RefreshWindow();
    end
    return self.globalScope;
end

-- 获取窗口
function ui:GetWindow(url, isNewNoExist)
    if (not rawget(self, "window")) then
        local UIWindow = commonlib.gettable("UIWindow");
        self.window = UIWindow:new();
        self.window:Connect("windowClosed", self, "OnWindowClosed", "UniqueConnection");
        self.window:SetUI(self);
    end
    return self.window;
end

-- 刷新窗口
function ui:RefreshWindow(delta)
    local page = self:GetWindow():Page();
    return page and page:Refresh(delta or 0.2);
end

-- 显示窗口
function ui.ShowWindow(self, params)
    if (not self.isa or not self:isa(ui)) then 
        params = self;
        self = ui:new();
        echo("-------------------new ui window-----------------");
    end

    params = params or {};
    local url = params.url or self:GetFilePath("ui.html");
    if (params.alignment == nil) then params.alignment = "_ct" end
    if (params.width == nil) then params.width = 600 end
    if (params.height == nil) then params.height = 500 end
    if (params.left == nil) then params.left = -params.width / 2 end
    if (params.top == nil) then params.top = -params.height / 2 end
    if (params.allowDrag == nil) then params.allowDrag = true end
    if (params.name == nil) then params.name = "UI" end
    -- 关闭销毁
    params.DestroyOnClose = true;
    -- 强制更新全局表
    params.pageGlobalTable = self:GetGlobalTable(params.G, true);
    -- 生成模板
    params.url = ParaXML.LuaXML_ParseString(params.mcml or string.format([[
        <pe:mcml class="ui-pe-mcml" width="100%%" height="100%%">
            <App filename="%s"></App>
        </pe:mcml>
    ]], url));

    self.params = params;
    
    return self:GetWindow():Show(params);
end

-- 设置窗口大小
function ui:SetWindowSize(params)
    if (params.alignment == nil) then params.alignment = "_ct" end
    if (params.width == nil) then params.width = 600 end
    if (params.height == nil) then params.height = 500 end
    if (params.left == nil) then params.left = -params.width / 2 end
    if (params.top == nil) then params.top = -params.height / 2 end
    self.params.alignment, self.params.left, self.params.top, self.params.width, self.params.height = params.alignment, params.left, params.top, params.width, params.height;
end

-- 关闭窗口
function ui:CloseWindow()
    if (not self.window) then return end
    self.window:CloseWindow();
    self.window = nil;
    self.global = nil;
    self.globalScope = nil;

    if (type(self.params.OnClose) == "function") then
        self.params.OnClose();
    end
end

-- 窗口关闭回调
function ui:OnWindowClosed()
    
end

-- 静态初始化
local function StaticInit()
    Helper.SetPathAlias("ui", __DIRECTORY__);
    
    ui:Register("App", App);
    ui:Register("Slot", Slot);

    ui:Register("WindowTitleBar", "%ui%/Core/Components/WindowTitleBar.html");
end

StaticInit();