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
ElementUI:Property("Visible", true);                        -- 可见性

local ElementUIDebug = GGS.Debug.GetModuleDebug("ElementUIDebug");
local ElementHoverDebug = GGS.Debug.GetModuleDebug("ElementHoverDebug").Disable();
local ElementFocusDebug = GGS.Debug.GetModuleDebug("ElementFocusDebug").Disable();

function ElementUI:ctor()
    self.windowX, self.windowY = 0, 0;                         -- 窗口内坐标
end

-- 是否显示
function ElementUI:IsVisible()
    if (not self:GetVisible()) then return false end
    local style = self:GetStyle();
    return not style or style.display ~= "none";
end

-- 是否需要渲染
function ElementUI:IsNeedRender()
    local style = self:GetStyle();
    if (self.isRender 
        or not self:IsVisible() 
        or not style 
        or style.display == "none" 
        or style.visibility == "hidden" 
        or self:GetWidth() == 0 
        or self:GetHeight() == 0) then 
            return false; 
        end
    return true;
end

-- 元素渲染
function ElementUI:Render(painter)
	if (not self:IsNeedRender()) then return end
    self.isRender = true;  -- 设置渲染标识 避免递归渲染
    -- 渲染元素
    self:OnRender(painter);  

    -- 渲染子元素
    painter:Translate(self:GetX(), self:GetY());

    -- 存在滚动需要做裁剪
    local layout = self:GetLayout();
    local width, height = self:GetSize();
    local scrollX, scrollY = self:GetScrollPos();
    if (layout:IsOverflowX() or layout:IsOverflowY()) then
        -- ElementUIDebug.FormatIf(self:GetName() == "TextArea", "Render ScrollX = %s, ScrollY = %s", scrollX, scrollY);
        painter:Save();
        painter:SetClipRegion(0, 0, width, height);
        painter:Translate(-scrollX, -scrollY);
    end

    -- 绘制子元素
    for childElement in self:ChildElementIterator() do
        childElement:Render(painter);
    end

    -- 恢复裁剪
    if (layout:IsOverflowX() or layout:IsOverflowY()) then
        painter:Translate(scrollX, scrollY);
        painter:Restore();
    end
    
    painter:Translate(-self:GetX(), -self:GetY());
    self.isRender = false; -- 清除渲染标识
end

-- 绘制元素
function ElementUI:OnRender(painter)
    self:RenderOutline(painter);
    self:RenderBackground(painter);
    self:RenderBorder(painter);
    -- 绘制元素内容
    self:RenderContent(painter);
end

-- 绘制外框线
function ElementUI:RenderOutline(painter)
    local style = self:GetStyle();
    local outlineWidth, outlineColor = style["outline-width"], style["outline-color"];
    local x, y, w, h = self:GetGeometry();
    if (not outlineWidth or not outlineColor) then return end
    painter:SetPen(outlineColor);
    painter:DrawRectTexture(x - outlineWidth, y - outlineWidth , w + 2 * outlineWidth, outlineWidth);  -- 上
    painter:DrawRectTexture(x + w, y - outlineWidth, outlineWidth, h + 2 * outlineWidth); -- 右
    painter:DrawRectTexture(x - outlineWidth, y + h , w + 2 * outlineWidth, outlineWidth);             -- 下
    painter:DrawRectTexture(x - outlineWidth, y - outlineWidth, outlineWidth, h + 2 * outlineWidth); -- 左
end

-- 绘制背景
function ElementUI:RenderBackground(painter)
    local style = self:GetStyle();
    local background, backgroundColor = style:GetBackground(), style:GetBackgroundColor("#ffffff00");
    local x, y, w, h = self:GetGeometry();

    -- ElementUIDebug.FormatIf(self:GetName() == "ScrollBarThumb", "RenderBackground Name = %s, x = %s, y = %s, w = %s, h = %s, background = %s, backgroundColor = %s", self:GetName(), x, y, w, h, background, backgroundColor);

    painter:SetPen(backgroundColor);
	painter:DrawRectTexture(x, y, w, h, background);
end

-- 绘制边框
function ElementUI:RenderBorder(painter)
    local style = self:GetStyle();
    local borderWidth, borderColor = style["border-width"], style["border-color"];
    local x, y, w, h = self:GetGeometry();
    if (not borderWidth or not borderColor) then return end
    painter:SetPen(borderColor);
    painter:DrawRectTexture(x, y, w, borderWidth); -- 上
    painter:DrawRectTexture(x + w - borderWidth, y , borderWidth, h); -- 右
    painter:DrawRectTexture(x, y + h - borderWidth, w, borderWidth); -- 下
    painter:DrawRectTexture(x, y , borderWidth, h); -- 左
end

-- 绘制内容
function ElementUI:RenderContent(painter)
end


-- 获取字体
function ElementUI:GetFont(defaultValue)
    return self:GetStyle():GetFont(defaultValue);
end

-- 获取字体颜色
function ElementUI:GetColor(defaultValue)
    return self:GetStyle():GetColor(defaultValue);
end

-- 获取背景
function ElementUI:GetBackground(defaultValue)
    return self:GetStyle():GetBackground(defaultValue);
