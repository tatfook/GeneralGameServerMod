--[[
Title: ElementLayout
Author(s): wxa
Date: 2020/8/14
Desc: 实现元素CSS属性的应用
------------------------------------------------------------

CSS 相关属性解释
元素宽高: 包含边框, 填充, 内容 width = border + margin + contentWidth
元素百分比: 取父元素最大大小的百分比 size = parentMaxSize * percentage
]]

local ElementLayout = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

-- 属性定义
ElementLayout:Property("UseSpace", true, "IsUseSpace");  -- 是否占据文档流空间
ElementLayout:Property("Element");                       -- 元素
ElementLayout:Property("ParentElementLayout");           -- 父元素布局
ElementLayout:Property("Style");                         -- 元素样式
ElementLayout:Property("Window");                        -- 所属窗口
local nid = 0;

-- 失效布局
function ElementLayout:invalidate()
	-- self:SetPos(0, 0);
	-- self:SetAvailablePos(0, 0);
	-- self:SetRealWidthHeight(0, 0);
	-- self:SetWidthHeight(0, 0);
	self:Reset();
end


-- 激活布局
function ElementLayout:activate()
	if (not self:GetWindow() or not self:GetWindow():GetRootElement()) then return end
	-- 获取窗体宽高
	local width, height = self:GetWindow():width(), self:GetWindow():height();
	-- 重置布局
	self:Reset();
	-- 设置布局大小
	self:SetWidthHeight(width, height);
	-- 开始元素布局
	self:UpdateElementLayout(self:GetWindow():GetRootElement());
end

-- 重置布局
function ElementLayout:Reset()
	-- 右侧可用位置
	-- self.rightAvailableX = 0;
	-- self.rightAvailableY = 0;
	-- 当前可用位置
	self.availableX = 0;
	self.availableY = 0;
	-- 相对于父元素的位置
	self.x = 0;
	self.y = 0
	-- 元素宽高 
	self.width = nil;
	self.height = nil;
	-- 真实宽高
	self.realWidth = 0;
	self.realHeight = 0;
end

-- 初始化
function ElementLayout:Init(element, parentElementLayout, window)
	self:Reset();
	
	nid = nid + 1;
	self.nid = nid;

	self:SetStyle({});
	self:SetElement(element);
	self:SetParentElementLayout(parentElementLayout);
	self:SetWindow(window);

	self:InitLayout();

	return self;
end

-- 获取窗口位置 x, y, w, h    (w, h 为宽高, 非坐标)
function ElementLayout:GetWindowPosition()
	return self:GetWindow():GetNativeWindow():GetAbsPosition();
end
-- 获取屏幕(应用程序窗口)位置 x, y, w, h    (w, h 为宽高, 非坐标)
function ElementLayout:GetScreenPosition()
	return ParaUI.GetUIObject("root"):GetAbsPosition();
end
-- 获取页面元素的CSS
function ElementLayout:GetElementStyle()
	return self:GetElement() and self:GetElement():GetStyle();
end
-- 设置位置坐标
function ElementLayout:SetPos(x, y)
	self.x, self.y = x, y;
end
-- 获取位置坐标
function ElementLayout:GetPos()
	return self.x or 0, self.y or 0; 
end
-- 偏移位置
function ElementLayout:OffsetPos(dx, dy)
	self.x = self.x + (dx or 0);
	self.y = self.y + (dy or 0);
end
-- 设置宽高 非坐标 包含 padding border
function ElementLayout:SetWidthHeight(width, height)
	self.width, self.height = width, height;
end
-- 获取宽高 非坐标 包含 padding border
function ElementLayout:GetWidthHeight()
	return self.width, self.height;
end
-- 设置真实宽高
function ElementLayout:SetRealWidthHeight(width, height)
	self.realWidth, self.realHeight = width, height;
end
-- 获取真实宽高
function ElementLayout:GetRealWidthHeight()
	return self.realWidth, self.realHeight;
end
-- 获取填充 left top right bottom
function ElementLayout:GetPaddings()
	local style = self:GetStyle();
	return style.paddingLeft, style.paddingTop, style.paddingRight, style.paddingBottom;
