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
local Mouse = commonlib.gettable("System.Windows.Mouse")
local Event = commonlib.gettable("System.Core.Event");
local SceneContextManager = commonlib.gettable("System.Core.SceneContextManager");
local Point = commonlib.gettable("mathlib.Point");
local Rect = commonlib.gettable("mathlib.Rect");
local SizeEvent = commonlib.gettable("System.Windows.SizeEvent");
local InputMethodEvent = commonlib.gettable("System.Windows.InputMethodEvent");
local FocusPolicy = commonlib.gettable("System.Core.Namespace.FocusPolicy");

local ElementManager = NPL.load("./ElementManager.lua", IsDevEnv);
local UIWindow = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

UIWindow:Property("UI");                              -- 窗口绑定的UI对象
UIWindow:Property("NativeWindow");                    -- 原生窗口
UIWindow:Property("PainterContext");                  -- 绘制上下文
UIWindow:Property("ElementManager", ElementManager);  -- 元素管理器
UIWindow:Property("RootElement");                     -- 根元素
UIWindow:Property("RootXmlNode");                     -- 根XMLNode

function UIWindow:ctor()
    self.x, self.y, self.width, self.height = 0, 0;
end

-- 加载页面内容
function UIWindow:LoadComponent(url)
    url = commonlib.XPath.selectNode(ParaXML.LuaXML_ParseString([[
       <html style="height:100%;">
            <Button>按钮</Button>
            <Text>中文 hello world  this is a test</Text>
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
    self:GetRootElement():LoadComponent();

    -- 更新元素布局
    self:GetRootElement():UpdateLayout();
end

-- 窗口刷新
function UIWindow:Refresh()
    if (not self:GetRootElement()) then return end

    -- 加载元素
    self:GetRootElement():LoadComponent();
end

-- 窗口显示
function UIWindow.Show(self, params)
    if (not self or not self.isa or self == UIWindow or not self:isa(UIWindow)) then 
        params = self ~= UIWindow and self or params;
        self = UIWindow:new();
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

    self:LoadComponent();

    self:SetVisible(true);
end

-- 窗口关闭
function UIWindow:CloseWindow()
    if(self:GetNativeWindow()) then
		ParaUI.Destroy(self:GetNativeWindow().id);
		self:SetNativeWindow(nil);
	end
end

if (_G.UIWindow) then _G.UIWindow:CloseWindow() end
_G.UIWindow = UIWindow:new();
UIWindow.Test = _G.UIWindow;

-- 设置可见性
function UIWindow:SetVisible(visible)
    if(not self:GetNativeWindow()) then return end
    self:GetNativeWindow().visible = visible == true;
end

-- 创建原生窗口
function UIWindow:CreateNativeWindow(params)
    if (self:GetNativeWindow()) then return end

    local name, left, top, width, height, alignment = params.name, params.left or 0, params.top or 0, params.width or 500, params.height or 400, params.alignment or "_lt";
    -- 创建窗口
    local native_window = ParaUI.CreateUIObject("container", name or "Window", alignment, left, top, width, height);
    native_window:SetField("OwnerDraw", true); -- enable owner draw paint event

    -- 加到有效窗口上
    if(not native_window.parent:IsValid()) then
        local parent = params.parent or ParaUI.GetUIObject("root");
        parent:AddChild(native_window);
    end
    -- 保存窗口大小
    local x, y, w, h = native_window:GetAbsPosition();
    self.x, self.y, self.width, self.height = x, y, w, h;
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
		local event = KeyEvent:init("keyPressEvent")
		
		self:HandlePressKeyEvent(event);
		if(event:isAccepted()) then
			Application:sendEvent(self:focusWidget(), event);
		end

		if(not event:isAccepted()) then
			local context = SceneContextManager:GetCurrentContext();
			if(context) then
				context:handleKeyEvent(event);
			end
		end
	end);
	_this:SetScript("onkeyup", function()
		-- Application:sendEvent(self:focusWidget(), KeyEvent:init("keyReleaseEvent"));
	end);
	_this:SetScript("oninputmethod", function()
		-- Application:sendEvent(self:focusWidget(), InputMethodEvent:new():init(msg));
	end);
	_this:SetScript("onactivate", function()
		local isActive = (param1 and param1>0);
		self:handleActivateEvent(isActive);
	end);
	_this:SetScript("onfocusin", function()
		self:handleActivateEvent(true);
	end);
	_this:SetScript("onfocusout", function()
		if(self:focusWidget() and self:focusWidget():hasFocus()) then
			self:handleActivateEvent(false);
		end
	end);
	_this:SetScript("ondestroy", function()
		self:handleDestroyEvent();
    end);

    return native_window;
end

-- 窗口大小改变
function UIWindow:handleGeometryChangeEvent()
    -- 保存窗口大小
    local x, y, w, h = native_window:GetAbsPosition();
    self.x, self.y, self.width, self.height = x, y, w, h;
    -- 更新布局
    if (not self:GetRootElement()) then return end
    local _, _, oldWidth, oldHeight = self:GetRootElement():GetGeometry();
    local _, _, newWidh, newHeight = self:GetNativeWindow():GetAbsPosition();
    if (oldWidth ~= newWidh or oldHeight ~= newHeight) then
        self:GetRootElement():UpdateLayout();
    end
end

-- handle ondraw callback from system ParaUI object. 
function UIWindow:handleRender()
	if(not self:GetRootElement()) then return end

    self:GetRootElement():Render(self:GetPainterContext());
end

function UIWindow:handleMouseEvent()
end

function UIWindow:handleMouseEnterLeaveEvent()
end

function UIWindow:HandleKeyEvent()
end

function UIWindow:handleActivateEvent()
end

function UIWindow:handleDestroyEvent()
    self:SetNativeWindow(nil);
end


function UIWindow:mapFromGlobal(pos)
    if((self.uiScalingX or 1) == 1 and (self.uiScalingY or 1) == 1) then
        return Point:new_from_pool(-self.x + pos:x(), -self.y + pos:y());
    else
        return Point:new_from_pool(math.floor((-self.x + pos:x()) / self.uiScalingX + 0.5), math.floor((-self.y + pos:y()) / self.uiScalingY + 0.5));
    end
end