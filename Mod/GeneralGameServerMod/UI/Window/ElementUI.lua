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

ElementUI:Property("Active", false, "IsActive");            -- 是否激活
ElementUI:Property("Hover", false, "IsHover");              -- 是否鼠标悬浮
ElementUI:Property("Visible", true);                        -- 可见性
ElementUI:Property("Render", false, "IsRender");            -- 是否渲染
ElementUI:Property("ZIndex", "");                           -- zindex 序
ElementUI:Property("CanFocus", false, "IsCanFocus");        -- 是否可以聚焦

local ElementUIDebug = GGS.Debug.GetModuleDebug("ElementUIDebug");
local ElementHoverDebug = GGS.Debug.GetModuleDebug("ElementHoverDebug").Disable(); 
local ElementFocusDebug = GGS.Debug.GetModuleDebug("ElementFocusDebug").Disable();

function ElementUI:ctor()
    self.winX, self.winY = 0, 0;                         -- 窗口坐标
    self.winWidth, self.winHeight = 0, 0;                -- 窗口大小
    self.AbsoluteElements, self.FixedElements = {}, {};
    self.RenderCacheList = {}
end

-- 是否显示
function ElementUI:IsVisible()
    return self:GetVisible() and self:GetLayout():IsVisible();
end

-- 是否存在
function ElementUI:IsExist()
    return self:GetVisible() and self:GetStyle().display ~= "none";
end

-- 是否需要渲染
function ElementUI:IsNeedRender()
    return not (self:IsRender() or not self:IsVisible());
end

function ElementUI:Render(painter)
    for i = 1, #self.AbsoluteElements do self.AbsoluteElements[i] = nil end
    for i = 1, #self.FixedElements do self.FixedElements[i] = nil end
    self:RenderStaticElement(painter, self);
    self:RenderAbsoluteElement(painter, self);
    self:RenderFixedElement(painter, self);
end

-- 元素渲染
function ElementUI:RenderStaticElement(painter, root)
    -- ElementUIDebug.If(self:GetAttrValue("id") == "debug", self:IsVisible(), self:GetWidth(), self:GetHeight());

    if (not self:IsNeedRender()) then return end
    local position = self:GetLayout():GetPositionStyle();
    if (self ~= root and (position == "absolute" or position == "fixed")) then
        if (position == "absolute") then 
            table.insert(root.AbsoluteElements, self);
        else
            table.insert(root.FixedElements, self);
        end
        return ;
    end
    
    self:SetRender(true);  -- 设置渲染标识 避免递归渲染

    -- 渲染元素
    self:OnRender(painter);
  
    -- 渲染子元素
    local left, top, width, height = self:GetGeometry();
    -- ElementUIDebug.FormatIf(self:GetAttrValue("id") == "debug", "RenderStaticElement left = %s, top = %s, width = %s, height = %s", left, top, width, height);

    painter:Translate(left, top);

    -- 存在滚动需要做裁剪
    local layout = self:GetLayout();
    local scrollX, scrollY = self:GetScrollPos();
    local isOverflowX, isOverflowY = layout:IsOverflowX(), layout:IsOverflowY();
    
    -- 绘制子元素
    for childElement in self:ChildElementIterator() do
        -- ElementUIDebug.If(self:GetAttrValue("id") == "debugp", childElement:GetXmlNode().attr);
        if (childElement:GetLayout():IsPositionElement()) then
            childElement:RenderStaticElement(painter, root);
        else 
            if (layout.overflowX == "hidden" or layout.overflowY == "hidden" or isOverflowX or isOverflowY) then
                -- ElementUIDebug.FormatIf(self:GetName() == "TextArea", "Render ScrollX = %s, ScrollY = %s", scrollX, scrollY);
                painter:Save();
                painter:SetClipRegion(0, 0, width, height);
                if (isOverflowX or isOverflowY) then painter:Translate(-scrollX, -scrollY) end
            end
            childElement:RenderStaticElement(painter, root);
            -- 恢复裁剪
            if (layout.overflowX == "hidden" or layout.overflowY == "hidden" or isOverflowX or isOverflowY) then
                if (isOverflowX or isOverflowY) then painter:Translate(scrollX, scrollY) end
                painter:Restore();
            end
        end
    end

    painter:Translate(-left, -top);
    
    self:SetRender(false); -- 清除渲染标识
end

