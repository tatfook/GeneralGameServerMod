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
local StyleManager = NPL.load("./StyleManager.lua", IsDevEnv);
local Window = commonlib.inherit(Element, NPL.export());
local WindowDebug = GGS.Debug.GetModuleDebug("WindowDebug");
local MouseDebug = GGS.Debug.GetModuleDebug("MouseDebug").Disable();  -- --Enable  Disable

Window:Property("NativeWindow");                    -- 原生窗口
Window:Property("PainterContext");                  -- 绘制上下文
Window:Property("ElementManager", ElementManager);  -- 元素管理器
Window:Property("StyleManager");                    -- 元素管理器
Window:Property("HoverElement");                    -- 光标所在元素
Window:Property("FocusElement");                    -- 焦点元素
Window:Property("MouseCaptureElement");             -- 鼠标捕获元素
Window:Property("G");                               -- 全局对象
Window:Property("FullScreen", false, "IsFullScreen");  -- 是否全屏窗口

function Window:ctor()
    --屏幕位置,宽度,高度
    self.screenX, self.screenY, self.screenWidth, self.screenHeight = 0, 0, 0, 0; 
    -- 窗口的位置,宽度,高度
    self.windowX, self.windowY, self.windowWidth, self.windowHeight = 0, 0, 0, 0; 
    self:SetName("Window");
    self:SetTagName("Window");
    self:SetStyleManager(StyleManager:new());
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

function Window:Init(params)
    self:SetG(G(self, params.G));      -- 设置全局G表
    
    -- 保存窗口大小
    self.screenX, self.screenY, self.screenWidth, self.screenHeight = self:GetNativeWindow():GetAbsPosition();
    self.windowWidth, self.windowHeight = params.width, params.height;
    self.windowX, self.windowY = params.x or math.floor((self.screenWidth - self.windowWidth) / 2), params.y or math.floor((self.screenHeight - self.windowHeight) / 2);

    -- 设置窗口元素
    self:InitElement({
        name = "Window",
        attr = {
            draggable = if_else(params.draggable == false, false, true),   -- 窗口默认可以拖拽
        }, 
    }, self, nil)

    -- 设置根元素
    local xmlNode = self:LoadXmlNodeByUrl(params.url);
    if (xmlNode) then
        self:InsertChildElement(self:CreateFromXmlNode(xmlNode, self, self));
    end
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
    params.width, params.height = params.width or 600, params.height or 500;
    self:SetFullScreen(if_else(params.fullscreen == true, true, false));
    if (not self:GetNativeWindow()) then
        self:SetNativeWindow(self:CreateNativeWindow(params));
    end
    self:Init(params);
    self:UpdateLayout();
end

-- 窗口关闭
function Window:CloseWindow()
    if (not self:GetNativeWindow()) then return end

    ParaUI.Destroy(self:GetNativeWindow().id);
    self:SetNativeWindow(nil);
    
    local G = self:GetG();
    if (G and type(G.OnClose) == "function") then G.OnClose() end
end

function Window:InitWindowPosition(params)
    -- 保存窗口大小
    local screenX, screenY, screenWidth, screenHeight = ParaUI.GetUIObject("root"):GetAbsPosition();
    if (self:IsFullScreen()) then return screenX, screenY, screenWidth, screenHeight end
    local windoX, windowY, windowWidth, windowHeight = 0, 0, params.width or 600, params.height or 500;
    local offsetX, offsetY = params.x or 0, params.y or 0;
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
    else
        windowX, windowY = offsetX + math.floor((screenWidth - windowWidth) / 2), offsetY + math.floor((screenHeight - windowHeight) / 2);
    end
    return windowX, windowY, windowWidth, windowHeight;
end

