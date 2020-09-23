--[[
Title: ElementUI
Author(s): wxa
Date: 2020/6/30
Desc: 元素UI基类, 主要实现元素绘制相关功能
use the lib:
-------------------------------------------------------
local ElementUI = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/ElementUI.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/Mouse.lua");
NPL.load("(gl)script/ide/System/Windows/MouseEvent.lua");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local ElementUI = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

ElementUI:Property("Value");                                -- 元素值
ElementUI:Property("Active", false, "IsActive");            -- 是否激活
ElementUI:Property("Hover", false, "IsHover");              -- 是否鼠标悬浮
ElementUI:Property("Layout");                               -- 元素布局

local ElementUIDebug = GGS.Debug.GetModuleDebug("ElementUIDebug");

function ElementUI:ctor()
    self.screenX, self.screenY = 0, 0;  -- 窗口的屏幕位置
end

-- 是否需要
function ElementUI:IsRender()
    local style = self:GetStyle();
    if (self.isRender or not style or style.display == "none" or style.visibility == "hidden" or self:GetWidth() == 0 or self:GetHeight() == 0) then return true end
    return false;
end

-- 元素渲染
function ElementUI:Render(painterContext)
	if (self:IsRender()) then return end

    self.isRender = true;  -- 设置渲染标识 避免递归渲染
    -- if(self.transform) then self:applyRenderTransform(painterContext, self.transform) end
       
    -- 渲染元素
    self:OnRender(painterContext);  

    self.isRender = false; -- 清除渲染标识

    -- 渲染子元素
    painterContext:Translate(self:GetX(), self:GetY());
    for childElement in self:ChildElementIterator() do
        childElement:Render(painterContext);
    end
    painterContext:Translate(-self:GetX(), -self:GetY());

	-- if(self.transform) then painterContext:Restore() end
end

-- 绘制元素
function ElementUI:OnRender(painter)
    local style = self:GetStyle();

    self:RenderOutline(painter, style);
    self:RenderBackground(painter, style);
    self:RenderBorder(painter, style);
    self:RenderContent(painter, style);
end

-- 绘制外框线
function ElementUI:RenderOutline(painter, style)
    local outlineWidth, outlineColor = style["outline-width"], style["outline-color"];
    local x, y, w, h = self:GetGeometry();
    if (not outlineWidth or not outlineColor) then return end
    painter:SetPen(outlineColor);
    painter:DrawRectTexture(x, y - outlineWidth , w, outlineWidth, background); -- 上
    painter:DrawRectTexture(x + w, y , outlineWidth, h, background); -- 右
    painter:DrawRectTexture(x, y + h , w, outlineWidth, background); -- 下
    painter:DrawRectTexture(x - outlineWidth, y , outlineWidth, h, background); -- 左
end

-- 绘制背景
function ElementUI:RenderBackground(painter, style)
    local background, backgroundColor = style:GetBackground(), style:GetBackgroundColor();
    local x, y, w, h = self:GetGeometry();
    -- ElementUIDebug.Format("RenderBackground Name = %s, x = %s, y = %s, w = %s, h = %s, background = %s, backgroundColor = %s", self:GetName(), x, y, w, h, background, backgroundColor);
	painter:SetPen(backgroundColor);
	painter:DrawRectTexture(x, y, w, h, background);
end

-- 绘制边框
function ElementUI:RenderBorder(painter, style)
    local borderWidth, borderColor = style["border-width"], style["border-color"];
    local x, y, w, h = self:GetGeometry();
    if (not borderWidth or not borderColor) then return end
    painter:SetPen(borderColor);
    painter:DrawRectTexture(x, y - borderWidth , w, borderWidth, background); -- 上
    painter:DrawRectTexture(x + w, y , borderWidth, h, background); -- 右
    painter:DrawRectTexture(x, y + h , w, borderWidth, background); -- 下
    painter:DrawRectTexture(x - borderWidth, y , borderWidth, h, background); -- 左
end

-- 绘制内容
function ElementUI:RenderContent()
end

-- 元素位置
function ElementUI:SetGeometry(x, y, w, h)
    self:GetRect():setRect(x, y, w, h);
end

function ElementUI:GetGeometry()
    return self:GetRect():getRect();
end

function ElementUI:GetX()
	return self:GetRect():x();
end

function ElementUI:GetY()
	return self:GetRect():y();
end

function ElementUI:SetX(x)
	self:GetRect():setX(x);
end

function ElementUI:SetY(y)
	self:GetRect():setY(y);
end

function ElementUI:GetWidth()
	return self:GetRect():width();
end

function ElementUI:GetHeight()
	return self:GetRect():height();
end

function ElementUI:SetWidth(w)
    self:GetRect():setWidth(w);
end

function ElementUI:SetHeight(h)
    self:GetRect():setHeight(h);
end

function ElementUI:SetPosition(x, y)
    self:GetRect():setPosition(x, y);
end

function ElementUI:GetPosition()
    return self:GetX(), self:GetY();
end

function ElementUI:SetSize(w, h)
    self:GetRect():setSize(w, h);
end

function ElementUI:GetSize()
    return self:GetWidth(), self:GetHeight();
end

function ElementUI:SetScreenPos(x, y)
    self.screenX, self.screenY = x, y;
end

function ElementUI:GetScreenPos()
    return self.screenX, self.screenY;
end

-- 是否捕获鼠标
function ElementUI:IsMouseCaptured()
    return self:GetMouseCapture() == self;
end

-- 捕获鼠标
function ElementUI:CaptureMouse()
	local lastCaptured = self:GetWindow():GetMouseCaptureElement();
	if(lastCaptured) then lastCaptured:ReleaseMouseCapture() end
    self:GetWindow():SetMouseCaptureElement(self);
end

-- 获取鼠标捕获
function ElementUI:GetMouseCapture()
    return self:GetWindow():GetMouseCaptureElement();
end

-- 释放鼠标捕获
function ElementUI:ReleaseMouseCapture()
	if (self:IsMouseCaptured()) then
        self:GetWindow():SetMouseCaptureElement(nil);
    end
end

-- 是否可以拖拽
function ElementUI:IsDraggable()
    return self:GetAttrValue("draggable") == true and true or false;
end

-- https://developer.mozilla.org/en-US/docs/Web/Events
-- Capture
function ElementUI:OnMouseDownCapture(event)
end

function ElementUI:OnMouseMove(event)
    -- self:SetHoverElement(self);
    -- event:accept();
end

function ElementUI:OnMouseLeave()
end

function ElementUI:OnMouseEnter()
end


function ElementUI:IsCanHover()
    return true;
end

-- 是否是光标元素
function ElementUI:IsHover()
    return self:GetHover() == self;
end

-- 获取光标元素
function ElementUI:GetHover()
    return self:GetWindow() and self:GetWindow():GetHoverElement();
end

-- 鼠标悬浮
function ElementUI:OnHover()
end

-- 鼠标取消悬浮
function ElementUI:OffHover()
end

-- 设置光标元素
function ElementUI:SetHover(element)
    local window = self:GetWindow();
    if (not window) then return end
    local hoverElement = window:GetHoverElement();
    if (hoverElement == element) then return end
    if (hoverElement) then
        hoverElement:OnMouseLeave(MouseEvent:init("mouseLeaveEvent", window));
        hoverElement:SelectStyle("OffHover");
        hoverElement:OffHover();
    end
    window:SetHoverElement(element);
    if (element and element:IsCanHover()) then
        element:OnMouseEnter(MouseEvent:init("mouseEnterEvent", window));
        element:OnHover();
        element:SelectStyle("OnHover");
        ElementUIDebug.Format("Hover Element, Name = %s", element:GetName());
    end
end

function ElementUI:OnFocusOut()
end

function ElementUI:OnFocusIn()
end

function ElementUI:IsCanFocus()
    return true;
end

-- 是否是聚焦元素
function ElementUI:IsFocus()
    return self:GetFocus() == self;
end

-- 获取聚焦元素
function ElementUI:GetFocus()
    return self:GetWindow() and self:GetWindow():GetFocusElement();
end

-- 设置聚焦元素
function ElementUI:SetFocus(element)
    local window = self:GetWindow();
    if (not window) then return end
    local focusElement = window:GetFocusElement();
    if (focusElement == element) then return end
    if (focusElement) then
        focusElement:OnFocusOut();
        focusElement:SelectStyle("FocusOut");
    end
    window:SetFocusElement(element);
    if (element and element:IsCanFocus()) then
        element:OnFocusIn();
        element:SelectStyle("FocusIn");
        ElementUIDebug.Format("Hover Element, Name = %s", element:GetName());
    end
end

-- 计算样式
function ElementUI:SelectStyle(action)
    local isNeedRefreshLayout = false;
    local style = self:GetStyle();
    if (not style) then return end
    if (not action) then
        if (self:IsFocus()) then action = "FocusIn" end
        if (self:IsHover()) then action = "OnHover" end
    end
    if (action == "OnHover" or action == "OffHover") then
        if (action == "OnHover") then 
            style:SelectHoverStyle();
        else
            style:SelectNormalStyle();
        end
        isNeedRefreshLayout = style:IsNeedRefreshLayout(style:GetHoverStyle()); 
    elseif (action == "FocusIn" or action == "FocusOut") then
        if (action == "FocusIn") then 
            style:SelectFocusStyle();
        else
            style:SelectNormalStyle();
        end
        isNeedRefreshLayout = style:IsNeedRefreshLayout(style:GetFocusStyle()); 
    else
        style:SelectNormalStyle();
    end
    if (isNeedRefreshLayout) then
        self:UpdateLayout();
    end 
end