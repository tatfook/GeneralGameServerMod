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
NPL.load("(gl)script/ide/System/Core/Event.lua");
NPL.load("(gl)script/ide/System/Core/SceneContextManager.lua");
NPL.load("(gl)script/ide/math/Point.lua");
NPL.load("(gl)script/ide/math/Rect.lua");
local PainterContext = commonlib.gettable("System.Core.PainterContext");
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local KeyEvent = commonlib.gettable("System.Windows.KeyEvent");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local Event = commonlib.gettable("System.Core.Event");
local SceneContextManager = commonlib.gettable("System.Core.SceneContextManager");
local Point = commonlib.gettable("mathlib.Point");
local Rect = commonlib.gettable("mathlib.Rect");
local SizeEvent = commonlib.gettable("System.Windows.SizeEvent");
local InputMethodEvent = commonlib.gettable("System.Windows.InputMethodEvent");
local FocusPolicy = commonlib.gettable("System.Core.Namespace.FocusPolicy");

local Element = NPL.load("./Element.lua", IsDevEnv);
local ElementManager = NPL.load("./ElementManager.lua", IsDevEnv);
local Window = commonlib.inherit(Element, NPL.export());
local WindowDebug = GGS.Debug.GetModuleDebug("WindowDebug");

Window:Property("NativeWindow");                    -- 原生窗口
Window:Property("PainterContext");                  -- 绘制上下文
Window:Property("ElementManager", ElementManager);  -- 元素管理器
Window:Property("HoverElement");                    -- 光标所在元素
Window:Property("FocusElement");                    -- 焦点元素
Window:Property("MouseCaptureElement");             -- 鼠标捕获元素

function Window:ctor()
    self:SetName("Window");
    self:SetTagName("Window");
    self:SetWindow(self);
end

function Window:IsWindow()
    return true;
end

function Window:Init(params)
    url = commonlib.XPath.selectNode(ParaXML.LuaXML_ParseString([[
       <html style="height:100%; background-color:#ffffff;">
            <Button>按钮</Button>
            <Text>中文 hello world  this is a test</Text>
       </html>
    ]]), "//html");

    -- 只接受xmlNode
    if (type(url) ~= "table") then return end
    
    local xmlNode = url;
    -- 保存XML
    self:SetXmlNode({Name = "Window"});
    -- 设置属性
    self:SetAttr({
        draggable = if_else(params.draggable == false, false, true),   -- 窗口默认可以拖拽
    });
    -- 清子元素
    self:ClearChildElement();
    -- 获取元素类 
    local Element = ElementManager:GetElementByTagName(xmlNode.name);
    if (not Element) then return end;
    -- 设置根元素
    self:InsertChildElement(Element:new():Init(xmlNode, self));
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
    if (params.alignment == nil) then params.alignment = "_ct" end
    if (params.width == nil) then params.width = 600 end
    if (params.height == nil) then params.height = 500 end
    if (params.left == nil) then params.left = -params.width / 2 end
    if (params.top == nil) then params.top = -params.height / 2 end
    if (params.allowDrag == nil) then params.allowDrag = true end
    if (params.name == nil) then params.name = "UI" end
    
    -- 关闭销毁
    params.DestroyOnClose = true;

    if (not self:GetNativeWindow()) then
        self:SetNativeWindow(self:CreateNativeWindow(params));
    end

    self:Init(params);

    self:LoadComponent();

    self:UpdateLayout();
end

-- 窗口关闭
function Window:CloseWindow()
    if(self:GetNativeWindow()) then
		ParaUI.Destroy(self:GetNativeWindow().id);
		self:SetNativeWindow(nil);
	end
end

if (_G.Window) then _G.Window:CloseWindow() end
_G.Window = Window:new();
Window.Test = _G.Window;