function ElementUI:RenderAbsoluteElement(painter, root)
    local function render(elements, index)
        local len = #elements;
        local element = elements[index];

        offsetX, offsetY = offsetX or 0, offsetY or 0;
        
        if (index > len) then return end
        if (len == index) then return element:Render(painter) end

        painter:Translate(element:GetX(), element:GetY());

        local childElement = elements[index + 1];
        if (childElement:GetLayout():IsPositionElement()) then
            render(elements, index + 1);
        else
            -- 存在滚动需要做裁剪
            local layout = element:GetLayout();
            local width, height = element:GetSize();
            local scrollX, scrollY = element:GetScrollPos();
            local isOverflowX, isOverflowY = layout:IsOverflowX(), layout:IsOverflowY();
            if (isOverflowX or isOverflowY) then
                painter:Save();
                painter:SetClipRegion(0, 0, width, height);
                painter:Translate(-scrollX, -scrollY);
            end
            render(elements, index + 1);
            if (isOverflowX or isOverflowY) then
                painter:Translate(scrollX, scrollY);
                painter:Restore();
            end
        end

        painter:Translate(-element:GetX(), -element:GetY());
    end

    for _, absoulteElement in ipairs(self.AbsoluteElements) do
        local element, list = absoulteElement, absoulteElement.RenderCacheList;
        for i = 1, #list do list[i] = nil end
        while (element) do
            table.insert(list, 1, element);
            if (element == root) then break end
            element = element:GetParentElement();
        end
        render(list, 1);
    end
end

function ElementUI:RenderFixedElement(painter)
    for _, fixedElement in ipairs(self.FixedElements) do
        fixedElement:Render(painter);
    end
end