end

-- 获取背景颜色
function ElementUI:GetBackgroundColor(defaultValue)
    return self:GetStyle():GetBackgroundColor(defaultValue);
end

-- 元素位置更新
function ElementUI:OnSize()
end

-- 元素位置
function ElementUI:SetGeometry(x, y, w, h)
    local oldx, oldy, oldw, oldh = self:GetGeometry();
    self:GetRect():setRect(x, y, w, h);
    if (oldx ~= x or oldy ~= y or oldw ~= w or oldh ~= h) then
        self:OnSize();
    end
end

function ElementUI:GetGeometry()
    return self:GetRect():getRect();
end

function ElementUI:GetContentGeometry()
    local x, y = self:GetLayout():GetContentPos();
    local w, h = self:GetLayout():GetContentWidthHeight();
    return x, y, w, h;
end

function ElementUI:GetX()
	return self:GetRect():x();
end

function ElementUI:GetY()
	return self:GetRect():y();
end

function ElementUI:SetX(x)
    self:SetPosition(x, self:GetY());
end

function ElementUI:SetY(y)
    self:SetPosition(self:GetX(), y);
end

function ElementUI:GetWidth()
	return self:GetRect():width();
end

function ElementUI:GetHeight()
	return self:GetRect():height();
end

function ElementUI:SetWidth(w)
    self:SetSize(w, self:GetHeight());
end

function ElementUI:SetHeight(h)
    self:SetSize(self:GetWidth(), h);
end

function ElementUI:SetPosition(x, y)
    local oldx, oldy = self:GetPosition();
    self:GetRect():setPosition(x, y);
    if (oldx ~= x or oldy ~= y) then self:OnSize() end
end

function ElementUI:GetPosition()
    return self:GetX(), self:GetY();
end

function ElementUI:SetSize(w, h)
    local oldw, oldh = self:GetSize();
    self:GetRect():setSize(w, h);
    if (oldw ~= w or oldh ~= h) then self:OnSize() end
end

function ElementUI:GetSize()
    return self:GetWidth(), self:GetHeight();
end

-- 设置元素相对窗口的坐标
function ElementUI:SetWindowPos(x, y)
    self.windowX, self.windowY = x, y;
end

-- 获取元素相对窗口的坐标
function ElementUI:GetWindowPos()
    return self.windowX, self.windowY;
end
-- 全局坐标转窗口坐标
function ElementUI:GloablToWindowPos()
end 

-- 全局坐标转元素内坐标
function ElementUI:GloablToGeometryPos()
end
-- 全局坐标转元素内容区坐标
function ElementUI:GlobalToContentGeometryPos()
end

-- 更新元素窗口的坐标
function ElementUI:UpdateWindowPos()
    local parentElement = self:GetParentElement();
	local windowX, windowY = 0, 0;
	local x, y = self:GetPosition();
    windowX, windowY = windowX + x, windowY + y;
    self:SetWindowPos(windowX, windowY);
    -- 更新子元素的窗口位置
	for child in self:ChildElementIterator() do
        child:UpdateWindowPos();
    end
end

-- 获取元素相对屏幕的坐标
function ElementUI:GetScreenPos()
    local windowX, windowY = self:GetWindowPos();
    local screenX, screenY = self:GetWindow():GetScreenPos();
    return screenX + windowX, screenY + windowY;
end

-- 指定点是否在元素视区内
function ElementUI:IsContainPoint(screenX, screenY)
    local left, top = self:GetScreenPos();
    local width, height = self:GetSize();
    local right, bottom = left + width, top + height;
    return left <= screenX and screenX <= right and top <= screenY and screenY <= bottom;
end

-- 获取滚动条的位置
function ElementUI:GetScrollPos()
    local scrollX, scrollY = 0, 0;
    if (self.horizontalScrollBar and self.horizontalScrollBar:IsVisible()) then scrollX = self.horizontalScrollBar.scrollLeft end
    if (self.verticalScrollBar and self.verticalScrollBar:IsVisible()) then scrollY = self.verticalScrollBar.scrollTop end
    return scrollX, scrollY;
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
        ElementHoverDebug.Format("Hover Element, Name = %s", element:GetName());
    end
end

function ElementUI:OnFocusOut()
end

function ElementUI:OnFocusIn()
end

function ElementUI:IsCanFocus()
    return false;
end

-- 是否是聚焦元素
function ElementUI:IsFocus()
    return self:GetFocus() == self;
end

-- 元素主动聚焦
function ElementUI:FocusIn()
    self:SetFocus(self);
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
        ElementFocusDebug.Format("Focus Element, Name = %s", element:GetName());
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
    -- ElementUIDebug.Format("Select Style: Name = %s", self:GetName());
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

-- 鼠标滚动事件
function ElementUI:OnMouseWheel(event)
    if (self.verticalScrollBar and self.verticalScrollBar:IsVisible()) then self.verticalScrollBar:OnMouseWheel(event) end
end

function ElementUI:OnKeyDown(event)
end

function ElementUI:OnKeyUp(event)
end

function ElementUI:OnKey(event)
end