end
-- 获取边距
function ElementLayout:GetMargins()
	local style = self:GetStyle();
	return style.marginLeft, style.marginTop, style.marginRight, style.marginBottom;
end
-- 设置可用位置
function ElementLayout:SetAvailablePos(availableX, availableY)
	self.availableX, self.availableY = availableX, availableY;
end
-- 获取可用位置
function ElementLayout:GetAvailablePos()
	return self.availableX, self.availableY;
end
-- 是否是有效布局
function ElementLayout:IsValid()
	return self:GetElementStyle() and self:GetStyle().display ~= "none";
end

-- 百分比转数字
function ElementLayout:PercentageToNumber(percentage, maxsize)
	if (type(percentage) == "number") then return percentage end;
	if (type(percentage) ~= "string") then return end
	local number = tonumber(string.match(percentage, "[%+%-]?%d+"));
	if (string.match(percentage, "%%$")) then
		number = maxsize and math.floor(maxsize * number /100);
	end
	return number;
end

-- 块元素识别
function ElementLayout:IsBlockElement()
	local style = self:GetStyle();
	return (not style.display or style.display == "block") and not style.float;
end

-- 处理布局准备工作, 单位数字化
function ElementLayout:InitLayout()
	-- 获取父元素布局
	local parentElementLayout = self:GetParentElementLayout();
	if (not parentElementLayout or not self:IsValid()) then return end

	-- 获取样式表
	local css = self:GetElementStyle();

	-- 保存布局最大大小
	local parentWidth, parentHeight = parentElementLayout:GetWidthHeight();

	local style = self:GetStyle();
	for key, val in pairs(css) do
		if (type(key) == "string" and (type(val) == "string" or type(val) == "number")) then
			style[key] = val;
		end
	end

	if (css.float and (css.float == "left" or css.float == "right")) then style.float = css.float end
	if (css.position and (css.position == "relative" or css.position == "absolute" or css.position == "fixed" or css.position == "static" or css.position == "screen")) then style.position = css.position end
	if (css.align and (css.align == "left" or css.align == "center" or css.align == "right")) then style.align = css.align end
	if (css.valign and (css.valign == "left" or css.valign == "center" or css.valign == "right")) then style.valign = css.valign end

	-- 数字最大最小宽高
	local minWidth, minHeight, maxWidth, maxHeight = css["min-width"], css["min-height"], css["max-width"], css["max-height"];
	minWidth = self:PercentageToNumber(minWidth, parentWidth);
	maxWidth = self:PercentageToNumber(maxWidth, parentWidth);
	minHeight = self:PercentageToNumber(minHeight, parentHeight);
	maxHeight = self:PercentageToNumber(maxHeight, parentHeight);
	style.minWidth, style.minHeight, style.maxWidth, style.maxHeight = minWidth, minHeight, maxWidth, maxHeight;
	-- 数字化边距
	local marginLeft, marginTop, marginRight, marginBottom = css["margin-left"], css["margin-top"], css["margin-right"], css["margin-bottom"];
	marginLeft = self:PercentageToNumber(marginLeft, parentWidth);
	marginRight = self:PercentageToNumber(marginRight, parentWidth);
	marginTop = self:PercentageToNumber(marginTop, parentHeight);
	marginBottom = self:PercentageToNumber(marginBottom, parentHeight);
	style.marginLeft, style.marginTop, style.marginRight, style.marginBottom = marginLeft or 0, marginTop or 0, marginRight or 0, marginBottom or 0;
	-- 数字化填充
	local paddingLeft, paddingTop, paddingRight, paddingBottom = css["padding-left"], css["padding-top"], css["padding-right"], css["padding-bottom"];
	paddingLeft = self:PercentageToNumber(paddingLeft, parentWidth);
	paddingRight = self:PercentageToNumber(paddingRight, parentWidth);
	paddingTop = self:PercentageToNumber(paddingTop, parentHeight);
	paddingBottom = self:PercentageToNumber(paddingBottom, parentHeight);
	style.paddingLeft, style.paddingTop, style.paddingRight, style.paddingBottom = paddingLeft or 0, paddingTop or 0, paddingRight or 0, paddingBottom or 0;
	
	-- 数字化宽高
	local width = self:GetElement():GetAttrValue("width") or css.width;      -- 支持百分比, px
	local height = self:GetElement():GetAttrValue("height") or css.height;   -- 支持百分比, px
	if (self:IsBlockElement() and not width) then width = parentWidth end    -- 块元素默认为父元素宽
	width = self:PercentageToNumber(width, parentWidth);
	height = self:PercentageToNumber(height, parentHeight);
	style.width, style.height = width, height;
	self:SetWidthHeight(width, height);

	-- 数字化位置
	local left, top, right, bottom = css.left, css.top, css.right, css.bottom;
	left = self:PercentageToNumber(left, parentWidth);
	right = self:PercentageToNumber(right, parentWidth);
	top = self:PercentageToNumber(top, parentHeight);
	bottom = self:PercentageToNumber(bottom, parentHeight);
	style.left, style.top, style.right,style. bottom = left, top, right, bottom;

	-- 数字化 z-index 序
	style.zIndex = tonumber(string.match(css["z-index"] or "0", "[%+%-]?%d+")) or 0;

	-- 默认使用文档流
	self:SetUseSpace(true);
	self:SetPos(parentElementLayout:GetAvailablePos());
	self:SetAvailablePos(0, 0);
	self:SetRealWidthHeight(0, 0);

	echo({self:GetElement():GetName(), width or "nil", height or "nil", "init layout", "nid", self.nid, "parent nid", parentElementLayout.nid, "parent width height:", parentWidth, parentHeight, style});

