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

local ElementLayout = NPL.load("./ElementLayout.lua", IsDevEnv);
local ElementManager = NPL.load("./ElementManager.lua", IsDevEnv);
local UIWindow = commonlib.inherit(commonlib.gettable("System.Windows.Window"), NPL.export());

UIWindow:Property("UIWindow", true, "IsUIWindow");    -- 是否是UIWindow
UIWindow:Property("UI");                              -- 窗口绑定的UI对象
UIWindow:Property("ElementManager");                  -- 元素管理器
UIWindow:Property("EnableElementLayout", false, "IsEnableElementLayout");   -- 是否启用元素布局
UIWindow:Property("RootElement");                     -- 根元素
UIWindow:Property("RootXmlNode");                     -- 根XMLNode
UIWindow:Property("RootLayout");                      -- 根布局

function UIWindow:ctor()
    -- 设置布局
    self.layout = ElementLayout:new():Init(nil, nil, self);

    -- 设置根布局
    self:SetRootLayout(self.layout);

    -- 设置元素管理器
    self:SetElementManager(ElementManager);
end

-- 加载页面内容
function UIWindow:LoadComponent(url)
    url = commonlib.XPath.selectNode(ParaXML.LuaXML_ParseString([[
       <html style="height:100%;">
            <Button>按钮</Button>
            hello world  this is a test
       </html>
    ]]), "//html");

    -- 只接受xmlNode
    if (type(url) ~= "table") then return end
    
    -- 保存XML
    self:SetRootXmlNode(url);

    -- 获取元素类 
    local Element = ElementManager:GetElementByTagName(self:GetRootXmlNode().name);
    if (not Element) then return end;

    -- 设置根元素
    self:SetRootElement(Element:new():Init(self:GetRootXmlNode(), self));

    -- 加载元素
    self:GetRootElement():LoadComponent(self, self:GetRootLayout());
end

-- 窗口刷新
function UIWindow:Refresh()
    if (not self:GetRootElement()) then return end

    -- 加载元素
    self:GetRootElement():LoadComponent(self, self:GetRootLayout());

    -- 激活布局
    self:GetRootLayout():activate();
end

-- 窗口显示
function UIWindow.Show(self, params)
    if (not self or not self.isa or self == UIWindow or not self:isa(UIWindow)) then 
        params = self ~= UIWindow and self or params;
        self = UIWindow:new();
    end

    self:LoadComponent();

    params = params or {};
    if (params.alignment == nil) then params.alignment = "_ct" end
    if (params.width == nil) then params.width = 600 end
    if (params.height == nil) then params.height = 500 end
    if (params.left == nil) then params.left = -params.width / 2 end
    if (params.top == nil) then params.top = -params.height / 2 end
    if (params.allowDrag == nil) then params.allowDrag = true end
    if (params.name == nil) then params.name = "UI" end
    
    -- 关闭销毁
    params.DestroyOnClose = true;

    UIWindow._super.Show(self, params);
end

-- 窗口关闭
function UIWindow:CloseWindow()
    UIWindow._super.CloseWindow(self);
end



-- handle ondraw callback from system ParaUI object. 
function UIWindow:handleRender()
	self.isRepaintScheduled = false;
	self:Render(self.painterContext);
	if(self.bSelfPaint) then
		-- for some reason, opengl sprites needs to be flushed in order to paint
		self.painterContext:Flush();
	end
end

-- render the widget and all its child objects to the current device context. 
function UIWindow:Render(painterContext)
	if(not painterContext or not self:GetRootElement()) then return end
	-- make sure all widgets are recursively laid out properly
	self:prepareToRender();

    self:GetRootElement():Render(painterContext);
end

if (_G.UIWindow) then _G.UIWindow:CloseWindow() end
_G.UIWindow = UIWindow:new();
UIWindow.Test = _G.UIWindow;