-- 绘制元素
function ElementUI:OnRender(painter)
    local transform = self:GetStyle().transform;
    if (type(transform) == "table" and #transform > 0) then
        local x, y, w, h = self:GetGeometry();
        local ratate = transform[1].to;
        painter:Translate(x + w / 2, y + h / 2);
        painter:Rotate(ratate);
        painter:Translate(-(x + w / 2), -(y + h / 2));
    end

    -- ElementUIDebug.If(self:GetTagName() == "GoodsTooltip", self:GetWindowPos());
    
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
    painter:DrawRectTexture(x - outlineWidth, y - outlineWidth , w + 2 * outlineWidth, outlineWidth);      -- 上
    painter:DrawRectTexture(x + w, y - outlineWidth, outlineWidth, h + 2 * outlineWidth);                  -- 右
    painter:DrawRectTexture(x - outlineWidth, y + h , w + 2 * outlineWidth, outlineWidth);                 -- 下
    painter:DrawRectTexture(x - outlineWidth, y - outlineWidth, outlineWidth, h + 2 * outlineWidth);       -- 左
end

-- 绘制背景
function ElementUI:RenderBackground(painter)
    local background, backgroundColor = self:GetBackground(), self:GetBackgroundColor();
    local x, y, w, h = self:GetGeometry();
    backgroundColor = backgroundColor or (background and "#ffffffff" or "#ffffff00");
    -- ElementUIDebug.FormatIf(self:GetName() == "ScrollBarThumb", "RenderBackground Name = %s, x = %s, y = %s, w = %s, h = %s, background = %s, backgroundColor = %s", self:GetName(), x, y, w, h, background, backgroundColor);
    -- ElementUIDebug.If(self:GetAttrValue("id") == "test", background);
    painter:SetPen(backgroundColor);
    local borderRadius = self:GetStyle()["border-radius"];
    if (background or not borderRadius) then
        painter:DrawRectTexture(x, y, w, h, background);
    else 
        painter:DrawRect(x + borderRadius, y + borderRadius, w - 2 * borderRadius, h - 2 * borderRadius);
        painter:DrawRect(x + borderRadius, y, w - 2 * borderRadius, borderRadius);                          -- 上
        painter:DrawRect(x + w - borderRadius, y + borderRadius, borderRadius, h - 2 * borderRadius);       -- 右
        painter:DrawRect(x + borderRadius, y + h - borderRadius, w - 2 * borderRadius, borderRadius);       -- 下
        painter:DrawRect(x, y + borderRadius, borderRadius, h - 2 * borderRadius);                          -- 左
        painter:DrawCircle(x + borderRadius, -y - borderRadius, 0, borderRadius, "z", true, nil, math.pi / 2, math.pi);
        painter:DrawCircle(x + w - borderRadius, -y - borderRadius, 0, borderRadius, "z", true, nil, 0, math.pi / 2);
        painter:DrawCircle(x + borderRadius, -y -h + borderRadius, 0, borderRadius, "z", true, nil, math.pi, math.pi * 3 / 2);
        painter:DrawCircle(x + w - borderRadius, -y -h + borderRadius, 0, borderRadius, "z", true, nil, math.pi * 3 / 2, math.pi * 2);
    end
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
function ElementUI:GetFont()
    return self:GetStyle():GetFont();
end

-- 获取字体大小
function ElementUI:GetFontSize(defaultValue)
    return self:GetStyle():GetFontSize(defaultValue);
end

-- 获取行高
function ElementUI:GetLineHeight(defaultValue)
    return self:GetStyle():GetLineHeight(defaultValue);
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
        self:UpdateWindowPos();
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
    if (oldx ~= x or oldy ~= y) then 
        self:OnSize();
    end
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
    self.winX, self.winY = x, y;
end

-- 获取元素相对窗口的坐标
function ElementUI:GetWindowPos()
    return self.winX, self.winY;
end

-- 设置元素相对窗口的大小
function ElementUI:SetWindowSize(w, h)
    self.winWidth, self.winHeight = w, h;
end

-- 获取元素相对窗口的大小
function ElementUI:GetWindowSize()
    return self.winWidth, self.winHeight;
end

-- 获取元素相对窗口坐标
function ElementUI:GetRelWindowPos()
    local windowWindowX, windowWindowY = self:GetWindow():GetWindowPos();
    local windowX, windowY = self:GetWindowPos();
    return windowX - windowWindowX, windowY - windowWindowY;
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
function ElementUI:UpdateWindowPos(forceUpdate)
    local parentScrollX, parentScrollY, parentWindowX, parentWindowY = 0, 0, 0, 0;
	local windowX, windowY, windowWidth, windowHeight = 0, 0, 0, 0;
    local x, y, w, h = self:GetGeometry();
    local oldWindowX, oldWindowY = self:GetWindowPos();
    local parentElement = self:GetParentElement();
    local position = self:GetStyle()["position"];
    if (parentElement and position ~= "fixed") then 
        parentWindowX, parentWindowY = parentElement:GetWindowPos();
        parentScrollX, parentScrollY = parentElement:GetScrollPos();
    end
    windowX, windowY = parentWindowX + x, parentWindowY + y;
    windowWidth, windowHeight = self:GetSize();
    if (position == "fixed") then
        windowX, windowY = self:GetPosition();
    elseif(position == "absolute") then
    else 
        windowX, windowY = windowX - parentScrollX, windowY - parentScrollY;
    end
    
    -- ElementUIDebug.FormatIf(self:GetAttrValue("id") == "test", "=================start===============");
    -- ElementUIDebug.FormatIf(self:GetAttrValue("id") == "test", "windowX = %s, windowY = %s, windowWidth = %s, windowHeight = %s, offsetX = %s, offsetY = %s, scrollX = %s, scrollY = %s", windowX, windowY, windowWidth, windowHeight, offsetX, offsetY, scrollX, scrollY);
    -- ElementUIDebug.FormatIf(parentElement and parentElement:GetAttrValue("id") == "test", "windowX = %s, windowY = %s, windowWidth = %s, windowHeight = %s, offsetX = %s, offsetY = %s, scrollX = %s, scrollY = %s", windowX, windowY, windowWidth, windowHeight, offsetX, offsetY, scrollX, scrollY);
    self:SetWindowPos(windowX, windowY);
    self:SetWindowSize(windowWidth, windowHeight);
    
    -- 更新子元素的窗口位置
    if (forceUpdate or oldWindowX ~= windowX or oldWindowY ~= windowY) then 
        for child in self:ChildElementIterator() do
            child:UpdateWindowPos(forceUpdate);
        end
    end
    -- ElementUIDebug.FormatIf(self:GetAttrValue("id") == "test", "============End========= windowX = %s, windowY = %s, windowWidth = %s, windowHeight = %s, offsetX = %s, offsetY = %s, scrollX = %s, scrollY = %s", windowX, windowY, windowWidth, windowHeight, offsetX, offsetY, scrollX, scrollY);
end

-- 获取元素相对屏幕的坐标
function ElementUI:GetScreenPos()
    local windowX, windowY = self:GetWindowPos();
    local screenX, screenY = self:GetWindow():GetScreenPosition();
    return screenX + windowX, screenY + windowY;
end

-- 指定点是否在元素视区内
function ElementUI:IsContainPoint(screenX, screenY)
    local left, top = self:GetScreenPos();
    local width, height = self:GetWindowSize();
    local right, bottom = left + width, top + height;
    return left <= screenX and screenX <= right and top <= screenY and screenY <= bottom;
end

-- 获取指定点相对元素位置
function ElementUI:GetRelPoint(screenX, screenY)
    local sx, sy = self:GetScreenPos();
    return screenX - sx, screenY - sy;
end

-- 获取滚动条的位置
function ElementUI:GetScrollPos()
    local scrollX, scrollY = 0, 0;
    if (self.horizontalScrollBar and self:GetLayout():IsOverflowX()) then scrollX = self.horizontalScrollBar.scrollLeft end
    if (self.verticalScrollBar and self:GetLayout():IsOverflowY()) then scrollY = self.verticalScrollBar.scrollTop end
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
    local style = self:GetStyle();
    local draggable = self:GetAttrBoolValue("draggable") == true and true or false;
    return draggable and (self:IsWindow() or style.position == "fixed" or style.position == "absolute");
end

-- https://developer.mozilla.org/en-US/docs/Web/Events
-- Capture
function ElementUI:OnMouseDownCapture(event)
end

function ElementUI:OnClick(event)
    self:CallAttrFunction("onclick", nil, self, event);
end

function ElementUI:OnContextMenu()
end

function ElementUI:OnChange(value)
    self:CallAttrFunction("onchange", nil, value, self, event);
end

function ElementUI:OnMouseDown(event)
    if(event:isAccepted()) then return end
    if (self:CallAttrFunction("onmousedown", nil, self, event)) then return end

    -- 默认拖拽处理
    if(self:IsDraggable() and event:button() =="left") then
        self.isMouseDown = true;
        self.isDragging = false;
        self.startDragX, self.startDragY = ParaUI.GetMousePosition();
        self.startDragElementX, self.startDragElementY = self:GetPosition();
        self.startDragScreenX, self.startDragScreenY = self:GetWindow():GetScreenPosition();
		event:accept();
	end
end

function ElementUI:OnMouseMove(event)
    if(event:isAccepted()) then return end
    if (self:CallAttrFunction("onmousemove", nil, self, event)) then return end

    local x, y = ParaUI.GetMousePosition();
	if(self.isMouseDown and ParaUI.IsMousePressed(0) and self:IsDraggable() and event:button() == "left") then
		if(not self.isDragging) then
			if(math.abs(x - self.startDragX) > 2 or math.abs(y - self.startDragY) > 2) then
                self.isDragging = true;
				self:CaptureMouse();
			end
        elseif(self.isDragging) then
            local offsetX, offsetY = x - self.startDragX, y - self.startDragY;
            if (self:IsWindow()) then
                local _, _, screenWidth, screenHeight = self:GetScreenPosition();
                self:GetWindow():GetNativeWindow():Reposition("_lt", self.startDragScreenX + offsetX, self.startDragScreenY + offsetY, screenWidth, screenHeight);
            else 
                self:SetPosition(self.startDragElementX + offsetX, self.startDragElementY + offsetY);
            end
		end
		if(self.isDragging) then
			event:accept();
		end
	end
end

function ElementUI:OnMouseUp(event)
    if(event:isAccepted()) then return end

    if (self:CallAttrFunction("onmouseup", nil, self, event)) then return end;

    if (event:button() == "right") then 
        self:OnContextMenu(event);
    else
        self:OnClick(event)
    end
    
	if(self.isDragging) then
        self.isDragging = false;
        local left, top = self:GetPosition();
        self:SetStyleValue("left", left);
        self:SetStyleValue("top", top);
        self:UpdateWindowPos(true);
		self:ReleaseMouseCapture();
		event:accept();
	end
	self.isMouseDown = false;
end

function ElementUI:OnMouseLeave()
    self:CallAttrFunction("onmouseleave", nil, self, event);
end

function ElementUI:OnMouseEnter()
    self:CallAttrFunction("onmouseenter", nil, self, event);
end

function ElementUI:OnHover(isHover)
    self:CallAttrFunction("onhover", nil, isHover, self);
end

-- 悬浮
function ElementUI:Hover(event, isUpdateLayout, zindex, isParentElementHover, isParentPositionElement, scrollElement)
    local isChangeHoverState = false;
    local hoverElement = nil;
    
    isParentElementHover = isParentElementHover == nil and true or isParentElementHover;
    zindex = (zindex or "") .. "-" .. self:GetZIndex();

    local function SetElementOffHover(element)
        if (element:IsHover()) then
            element:SetHover(false);
            isChangeHoverState = true
            element:OnMouseLeave();
            element:OnHover(false);
        end
        for child in element:ChildElementIterator() do
            SetElementOffHover(child);
        end
    end

    local maxZIndex = zindex;
    local parentElement = self:GetParentElement();
    local isPositionElement = self:GetLayout():IsPositionElement();
    local isContainPoint = self:IsContainPoint(event.x, event.y);
    local isHover = isContainPoint and isParentElementHover;
    if (isContainPoint) then
        if (isParentElementHover) then
            isHover = true;
        elseif(isPositionElement) then
            if (not scrollElement or scrollElement == self:GetParentElement()) then
                isHover = true;
            end
        end
    elseif (scrollElement) then
        if (isPositionElement) then 
            scrollElement = nil;
        else 
            SetElementOffHover(self);
            if (isUpdateLayout and isChangeHoverState) then self:UpdateLayout(true) end
            return nil, maxZIndex; 
        end
    end

    -- 设置滚动元素
    local scrollX, scrollY = self:GetScrollPos();
    if (scrollX > 0 or scrollY > 0) then scrollElement = self end

    if (isHover) then
        hoverElement = self;
        if (not self:IsHover()) then
            -- ElementUIDebug.If(self:GetAttrStringValue("class") == "project btn", "---------------OnHover-----------");
            self:SetHover(true);
            isChangeHoverState = true
            self:OnHover(true);
            self:OnMouseEnter();
        end
    else 
        if (self:IsHover()) then
            -- ElementUIDebug.If(self:GetAttrStringValue("class") == "project btn", "---------------OffHover-----------");
            self:SetHover(false);
            isChangeHoverState = true
            self:OnHover(false);
            self:OnMouseLeave();
        end
    end

    -- 事件序遍历 取第一悬浮元素
    for child in self:ChildElementIterator(false) do
        local childHoverElement, childZIndex = child:Hover(event, isUpdateLayout and not isChangeHoverState, zindex, isHover, isPositionElement, scrollElement);  -- 若父布局更新, 则子布局无需更新 
        if (childHoverElement and maxZIndex < childZIndex) then
            hoverElement = childHoverElement;
            maxZIndex = childZIndex;
        end
    end

    -- 需要更新且发送状态改变
    if (isUpdateLayout and isChangeHoverState) then 
        self:UpdateLayout(true);
    end

    return hoverElement, maxZIndex;
end

function ElementUI:OnFocusOut()
    local onblur = self:GetAttrFunctionValue("onblur");
	if (onblur) then onblur() end
end

function ElementUI:OnFocusIn()
    local onfocus = self:GetAttrFunctionValue("onfocus");
	if (onfocus) then onfocus() end
end

-- 是否是聚焦元素
function ElementUI:IsFocus()
    return self:GetFocus() == self;
end

-- 元素主动聚焦
function ElementUI:FocusIn()
    self:SetFocus(self:IsCanFocus() and self or nil);
end

-- 元素主动失去焦点
function ElementUI:FocusOut()
    self:SetFocus(nil);
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
    window:SetFocusElement(element);
    if (focusElement == element) then return end
    if (element) then
        element:OnFocusIn();
        -- self:UpdateLayout(true);
        ElementFocusDebug.Format("Focus Element, Name = %s", element:GetName());
    end
    if (focusElement) then
        focusElement:OnFocusOut();
        -- self:UpdateLayout(true);  -- 太过耗时
    end
end

-- 选择样式
function ElementUI:SelectStyle()
    local style = self:GetStyle();
    style:UnselectStyle();
    style:SelectNormalStyle();
    if (self:IsFocus()) then style:SelectFocusStyle() end
    if (self:IsHover()) then style:SelectHoverStyle() end
end

-- 鼠标滚动事件
function ElementUI:OnMouseWheel(event)
    if (self:GetLayout():IsOverflowY()) then 
        if (self.verticalScrollBar) then
            self.verticalScrollBar:OnMouseWheel(event);
        end
    end
end

function ElementUI:OnKeyDown(event)
end

function ElementUI:OnKeyUp(event)
end

function ElementUI:OnKey(event)
end

function ElementUI:OnMouseDownCapture()
end
function ElementUI:OnMouseUpCapture()
end
function ElementUI:OnMouseMoveCapture()
end
function ElementUI:OnMouseWheelCapture()
end
function ElementUI:OnMouseEnterCapture()
end
function ElementUI:OnMouseLeaveCapture()
end
function ElementUI:OnMouseCapture()
end
function ElementUI:OnMouse()
end