end

-- 生效位置
function ElementLayout:ApplyStyle()
	self:ApplyPositionStyle();
	self:ApplyAlignStyle();
	self:ApplyFloatStyle();
end

-- 应用CSS的定位样式
function ElementLayout:ApplyPositionStyle()
	local style = self:GetStyle();
	local width, height = self:GetWidthHeight();
	local WindowX, WindowY, WindowWidth, WindowHeight = self:GetWindowPosition();
	local ScreenX, ScreenY, ScreenWidth, ScreenHeight = self:GetScreenPosition();
	local float, position, left, top, right, bottom = style.float, style.position, style.left, style.top, style.right, style.bottom;
	-- 浮动与定位不共存
	if (float or not position) then return end
	-- 相对定位
	if (position == "relative") then return self:OffsetPos(left or 0, top or 0) end
	-- 不使用文档流
	self:SetUseSpace(false);
	-- 计算定位
	local relElementLayout = self:GetParentElementLayout();
	if (position == "absolute") then
		-- 绝对定位 取已定位的父元素
		while (relElementLayout and relElementLayout:GetParentElementLayout()) do
			local relStyle = relElementLayout:GetStyle();
			if (relStyle.position and (relStyle.position == "relative" or relStyle.position == "absolute" or relStyle.position == "fixed" or relStyle.position == "screen")) then break end
			relElementLayout = relElementLayout:GetParentElementLayout();
		end
	elseif (position == "fixed") then
		-- 固定定位 取根元素
		while (relElementLayout and relElementLayout:GetParentElementLayout()) do
			relElementLayout = relElementLayout:GetParentElementLayout();
		end
	end
	local relWidth, relHeight = relElementLayout:GetWidthHeight();
	if (position == "screen") then relWidth, relHeight = ScreenWidth, ScreenHeight end
	relWidth, relHeight = relWidth or 0, relHeight or 0;
	if (right and width and not left) then left = relWidth - right - width end
	if (bottom and height and not top) then top = relHeight - bottom - height end
	if (not width) then width = relWidth - (left or 0) - (right or 0) end 
	if (not height) then height = relHeight - (top or 0) - (bottom or 0) end 
	left, top = left or 0, top or 0;
	if (position == "screen") then
		self:SetPos(left - WindowX, top - WindowY);
	else
		self:SetPos(left, top);
	end
	self:SetWidthHeight(math.max(width, 0), math.max(height, 0));
end

