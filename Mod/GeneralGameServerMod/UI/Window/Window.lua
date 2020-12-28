--[[
Title: ui
Author(s): wxa
Date: 2020/6/30
Desc: UI Window
use the lib:
-------------------------------------------------------
local Window = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Window.lua");
-------------------------------------------------------
]]
-- Window
NPL.load("(gl)script/ide/System/Core/PainterContext.lua");
NPL.load("(gl)script/ide/System/Windows/MouseEvent.lua");
NPL.load("(gl)script/ide/System/Windows/KeyEvent.lua");
NPL.load("(gl)script/ide/System/Windows/Mouse.lua");
NPL.load("(gl)script/ide/System/Core/SceneContextManager.lua");
NPL.load("(gl)script/ide/math/Point.lua");
NPL.load("(gl)script/ide/math/Rect.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Screen = commonlib.gettable("System.Windows.Screen");
local PainterContext = commonlib.gettable("System.Core.PainterContext");
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local KeyEvent = commonlib.gettable("System.Windows.KeyEvent");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local SceneContextManager = commonlib.gettable("System.Core.SceneContextManager");
local Point = commonlib.gettable("mathlib.Point");
local Rect = commonlib.gettable("mathlib.Rect");
local SizeEvent = commonlib.gettable("System.Windows.SizeEvent");
local InputMethodEvent = commonlib.gettable("System.Windows.InputMethodEvent");
local FocusPolicy = commonlib.gettable("System.Core.Namespace.FocusPolicy");

local G = NPL.load("./G.lua", IsDevEnv);
local Event = NPL.load("./Event.lua", IsDevEnv);
local Element = NPL.load("./Element.lua", IsDevEnv);
local ElementManager = NPL.load("./ElementManager.lua", IsDevEnv);
local StyleManager = NPL.load("./Style/StyleManager.lua", IsDevEnv);

local Window = commonlib.inherit(Element, NPL.export());
local WindowDebug = GGS.Debug.GetModuleDebug("WindowDebug").Enable();
local MouseDebug = GGS.Debug.GetModuleDebug("MouseDebug").Disable();  -- Enable  Disable
local EventElementList = {};

local windowId = 0;
Window:Property("NativeWindow");                    -- 原生窗口
Window:Property("PainterContext");                  -- 绘制上下文
Window:Property("ElementManager", ElementManager);  -- 元素管理器
Window:Property("StyleManager");                    -- 元素管理器
Window:Property("HoverElement");                    -- 光标所在元素
Window:Property("FocusElement");                    -- 焦点元素
Window:Property("MouseCaptureElement");             -- 鼠标捕获元素
Window:Property("G");                               -- 全局对象
Window:Property("Params");                          -- 窗口参数
Window:Property("Event");                           -- 事件对象
Window:Property("3DUI", false, "Is3DUI");           -- 是否是3DUI

function Window:ctor()
    windowId = windowId + 1;
    self.windowId = windowId;

    --屏幕位置,宽度,高度
    self.screenX, self.screenY, self.screenWidth, self.screenHeight = 0, 0, 0, 0; 
    -- 窗口的位置,宽度,高度
    self.windowX, self.windowY, self.windowWidth, self.windowHeight = 0, 0, 0, 0; 
    self:SetName("Window");
    self:SetTagName("Window");
    self:SetStyleManager(StyleManager:new());
    -- 创建绘图上下文
    self:SetPainterContext(System.Core.PainterContext:new():init(self));
end

function Window:IsWindow()
    return true;
end

function Window:LoadXmlNodeByUrl(url)
    if (type(url) == "table") then return url end
    if (type(url) ~= "string") then return nil end

    local file = ParaIO.open(url, "r");
    if(not file:IsValid()) then
        WindowDebug.Format("ERROR: read file failed: %s ", url);
        return ;
    end
    local text = file:GetText();
    file:close();
    return commonlib.XPath.selectNode(ParaXML.LuaXML_ParseString(text), "//html");
end

function Window:LoadXmlNodeByTemplate(template)
    if (type(template) == "table") then return template end
    if (type(template) ~= "string") then return nil end
    return commonlib.XPath.selectNode(ParaXML.LuaXML_ParseString(template), "//html");
end

function Window:LoadXmlNode(params)
    if (params.tpl) then return self:LoadXmlNodeByTemplate(params.tpl) end
    if (params.url) then return self:LoadXmlNodeByUrl(params.url) end
end

-- 新建一个全局表
function Window:NewG(g)
    return G.New(self, g);
end

function Window:Init()
    Screen:Connect("sizeChanged", self, self.OnScreenSizeChanged, "UniqueConnection");

    local params = self:GetParams();
    self:SetG(self:NewG(params.G));      -- 设置全局G表
    -- 设置窗口元素
    self:InitElement({
        name = "Window",
        attr = {
            draggable = if_else(params.draggable == false, false, true),   -- 窗口默认可以拖拽
        }, 
    }, self, nil);
    self:SetVisible(true);

    -- 设置根元素
    local xmlNode = self:LoadXmlNode(params);
    local rootElement = xmlNode and self:CreateFromXmlNode(xmlNode, self, self);
    if (rootElement) then table.insert(self.childrens, rootElement) end

    -- 加载元素, 提供一种置顶向下执行的机制
    self:LoadElement();
end

-- 窗口刷新
function Window:Refresh()
end

-- 窗口显示
function Window.Show(self, params)
    if (not self or not self.isa or self == Window or not self:isa(Window)) then 
        params = self ~= Window and self or params;
        self = Window:new();
    end
    params = params or {};
    self:SetParams(params);
    if (not self:GetNativeWindow()) then
        self:SetNativeWindow(self:CreateNativeWindow());
    end
    
    if (params.is3DUI) then self:Set3DUI(true) end

    -- 初始化
    self:Init();
    -- 文档化
    self:Attach();
    -- 更新布局
    self:UpdateLayout(true);

    return self;
end

-- 窗口关闭
function Window:CloseWindow()
    if (not self:GetNativeWindow()) then return end
    Screen:Disconnect("sizeChanged", self, self.OnScreenSizeChanged, "UniqueConnection");
    ParaUI.Destroy(self:GetNativeWindow().id);
    self:SetNativeWindow(nil);
    self:SetVisible(false);
    local G = self:GetG();
    if (G and type(G.OnClose) == "function") then G.OnClose() end
end

function Window:InitWindowPosition()
    local params = self:GetParams();
    local screenX, screenY, screenWidth, screenHeight = ParaUI.GetUIObject("root"):GetAbsPosition();
    -- print(screenX, screenY, screenWidth, screenHeight, params.width, params.height);
    local windoX, windowY, windowWidth, windowHeight = 0, 0, params.width or screenWidth, params.height or screenHeight;
    local offsetX, offsetY = params.x or 0, params.y or 0;
    if (type(windowWidth) == "string" and string.match(windowWidth, "^%d+%%$")) then windowWidth = math.floor(screenWidth * tonumber(string.match(windowWidth, "%d+")) / 100) end
    if (type(windowHeight) == "string" and string.match(windowHeight, "^%d+%%$")) then windowHeight = math.floor(screenHeight * tonumber(string.match(windowHeight, "%d+")) / 100) end
    if (type(offsetX) == "string" and string.match(offsetX, "^%d+%%$")) then offsetX = math.floor(screenWidth * tonumber(string.match(offsetX, "%d+")) / 100) end
    if (type(offsetY) == "string" and string.match(offsetY, "^%d+%%$")) then offsetY = math.floor(screenHeight * tonumber(string.match(offsetY, "%d+")) / 100) end
    -- *	- "_lt" align to left top of the screen
    -- *	- "_lb" align to left bottom of the screen
    -- *	- "_ct" align to center of the screen
    -- *	- "_ctt": align to center top of the screen
    -- *	- "_ctb": align to center bottom of the screen
    -- *	- "_ctl": align to center left of the screen
    -- *	- "_ctr": align to center right of the screen
    -- *	- "_rt" align to right top of the screen
    -- *	- "_rb" align to right bottom of the screen
    -- *	- "_mt": align to middle top
    -- *	- "_ml": align to middle left
    -- *	- "_mr": align to middle right
    -- *	- "_mb": align to middle bottom
    -- *	- "_fi": align to left top and right bottom. This is like fill in the parent window.
    -- *
    -- *	the layout is given below:
    -- *	_lt _mt _rt	
    -- *	_ml _ct _mr 
    -- *	_lb _mb _rb 
    if (params.alignment == "_ctb") then
        windowX, windowY = offsetX + math.floor((screenWidth - windowWidth) / 2), offsetY + screenHeight - windowHeight;
    elseif (params.alignment == "_ctt") then
        windowX, windowY = offsetX + math.floor((screenWidth - windowWidth) / 2), offsetY;
    elseif (params.alignment == "_ctl") then
        windowX, windowY = offsetX, offsetY + math.floor((screenHeight - windowHeight) / 2);
    elseif (params.alignment == "_ctr") then
        windowX, windowY = offsetX + screenWidth - windowWidth , offsetY + math.floor((screenHeight - windowHeight) / 2);
    elseif (params.alignment == "_lt") then
        windowX, windowY = offsetX, offsetY;
    elseif (params.alignment == "_lb") then
        windowX, windowY = offsetX, offsetY + screenHeight - windowHeight;
    elseif (params.alignment == "_rt") then
        windowX, windowY = offsetX + screenWidth - windowWidth, offsetY;
    elseif (params.alignment == "_rb") then
        windowX, windowY = offsetX + screenWidth - windowWidth, offsetY + screenHeight - windowHeight;
    elseif (params.alignment == "_mt") then
        windowX, windowY = offsetX + math.floor((screenWidth - windowWidth) / 2), offsetY;
    elseif (params.alignment == "_mb") then
        windowX, windowY = offsetX + math.floor((screenWidth - windowWidth) / 2), offsetY + screenHeight - windowHeight;
    elseif (params.alignment == "_ml") then
        windowX, windowY = offsetX, offsetY + math.floor((screenHeight - windowHeight) / 2);
    elseif (params.alignment == "_mr") then
        windowX, windowY = offsetX + screenWidth - windowWidth, offsetY + math.floor((screenHeight - windowHeight) / 2);
    else
        windowX, windowY = offsetX + math.floor((screenWidth - windowWidth) / 2), offsetY + math.floor((screenHeight - windowHeight) / 2);
    end

    self.screenX, self.screenY, self.screenWidth, self.screenHeight = windowX, windowY, windowWidth, windowHeight;
    self.windowX, self.windowY, self.windowWidth, self.windowHeight = 0, 0, windowWidth, windowHeight;
    -- WindowDebug(
    --     string.format("root window screenX = %s, screenY = %s, screenWidth = %s, screenHeight = %s", screenX, screenY, screenWidth, screenHeight),
    --     string.format("screenX = %s, screenY = %s, screenWidth = %s, screenHeight = %s", windowX, windowY, windowWidth, windowHeight),
    --     string.format("windowX = %s, windowY = %s, windowWidth = %s, windowHeight = %s", 0, 0, windowWidth, windowHeight)
    -- );
    return windowX, windowY, windowWidth, windowHeight;
end

-- 创建原生窗口
function Window:CreateNativeWindow()
    if (self:GetNativeWindow()) then return self:GetNativeWindow() end
    local RootUIObject = ParaUI.GetUIObject("root");
    -- 创建窗口
    local windoX, windowY, windowWidth, windowHeight = self:InitWindowPosition();
    local native_window = ParaUI.CreateUIObject("container", "Window", "_lt", windoX, windowY, windowWidth, windowHeight);
    -- WindowDebug.Format("CreateNativeWindow windoX = %s, windowY = %s, windowWidth = %s, windowHeight = %s", windoX, windowY, windowWidth, windowHeight);
    native_window:SetField("OwnerDraw", true);               -- enable owner draw paint event
    native_window:SetField("CanHaveFocus", true);
    native_window:SetField("InputMethodEnabled", true);
    local zorder = self:GetParams().zorder;
    if (zorder) then native_window.zorder = zorder end
    -- native_window.isPinned = true;
    
    -- 加到有效窗口上
    native_window:AttachToRoot();
	
	local _this = native_window;
	-- redirect events from native ParaUI object to this object. 
    _this:SetScript("onsize", function()
		self:handleGeometryChangeEvent();
	end);
    _this:SetScript("ondraw", function()
        -- if (self:Is3DUI()) then 
        --     self:GetPainterContext():LoadBillboardMatrix();
        -- end
		self:handleRender();
	end);
	_this:SetScript("onmousedown", function()
		self:handleMouseEvent(Event.MouseEvent:init("mousePressEvent", self));
	end);
	_this:SetScript("onmouseup", function()
		self:handleMouseEvent(Event.MouseEvent:init("mouseReleaseEvent", self));
	end);
    _this:SetScript("onmousemove", function()
		self:handleMouseEvent(Event.MouseEvent:init("mouseMoveEvent", self));
	end);
	_this:SetScript("onmousewheel", function()
		self:handleMouseEvent(Event.MouseEvent:init("mouseWheelEvent", self));
	end);
	_this:SetScript("onmouseleave", function()
		self:handleMouseEnterLeaveEvent(Event.MouseEvent:init("mouseLeaveEvent", self));
	end);
    _this:SetScript("onmouseenter", function()
		self:handleMouseEnterLeaveEvent(Event.MouseEvent:init("mouseEnterEvent", self));
	end);
	_this:SetScript("onkeydown", function()
        self:handleKeyEvent(KeyEvent:init("keyPressEvent"));
	end);
    _this:SetScript("onkeyup", function()
        self:handleKeyEvent(KeyEvent:init("keyReleaseEvent"));
	end);
    _this:SetScript("oninputmethod", function()
        self:handleKeyEvent(InputMethodEvent:new():init(msg));
	end);
    _this:SetScript("onactivate", function()
		self:handleActivateEvent(param1 and param1>0);
	end);
	_this:SetScript("onfocusin", function()
		self:handleActivateEvent(true);
	end);
	_this:SetScript("onfocusout", function()
		self:handleActivateEvent(false);
	end);
    _this:SetScript("ondestroy", function(...)
		self:handleDestroyEvent();
    end);

    return native_window;
end

-- 屏幕窗口大小改变
function Window:OnScreenSizeChanged()
    WindowDebug("================OnScreenSizeChanged===============");
    self:InitWindowPosition();
    self:GetWindow():GetNativeWindow():Reposition("_lt", self.screenX, self.screenY, self.screenWidth, self.screenHeight);
    self:UpdateLayout();
end

-- 获取窗口位置
function Window:GetWindowPosition()
    return self.windowX, self.windowY, self.windowWidth, self.windowHeight;
end

-- 设置窗口位置
function Window:SetWindowPosition(x, y, w, h)
    local isChangeSize = self.windowWidth ~= w or self.windowHeight ~= h;
    self.windowX, self.windowY, self.windowWidth, self.windowHeight = x, y, w, h;
    if (isChangeSize) then self:UpdateLayout() end
end

-- 获取元素相对屏幕的坐标
function Window:GetScreenPosition()
    return self.screenX, self.screenY, self.screenWidth, self.screenHeight;
end

-- 窗口大小改变
function Window:handleGeometryChangeEvent()
    self.screenX, self.screenY, self.screenWidth, self.screenHeight = self:GetNativeWindow():GetAbsPosition();
end

-- handle ondraw callback from system ParaUI object. 
function Window:handleRender()
    if (not self:GetNativeWindow()) then return end
    self:Render(self:GetPainterContext());
end

-- 获取方法名通过事件名
function Window:GetEventTypeFuncName(eventName)
    if (eventName == "mousePressEvent") then
        return "OnMouseDownCapture", "OnMouseDown";
    elseif (eventName == "mouseReleaseEvent") then
        return "OnMouseUpCapture", "OnMouseUp";
    elseif (eventName == "mouseMoveEvent") then
        return "OnMouseMoveCapture", "OnMouseMove";
    elseif (eventName == "mouseWheelEvent") then
        return "OnMouseWheelCapture", "OnMouseWheel";
    elseif (eventName == "mouseEnterEvent") then
        return "OnMouseEnterCapture", "OnMouseEnter";
    elseif (eventName == "mouseLeaveEvent") then
        return "OnMouseLeaveCapture", "OnMouseLeave";
    else 
        return "OnMouseCapture", "OnMouse";
    end
end

-- 鼠标事件处理函数
function Window:handleMouseEvent(event)
    if (not self:GetNativeWindow()) then return end
    self:SetEvent(event);

    -- local BeginTime = ParaGlobal.timeGetTime();
    local eventType = event:GetType();
    local captureFuncName, bubbleFuncName = self:GetEventTypeFuncName(eventType);

    -- 优先捕获鼠标元素
    local captureElement = self:GetMouseCapture();
    event.target = captureElement;
    if (captureElement) then
        event:SetElement(captureElement);
        (captureElement[captureFuncName])(captureElement, event);
        (captureElement[bubbleFuncName])(captureElement, event);
        return ;        
    end
    -- 获取悬浮元素
    local hoverElement = self:Hover(event, true);
    local lastHoverElement = self:GetHoverElement();
    if (lastHoverElement ~= hoverElement) then
        if (lastHoverElement) then
            event:SetElement(lastHoverElement);
            lastHoverElement:CallAttrFunction("onmouseout", nil, event, lastHoverElement);
        end
        self:SetHoverElement(hoverElement);
        event:SetElement(hoverElement);
        hoverElement:CallAttrFunction("onmouseover", nil, event, hoverElement);
    end

    event.target = hoverElement;
    -- WindowDebug.If(eventType == "mousePressEvent", hoverElement:GetAttr(), {hoverElement:GetWindowPos()}, {hoverElement:GetWindowSize()});

    -- WindowDebug.FormatIf(eventType == "mousePressEvent", "Hover 耗时 %sms", ParaGlobal.timeGetTime() - BeginTime);

    -- 获取事件元素列表
    local el = hoverElement;
    while (el and el:IsContainPoint(event.x, event.y)) do
        table.insert(EventElementList, el);
        el = el:GetParentElement();
    end
    -- WindowDebug.FormatIf(eventType == "mousePressEvent", "获取元素列表 耗时 %sms", ParaGlobal.timeGetTime() - BeginTime);
    -- 捕获事件
    local EventElementCount = #EventElementList;
    for i = EventElementCount, 1, -1 do
        el = EventElementList[i];
        event:SetElement(el);
        (el[captureFuncName])(el, event);
        if (event:isAccepted()) then break end
    end
    -- WindowDebug.FormatIf(eventType == "mousePressEvent", "捕获事件 耗时 %sms", ParaGlobal.timeGetTime() - BeginTime);
    -- 冒泡事件
    for i = 1, EventElementCount, 1 do
        el = EventElementList[i];
        event:SetElement(el);
        (el[bubbleFuncName])(el, event);
        if (event:isAccepted()) then break end
    end 
    -- WindowDebug.FormatIf(eventType == "mousePressEvent", "冒泡事件 耗时 %sms", ParaGlobal.timeGetTime() - BeginTime);
    -- 清空列表
    for i = 1, EventElementCount, 1 do EventElementList[i] = nil end
    -- WindowDebug.FormatIf(eventType == "mousePressEvent", "清除元素列表 耗时 %sms", ParaGlobal.timeGetTime() - BeginTime);
    -- 聚焦目标元素  聚焦与事件是否处理无关
    -- if (event:isAccepted()) then return end
    if(eventType == "mousePressEvent") then
        event:SetElement(hoverElement);
        self:SetFocus(hoverElement);
    end
    -- WindowDebug.FormatIf(eventType == "mousePressEvent", "鼠标事件 耗时 %sms", ParaGlobal.timeGetTime() - BeginTime);
end

function Window:handleMouseEnterLeaveEvent(event)
    if (event:GetType() == "mouseLeaveEvent") then
        -- self:SetHover(nil);
    end
end

function Window:handleKeyEvent(event)
    if (not self:GetNativeWindow()) then return end
    self:SetEvent(event);

    local focusElement = self:GetFocus();
    if (focusElement) then
        if (event:GetType() == "keyPressEvent") then
            focusElement:OnKeyDown(event);
        elseif (event:GetType() == "keyReleaseEvent") then 
            focusElement:OnKeyUp(event);    -- 不生效
        else
            focusElement:OnKey(event);
        end
    end

    -- 系统其它事件处理
    if (not focusElement and not event:isAccepted()) then 
        local context = SceneContextManager:GetCurrentContext();
        if(context) then
            context:handleKeyEvent(event);
        end
    end
end

function Window:handleActivateEvent(isActive)
    -- if (isActive) then
    --     self:SetFocus(self.lastFocusElement);
    -- else
    --     self.lastFocusElement = self:GetFocus();
    --     self:SetFocus(nil);
    -- end
end

function Window:handleDestroyEvent()
end

-- 执行字符串代码  返回 result, errmsg
function Window:ExecCode(code)
    local code_func, errmsg = loadstring(code);
    if (not code_func) then 
        WindowDebug.Format("Window ExecCode Error: %s", errmsg);
        return nil, errmsg;
    end
    -- 设置脚本执行环境
    setfenv(code_func, self:GetG());
    -- 执行脚本
    local result = code_func();
    return result, nil;
end