-- 创建原生窗口
function Window:CreateNativeWindow(params)
    if (self:GetNativeWindow()) then return self:GetNativeWindow() end
    local RootUIObject = ParaUI.GetUIObject("root");
    -- 创建窗口
    local windoX, windowY, windowWidth, windowHeight = self:InitWindowPosition(params);
    local native_window = ParaUI.CreateUIObject("container", "Window", "_lt", windoX, windowY, windowWidth, windowHeight);
    -- WindowDebug.Format("CreateNativeWindow windoX = %s, windowY = %s, windowWidth = %s, windowHeight = %s", windoX, windowY, windowWidth, windowHeight);
    native_window:SetField("OwnerDraw", true);               -- enable owner draw paint event
    native_window:SetField("CanHaveFocus", true);
    native_window:SetField("InputMethodEnabled", true);
    -- 加到有效窗口上
    native_window:AttachToRoot();
    -- 创建绘图上下文
    self:SetPainterContext(System.Core.PainterContext:new():init(self));
	
	local _this = native_window;
	-- redirect events from native ParaUI object to this object. 
    _this:SetScript("onsize", function()
		self:handleGeometryChangeEvent();
	end);
	_this:SetScript("ondraw", function()
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
	_this:SetScript("ondestroy", function()
		self:handleDestroyEvent();
    end);

    return native_window;
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
    self:Render(self:GetPainterContext());
end

function Window:handleMouseEvent(event)
    self:Hover(event);

    local point, eventType = event:globalPos(), event:GetType();
    local x, y = point:x(), point:y();
    local captureFuncName, bubbleFuncName = nil, nil;
    if (eventType == "mousePressEvent") then
        captureFuncName, bubbleFuncName = "OnMouseDownCapture", "OnMouseDown";
    elseif (eventType == "mouseReleaseEvent") then
        captureFuncName, bubbleFuncName = "OnMouseUpCapture", "OnMouseUp";
    elseif (eventType == "mouseMoveEvent") then
        captureFuncName, bubbleFuncName = "OnMouseMoveCapture", "OnMouseMove";
    elseif (eventType == "mouseWheelEvent") then
        captureFuncName, bubbleFuncName = "OnMouseWheelCapture", "OnMouseWheel";
    elseif (eventType == "mouseEnterEvent") then
        captureFuncName, bubbleFuncName = "OnMouseEnterCapture", "OnMouseEnter";
    elseif (eventType == "mouseLeaveEvent") then
        captureFuncName, bubbleFuncName = "OnMouseLeaveCapture", "OnMouseLeave";
    else 
        captureFuncName = "OnMouseCapture", "OnMouse";
    end

    -- 获取点所在的元素
    local function ElementMouseEvent(element)
        -- 无布局的元素忽略
        if (not element:IsVisible()) then return end

        -- 检测元素是否包含
        if (not element:IsContainPoint(x, y)) then return end

        if (eventType ~= "mouseMoveEvent") then MouseDebug.Format("Element Capture: Name = %s, EventType = %s, CaptureFuncName = %s, BubbleFuncName = %s", element:GetName(), eventType, captureFuncName, bubbleFuncName) end

        -- 触发捕获事件
        if (type(element[captureFuncName]) == "function") then 
            (element[captureFuncName])(element, event);
        end

        -- 是否已处理
        if (event:isAccepted()) then return target end

        -- 子元素
        local target = nil;
        for child in element:ChildElementIterator(false) do
            target = ElementMouseEvent(child);
            if (target) then break end
        end
        target = target or element;
        
        -- 是否已处理
        if (event:isAccepted()) then return target end
        
        if (eventType ~= "mouseMoveEvent") then MouseDebug.Format("Element Bubble: Name = %s, EventType = %s, CaptureFuncName = %s, BubbleFuncName = %s", element:GetName(), eventType, captureFuncName, bubbleFuncName) end

        -- 触发相应事件
        if (type(element[bubbleFuncName]) == "function") then
            (element[bubbleFuncName])(element, event);
        end
        
        return target;
    end

    -- 如果鼠标事件已被锁定则直接执行事件回调
    local element = self:GetMouseCapture();
    if (element) then
        if (eventType ~= "mouseMoveEvent") then MouseDebug.Format("Mouse Capture: Name = %s, EventType = %s, CaptureFuncName = %s, BubbleFuncName = %s", element:GetName(), eventType, captureFuncName, bubbleFuncName) end
        if (type(element[bubbleFuncName]) == "function") then
            (element[bubbleFuncName])(element, event);
        end
    else 
        local positionElements = self:GetPositionElements();
        for _, el in ipairs(positionElements) do
            -- MouseDebug.If(false and eventType ~= "mouseMoveEvent", el:GetName());
            element = ElementMouseEvent(el);
            if (element) then break end
        end
        element = element or ElementMouseEvent(self);
    end

    if (eventType ~= "mouseMoveEvent") then MouseDebug.Format("Target Element: Name = %s, EventType = %s, CaptureFuncName = %s, BubbleFuncName = %s", element and element:GetName(), eventType, captureFuncName, bubbleFuncName) end

    if (eventType == "mouseMoveEvent") then
        -- self:SetHover(element);
    elseif(eventType == "mousePressEvent") then
        self:SetFocus(element);
    end

    -- 系统其它事件处理
    if(not event:isAccepted() and not element and not self:GetWindow():IsContainPoint(x, y)) then
        -- WindowDebug(string.format("x = %s, y = %s", x, y), self:GetWindow():GetWindowPosition());
        local context = SceneContextManager:GetCurrentContext();
        if(context) then context:handleMouseEvent(event) end
    end
end

function Window:handleMouseEnterLeaveEvent(event)
    if (event:GetType() == "mouseLeaveEvent") then
        -- self:SetHover(nil);
    end
end

function Window:handleKeyEvent(event)
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
    self:SetNativeWindow(nil);
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