-- 应用排列属性
function ElementLayout:ApplyAlignStyle()
	local style = self:GetStyle();
	local parentElementLayout = self:GetParentElementLayout();
	local parentWidth, parentHeight = parentElementLayout:GetWidthHeight();
	local width, height = self:GetWidthHeight();
	local align = self:GetElement():GetAttrValue("align") or style.align;
	local valign = self:GetElement():GetAttrValue("valign") or style.valign;
	local x, y = 0, 0;

	if (parentWidth and width and align) then
		-- align at center. 
		if(align == "center") then 
			x = (parentWidth - width) / 2;
		elseif(align == "right") then
			x = (parentWidth - width);
		else 
			x = 0;
		end	
	end

	if (parentHeight and height and valign) then
		if(valign == "center") then
			y = (parentHeight - height) / 2;
		elseif(valign == "bottom") then
			y = (parentHeight - height);
		else
			y = 0;
		end	
	end

	self:SetPos(x, y);
end

-- 应用浮动样式
function ElementLayout:ApplyFloatStyle()
	local style = self:GetStyle();
	local parentElementLayout = self:GetParentElementLayout();
	local parentWidth, parentHeight = parentElementLayout:GetWidthHeight();
	local width, height = self:GetWidthHeight();
	local float = style.float;
	local left, top = self:GetPos();
	if (float == "right" and parentWidth and width) then
		-- 不使用文档流
		self:SetUseSpace(false);
		self:SetPos(parentWidth - width - (style.marginRight or 0), top);
	end
end

-- 应用元素使用空间
function ElementLayout:UpdateParentElementLayout()
	if (not self:IsValid() or not self:IsUseSpace()) then return end
	local style = self:GetStyle();
	local parentElementLayout = self:GetParentElementLayout();
	local marginLeft, marginTop, marginRight, marginBottom = style.marginLeft, style.marginTop, style.marginRight, style.marginBottom;
	local parentWidth, parentHeight = parentElementLayout:GetWidthHeight();
	local availableX, availableY = parentElementLayout:GetAvailablePos();
	local realWidth, realHeight = parentElementLayout:GetRealWidthHeight();
	local width, height = self:GetWidthHeight();
	local left, top = self:GetPos();
	local isBlockElement = self:IsBlockElement();
	echo({self:GetElement():GetName(), left, top, width, height, "parent layout nid: " .. tostring(parentElementLayout.nid), availableX, availableY, realWidth, realHeight});
	-- 添加元素到父布局
	if (not isBlockElement) then
		-- 内联元素
		if (parentWidth and parentWidth < (availableX + width + marginLeft + marginRight)) then
			-- 新起一行
			availableX = width + marginLeft + marginRight;
			availableY = realHeight;
			left = marginLeft;
			top = realHeight + marginTop;
		else 
			isNewLine = false;
			availableX = availableX + width + marginLeft + marginRight;
			availableY = availableY; -- 可用点的Y坐标不变
			left = availableX - width - marginRight;
			top = availableY + marginTop;
		end
		realWidth = if_else(realWidth > availableX, realWidth, availableX);
		local newHeight = availableY + height + marginTop + marginBottom;
		realHeight = if_else(newHeight > realHeight, newHeight, realHeight)
	else 
		-- 块元素 新起一行
		availableX = 0;                                                   -- 可用位置X坐标置0
		availableY = realHeight + height + marginTop + marginBottom;      -- 取最大Y坐标
		local newWidth = width + marginLeft + marginRight;
		realWidth = if_else(newWidth > realWidth, newWidth, realWidth);
		realHeight = availableY;
		left = marginLeft;
		top = realHeight - height - marginBottom;
	end
	echo({self:GetElement():GetName(), left, top, width, height, "parent layout nid: " .. tostring(parentElementLayout.nid), availableX, availableY, realWidth, realHeight});
	parentElementLayout:SetAvailablePos(availableX, availableY);    -- 更新父元素的可用位置
	parentElementLayout:SetRealWidthHeight(realWidth, realHeight);  -- 更新父元素的真实大小
	self:SetPos(left, top);  -- 更新自己再父元素中相对坐标
end

-- 元素布局更新前
function ElementLayout:OnBeforeUpdateElementLayout()
end

