--[[
Title: ElementBase
Author(s): wxa
Date: 2020/6/30
Desc: 元素基类, 主要实现元素绘制相关功能
use the lib:
-------------------------------------------------------
local ElementBase = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/ElementBase.lua");
-------------------------------------------------------
]]

local ElementBase = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

ElementBase:Property("Value");                                -- 元素值
ElementBase:Property("Active", false, "IsActive");            -- 是否激活
ElementBase:Property("Hover", false, "IsHover");              -- 是否鼠标悬浮


-- 是否需要
function ElementBase:IsRender()
    local style = self:GetStyle();
    if (self.isRender or not style or style.display == "none" or style.visibility == "hidden" or self:GetWidth() == 0 or self:GetHeight() == 0) then return true end
    return false;
end

-- 元素渲染
function ElementBase:Render(painterContext)
	if (self:IsRender()) then return end

    self.isRender = true;  -- 设置渲染标识 避免递归渲染
    -- if(self.transform) then self:applyRenderTransform(painterContext, self.transform) end

    self:OnRender(painterContext);  -- 渲染元素

    self.isRender = false; -- 清除渲染标识

    -- 渲染子元素
    painterContext:Translate(self:GetX(), self:GetY());
    for childElement in self:ChildrenElementIterator() do
        childElement:Render(painterContext);
    end
    painterContext:Translate(-self:GetX(), -self:GetY());

	-- if(self.transform) then painterContext:Restore() end
end

-- 绘制元素
function ElementBase:OnRender(painter)
    local style = self:GetCurrentStyle();

    self:RenderOutline(painter, style);
    self:RenderBackground(painter, style);
    self:RenderBorder(painter, style);
    self:RenderContent(painter, style);
end

-- 绘制外框线
function ElementBase:RenderOutline(painter, style)
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
function ElementBase:RenderBackground(painter, style)
    local background, backgroundColor = style:GetBackground(), style:GetBackgroundColor("#ffffff");
    local x, y, w, h = self:GetGeometry();
	painter:SetPen(backgroundColor);
	painter:DrawRectTexture(x, y, w, h, background);
end

-- 绘制边框
function ElementBase:RenderBorder(painter, style)
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
function ElementBase:RenderContent()
end

-- 元素位置
function ElementBase:SetGeometry(x, y, w, h)
    self:GetRect():setRect(x, y, w, h);
end

function ElementBase:GetGeometry()
    return self:GetRect():getRect();
end

function ElementBase:GetX()
	return self:GetRect():x();
end

function ElementBase:GetY()
	return self:GetRect():y();
end

function ElementBase:SetX(x)
	self:GetRect():setX(x);
end

function ElementBase:SetY(y)
	self:GetRect():setY(y);
end

function ElementBase:GetWidth()
	return self:GetRect():width();
end

function ElementBase:GetHeight()
	return self:GetRect():height();
end

function ElementBase:SetWidth(w)
    self:GetRect():setWidth(w);
end

function ElementBase:SetHeight(h)
    self:GetRect():setHeight(h);
end

function ElementBase:SetPosition(x, y)
    self:GetRect():setPosition(x, y);
end

function ElementBase:SetSize(w, h)
    self:GetRect():setSize(w, h);
end