-- 创建原生窗口
function Window:CreateNativeWindow(params)
    if (self:GetNativeWindow()) then return self:GetNativeWindow() end

    local name, left, top, width, height, alignment = params.name, params.left or 0, params.top or 0, params.width or 500, params.height or 400, params.alignment or "_lt";
    -- 创建窗口
    local native_window = ParaUI.CreateUIObject("container", name or "Window", alignment, left, top, width, height);
    native_window:SetField("OwnerDraw", true); -- enable owner draw paint event
    -- 加到有效窗口上
    if(not native_window.parent or not native_window.parent:IsValid()) then
        local parent = params.parent or ParaUI.GetUIObject("root");
        parent:AddChild(native_window);
    end
    -- 保存窗口大小
    local x, y, w, h = native_window:GetAbsPosition();
    self:SetScreenPos(x, y);
    self:SetSize(w, h);

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
		self:handleMouseEvent(MouseEvent:init("mousePressEvent", self));
	end);
	_this:SetScript("onmouseup", function()
		self:handleMouseEvent(MouseEvent:init("mouseReleaseEvent", self));
	end);
	_this:SetScript("onmousemove", function()
		self:handleMouseEvent(MouseEvent:init("mouseMoveEvent", self));
	end);
	_this:SetScript("onmousewheel", function()
		self:handleMouseEvent(MouseEvent:init("mouseWheelEvent", self));
	end);
	_this:SetScript("onmouseleave", function()
		self:handleMouseEnterLeaveEvent(MouseEvent:init("mouseLeaveEvent", self));
	end);
	_this:SetScript("onmouseenter", function()
		self:handleMouseEnterLeaveEvent(MouseEvent:init("mouseEnterEvent", self));
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

-- 窗口大小改变
function Window:handleGeometryChangeEvent()
    -- 保存窗口大小
    local x, y, newWidth, newHeight = self:GetNativeWindow():GetAbsPosition();
    local oldWidth, oldHeight = self:GetSize();

    self:SetScreenPos(x, y);
    if (oldWidth == newWidth and oldHeight == newHeight) then return end

    self:SetSize(newWidth, newHeight);
    self:UpdateLayout();
end

-- handle ondraw callback from system ParaUI object. 
function Window:handleRender()
    self:Render(self:GetPainterContext());
end

function Window:handleMouseEvent(event)
    local point, eventType = event:localPos(), event:GetType();
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
        if (not element:GetLayout():IsLayout()) then return end

        -- 检测元素是否包含
        if (not element:GetRect():contains(point)) then return end

        if (eventType ~= "mouseMoveEvent") then WindowDebug.Format("Element Capture: Name = %s, EventType = %s, CaptureFuncName = %s, BubbleFuncName = %s", element:GetName(), eventType, captureFuncName, bubbleFuncName) end

        -- 触发捕获事件
        if (type(element[captureFuncName]) == "function") then 
            (element[captureFuncName])(element, event);
        end

        -- 是否已处理
        if (event:isAccepted()) then return target end
        
        -- 切换点为元素内的坐标
        point:sub(element:GetPosition());
        -- 子元素
        local target = nil;
        for child in element:ChildElementIterator(false) do
            target = ElementMouseEvent(child);
            if (target) then break end
        end
        target = target or element;
        -- 还原点坐标
        point:add(element:GetPosition());
        
        -- 是否已处理
        if (event:isAccepted()) then return target end
        
        if (eventType ~= "mouseMoveEvent") then WindowDebug.Format("Element Bubble: Name = %s, EventType = %s, CaptureFuncName = %s, BubbleFuncName = %s", element:GetName(), eventType, captureFuncName, bubbleFuncName) end

        -- 触发相应事件
        if (type(element[bubbleFuncName]) == "function") then
            (element[bubbleFuncName])(element, event);
        end

        return target;
    end

    -- 如果鼠标事件已被锁定则直接执行事件回调
    local element = self:GetMouseCapture();
    if (element) then
        -- if (eventType ~= "mouseMoveEvent") then WindowDebug.Format("Mouse Capture: Name = %s, EventType = %s, CaptureFuncName = %s, BubbleFuncName = %s", element:GetName(), eventType, captureFuncName, bubbleFuncName) end

        if (type(element[bubbleFuncName]) == "function") then
            (element[bubbleFuncName])(element, event);
        end
    else 
        element = ElementMouseEvent(self);
    end

    if (eventType ~= "mouseMoveEvent") then WindowDebug.Format("Target Element: Name = %s, EventType = %s, CaptureFuncName = %s, BubbleFuncName = %s", element:GetName(), eventType, captureFuncName, bubbleFuncName) end

    if (eventType == "mouseMoveEvent") then
        self:SetHover(element);
    elseif(eventType == "mousePressEvent") then
        self:SetFocus(element);
    end
end

function Window:handleMouseEnterLeaveEvent(event)
    if (event:GetType() == "mouseLeaveEvent") then
        self:SetHover(nil);
    end
end

function Window:handleKeyEvent()
    if(not event:isAccepted()) then
        local context = SceneContextManager:GetCurrentContext();
        if(context) then
            context:handleKeyEvent(event);
        end
    end
end

function Window:handleActivateEvent(isActive)
    if (isActive) then
        self:SetFocus(self.lastFocusElement);
    else
        self.lastFocusElement = self:GetFocus();
        self:SetFocus(nil);
    end
end

function Window:handleDestroyEvent()
    self:SetNativeWindow(nil);
end

function Window:mapFromGlobal(pos)
    local x, y, w, h = self:GetNativeWindow():GetAbsPosition(); 
    if((self.uiScalingX or 1) == 1 and (self.uiScalingY or 1) == 1) then
        return Point:new_from_pool(-x + pos:x(), -y + pos:y());
    else
        return Point:new_from_pool(math.floor((-x + pos:x()) / self.uiScalingX + 0.5), math.floor((-y + pos:y()) / self.uiScalingY + 0.5));
    end
end

function Window:OnMouseDown(event)
    if(event:isAccepted()) then return end

    if(self:IsDraggable() and event:button()=="left") then
        self.isMouseDown = true;
        self.isDragging = false;
		self.startDragPosition = event:screenPos():clone();
		event:accept();
	end
end

function Window:OnMouseMove(event)
    if(event:isAccepted()) then return end
    
	if(self.isMouseDown and self:IsDraggable() and event:button() == "left") then
		if(not self.isDragging) then
			if(event:screenPos():dist2(self.startDragPosition[1], self.startDragPosition[2]) > 2) then
				self.isDragging = true;
				self.startDragWinLocation = Point:new():init(self:GetScreenPos());
				self:CaptureMouse();
			end
		elseif(self.isDragging) then
            local newPos = self.startDragWinLocation + event:screenPos() - self.startDragPosition;
            local screenX, screenY = newPos[1], newPos[2];
            local width, height = self:GetSize();
            self:GetNativeWindow():Reposition("_lt", screenX, screenY, width, height);
		end
		if(self.isDragging) then
			event:accept();
		end
	end
end

function Window:OnMouseUp(event)
    if(event:isAccepted()) then return end

	if(self.isDragging) then
		self.isDragging = false;
		self:ReleaseMouseCapture();
		event:accept();
	end
	self.isMouseDown = false;
end