-- 子元素布局更新前
function ElementLayout:OnBeforeUpdateChildElementLayout()
end

-- 元素布局更新
function ElementLayout:OnUpdateElementLayout()
	local realWidth, realHeight = self:GetRealWidthHeight();
	local width, height = self:GetWidthHeight();
	
	-- 元素布局更新必须确保宽高存在
	self:SetWidthHeight(width or realHeight or 0, height or realHeight or 0);

	-- 调整位置信息
	self:ApplyStyle();

	-- 更新父布局 将自己加入父布局
	self:UpdateParentElementLayout();
end

-- 子元素布局更新后, 真实宽高必定存在
function ElementLayout:OnAfterUpdateChildElementLayout()
	local realWidth, realHeight = self:GetRealWidthHeight();
	local width, height = self:GetWidthHeight();
	local style = self:GetStyle();
	local paddingLeft, paddingTop, paddingRight, paddingBottom = style.paddingLeft, style.paddingTop, style.paddingRight, style.paddingBottom;
	
	width = width or (realWidth + paddingLeft + paddingRight);
	height = height or (realHeight + paddingTop + paddingBottom);

	self:SetWidthHeight(width, height);
end

-- 元素布局更新后
function ElementLayout:OnAfterUpdateElementLayout()
	local left, top = self:GetPos();
	local width, height = self:GetWidthHeight();
	self:GetElement():SetGeometry(left, top, width, height);
end

-- 更新元素布局
local function UpdateElementLayout(element, parentElementLayout)
	if (not parentElementLayout) then return end

    -- 获取当前元素布局
    local elementLayout = ElementLayout:new():Init(element, parentElementLayout, parentElementLayout:GetWindow());
	echo(string.format("-----------------[tag:%s, nid: %s] begin layout----------------", element:GetName(), elementLayout.nid));
    
    -- 布局无效 直接退出
    if (not elementLayout:IsValid() or not element) then return elementLayout end

	-- 元素布局更新前回调
	local isUpdatedElementLayout = false;
	if (type(element.OnBeforeUpdateElementLayout) == "function") then
        isUpdatedElementLayout = element:OnBeforeUpdateElementLayout(elementLayout, parentElementLayout);
    else
        isUpdatedElementLayout = elementLayout:OnBeforeUpdateElementLayout();
	end

	-- 元素布局已更新则直接返回
	if (isUpdatedElementLayout) then return elementLayout end
	
	-- 子元素布局更新前回调
	local isUpdatedChildElementLayout = false;
    if (type(element.OnBeforeUpdateChildElementLayout) == "function") then
        isUpdatedChildElementLayout = element:OnBeforeUpdateChildElementLayout(elementLayout, parentElementLayout);
    else
        isUpdatedChildElementLayout = elementLayout:OnBeforeUpdateChildElementLayout();
    end
    
	-- 执行子元素布局  子元素布局未更新则进行更新
	if (not isUpdatedChildElementLayout) then
		for childElement in element:ChildrenElementIterator() do
			UpdateElementLayout(childElement, elementLayout);
		end
	end
	
	-- 执行子元素布局后回调
    if (type(element.OnAfterUpdateChildElementLayout) == "function") then
        element:OnAfterUpdateChildElementLayout(elementLayout, parentElementLayout);
    else
        elementLayout:OnAfterUpdateChildElementLayout();
	end
	
    -- 执行元素布局更新
    if (type(element.OnUpdateElementLayout) == "function") then
        element:OnUpdateElementLayout(elementLayout, parentElementLayout);
    else
        elementLayout:OnUpdateElementLayout();
    end

	-- 元素布局更新后回调
	if (type(element.OnAfterUpdateElementLayout) == "function") then
        element:OnAfterUpdateElementLayout(elementLayout, parentElementLayout);
    else
        elementLayout:OnAfterUpdateElementLayout();
	end

	echo(string.format("-----------------[tag:%s, nid:%s] end layout----------------", element:GetName(), elementLayout.nid));

    return elementLayout;
end

-- 更新元素布局
function ElementLayout:UpdateElementLayout(elment, parentElementLayout)
	return UpdateElementLayout(elment, parentElementLayout or self);
end