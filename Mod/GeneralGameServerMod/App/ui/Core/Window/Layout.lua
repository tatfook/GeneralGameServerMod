--[[
Title: Style
Author(s): wxa
Date: 2020/6/30
Desc: 布局类
use the lib:
-------------------------------------------------------
local Layout = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Layout.lua");
-------------------------------------------------------
]]

local Layout = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local LayoutDebug = GGS.Debug.GetModuleDebug("LayoutDebug").Enable(); --.Disable()

-- 属性定义
Layout:Property("Element");                                        -- 元素
Layout:Property("BorderBox", false, "IsBorderBox");                -- 区域盒子
Layout:Property("LayoutFinish", false, "IsLayoutFinish");          -- 是否布局完成
Layout:Property("FixedSize", false, "IsFixedSize");                -- 是否是固定大小
Layout:Property("FixedWidth", false, "IsFixedWidth");  			   -- 是否是固定宽
Layout:Property("FixedHeight", false, "IsFixedHeight");  		   -- 是否是固定高
local nid = 0;

-- 重置布局
function Layout:Reset()
	-- 当前可用位置
	self.availableX, self.availableY, self.rightAvailableX, self.rightAvailableY = 0, 0, 0, 0;
	-- 相对于父元素的位置
	self.top, self.right, self.bottom, self.left = 0, 0, 0, 0;
	-- 元素宽高 
	self.width, self.height = nil, nil;
	-- 真实内容宽高
	self.realContentWidth, self.realContentHeight = nil, nil;
	-- 内容宽高
	self.contentWidth, self.contentHeight = 0, 0;  
	-- 空间大小
	self.spaceWidth, self.spaceHeight = 0, 0;
	-- 边框
	self.borderTop, self.borderRight, self.borderBottom, self.borderLeft = 0, 0, 0, 0;
	-- 填充
	self.paddingTop, self.paddingRight, self.paddingBottom, self.paddingLeft = 0, 0, 0, 0;
	-- 边距
	self.marginTop, self.marginRight, self.marginBottom, self.marginLeft = 0, 0, 0, 0;

	-- 是否固定内容大小
	self:SetFixedSize(false);
	self:SetFixedWidth(false);
	self:SetFixedHeight(false);
	self:SetLayoutFinish(false);
end

-- 初始化
function Layout:Init(element)
	self:Reset();
	
	nid = nid + 1;
	self.nid = nid;

    self:SetElement(element);

	return self;
end
-- 获取元素名
function Layout:GetName()
    return self:GetElement():GetName();
end
-- 获取窗口
function Layout:GetWindow()
    return self:GetElement():GetWindow();
end
-- 获取窗口位置 x, y, w, h    (w, h 为宽高, 非坐标)
function Layout:GetWindowPosition()
    local wnd = self:GetWindow():GetNativeWindow();
    if (not wnd) then return end;
	return wnd:GetAbsPosition();
end
-- 获取屏幕(应用程序窗口)位置 x, y, w, h    (w, h 为宽高, 非坐标)
function Layout:GetScreenPosition()
	return ParaUI.GetUIObject("root"):GetAbsPosition();
end
-- 获取页面元素的样式
function Layout:GetStyle()
	return self:GetElement():GetStyle();
end
-- 获取父布局
function Layout:GetParentLayout()
    local parent = self:GetElement():GetParentElement();
    return parent and parent:GetLayout();
end
-- 设置空间大小
function Layout:SetSpaceWidthHeight(width, height)
	self.spaceWidth, self.spaceHeight = width, height;
end
-- 获取空间大小 margin border padding content
function Layout:GetSpaceWidthHeight(width, height)
	return self.spaceWidth, self.spaceHeight;
end
-- 设置区域宽高 非坐标 包含 padding border content
function Layout:SetWidthHeight(width, height)
	self.width, self.height = width, height;
	self:GetElement():SetSize(self.width or 0, self.height or 0);
	
	local marginTop, marginRight, marginBottom, marginLeft = self:GetMargin();
	local paddingTop, paddingRight, paddingBottom, paddingLeft = self:GetPadding();
	local borderTop, borderRight, borderBottom, borderLeft = self:GetBorder();
	self.spaceWidth = width and (width + marginLeft + marginRight);
	self.spaceHeight = height and (height + marginTop + marginBottom);
	self.contentWidth = width and (width - borderLeft - borderRight - paddingLeft - paddingRight);
	self.contentHeight = height and (height - borderTop - borderBottom - paddingTop - paddingBottom);
end
-- 获取区域宽高 非坐标 包含 padding border style.width    style.width 可能是内容宽也可能是区域宽,  布局里的宽一定是区域宽
function Layout:GetWidthHeight()
	return self.width, self.height;
end
-- 设置内容宽高
function Layout:SetContentWidthHeight(width, height)
    self.contentWidth, self.contentHeight = width, height;
end
-- 获取内容宽高 
function Layout:GetContentWidthHeight()
	return self.contentWidth, self.contentHeight;
end
-- 设置真实宽高
function Layout:SetRealContentWidthHeight(width, height)
    self.realContentWidth, self.realContentHeight = width, height;
end
-- 获取真实宽高 
function Layout:GetRealContentWidthHeight()
	return self.realContentWidth, self.realContentHeight;
end
-- 设置最小宽高 
function Layout:SetMinWidthHeight(width, height)
	self.minWidth, self.minHeight = width, height;
end
-- 获取最小宽高
function Layout:GetMinWidthHeight()
	return self.minWidth, self.minHeight;
end
-- 设置最大宽高 
function Layout:SetMaxWidthHeight(width, height)
	self.maxWidth, self.maxHeight = width, height;
end
-- 获取最大宽高
function Layout:GetMaxWidthHeight()
	return self.maxWidth, self.maxHeight;
end
-- 设置填充
function Layout:SetBorder(top, right, bottom, left)
    self.borderTop, self.borderRight, self.borderBottom, self.borderLeft = top, right, bottom, left;
end
-- 获取填充 top right bottom left 
function Layout:GetBorder()
	return self.borderTop, self.borderRight, self.borderBottom, self.borderLeft;
end
-- 设置填充
function Layout:SetPadding(top, right, bottom, left)
    self.paddingTop, self.paddingRight, self.paddingBottom, self.paddingLeft = top, right, bottom, left;
end
-- 获取填充 top right bottom left 
function Layout:GetPadding()
	return self.paddingTop, self.paddingRight, self.paddingBottom, self.paddingLeft;
end
-- 设置边距
function Layout:SetMargin(top, right, bottom, left)
    self.marginTop, self.marginRight, self.marginBottom, self.marginLeft = top, right, bottom, left;
end
-- 获取填充 top right bottom left 
function Layout:GetMargin()
	return self.marginTop, self.marginRight, self.marginBottom, self.marginLeft;
end
-- 设置位置
function Layout:SetPosition(top, right, bottom, left)
	self.top, self.right, self.bottom, self.left = top, right, bottom, left;
end
-- 获取位置
function Layout:GetPosition()
    return self.top, self.right, self.bottom, self.left;
end
-- 设置位置坐标
function Layout:SetPos(x, y)
	self.left, self.top = x or 0, y or 0;
	self:GetElement():SetPosition(self.left, self.top);
end
-- 获取位置坐标
function Layout:GetPos()
	return self.left or 0, self.top or 0; 
end
-- 获取左上点
function Layout:GetLeftTop()
    return self.left, self.top;
end
-- 获取右下点
function Layout:GetRightBottom()
    return self.right, self.bottom;
end
-- 偏移位置
function Layout:OffsetPos(dx, dy)
	self.left = self.left + (dx or 0);
	self.top = self.top + (dy or 0);
end
-- 设置可用位置
function Layout:SetAvailablePos(availableX, availableY)
	self.availableX, self.availableY = availableX, availableY;
end
-- 获取可用位置
function Layout:GetAvailablePos()
	return self.availableX, self.availableY;
end
-- 百分比转数字
function Layout:PercentageToNumber(percentage, size)
	if (type(percentage) == "number") then return percentage end;
	if (type(percentage) ~= "string") then return end
	local number = tonumber(string.match(percentage, "[%+%-]?%d+"));
	if (string.match(percentage, "%%$")) then
		number = size and math.floor(size * number /100);
	end
	return number;
end
-- 块元素识别
function Layout:IsBlock()
	local style = self:GetStyle();
	return (not style.display or style.display == "block") and not style.float and not style.position;
end
-- 元素是否布局 false 不布局
function Layout:IsLayout()
    local display = self:GetStyle().display;
    local width, height = self:GetWidthHeight();
    if (width == 0 or height == 0 or display == "none") then return false end 
    return true;
end
-- 是否溢出
function Layout:IsOverflow()
	return self:IsOverflowX() or self:IsOverflowY();
end
-- 是否溢出
function Layout:IsOverflowX()
	return self.realContentWidth and self.realContentWidth > self.contentWidth;
end
-- 是否溢出
function Layout:IsOverflowY()
	return self.realContentHeight and self.realContentHeight > self.contentHeight;
end

-- 处理布局准备工作, 单位数字化
function Layout:PrepareLayout()
    -- 先重置布局
    self:Reset();

	-- 获取父元素布局
    local parentLayout = self:GetParentLayout();
	
	-- 窗口元素 直接设置宽高
	if (not parentLayout) then
        local x, y, w, h = self:GetWindowPosition();
		return self:SetWidthHeight(w or 0, h or 0);
	end
	
	-- 获取父元素宽高
    local parentWidth, parentHeight = parentLayout:GetWidthHeight();
    -- 父元素无宽高则不布局
    if (parentWidth == 0 or parentHeight == 0) then return self:SetWidthHeight(0, 0) end 

    -- 获取元素样式
    local style = self:GetStyle();
   -- 数字最大最小宽高
	local minWidth, minHeight, maxWidth, maxHeight = style["min-width"], style["min-height"], style["max-width"], style["max-height"];
	minWidth = self:PercentageToNumber(minWidth, parentWidth);
	maxWidth = self:PercentageToNumber(maxWidth, parentWidth);
	minHeight = self:PercentageToNumber(minHeight, parentHeight);
    maxHeight = self:PercentageToNumber(maxHeight, parentHeight);
    self:SetMinWidthHeight(minWidth, minHeight);
    self:SetMaxWidthHeight(maxWidth, maxHeight);

    -- 数字化边距
	local marginLeft, marginTop, marginRight, marginBottom = style["margin-top"], style["margin-right"], style["margin-bottom"], style["margin-left"];
	marginLeft = self:PercentageToNumber(marginLeft, parentWidth) or 0;
	marginRight = self:PercentageToNumber(marginRight, parentWidth) or 0;
	marginTop = self:PercentageToNumber(marginTop, parentWidth) or 0;
	marginBottom = self:PercentageToNumber(marginBottom, parentWidth) or 0;
    self:SetMargin(marginTop, marginRight, marginBottom, marginLeft);
    
    -- 数字化边框
	local borderLeft, borderTop, borderRight, borderBottom = style["border-left-width"], style["border-top-width"], style["border-right-width"], style["border-bottom-width"];
	borderLeft = self:PercentageToNumber(borderLeft, parentWidth) or 0;
	borderRight = self:PercentageToNumber(borderRight, parentWidth) or 0;
	borderTop = self:PercentageToNumber(borderTop, parentWidth) or 0;
    borderBottom = self:PercentageToNumber(borderBottom, parentWidth) or 0;
    self:SetBorder(borderTop, borderRight, borderBottom, borderLeft);

	-- 数字化填充
	local paddingLeft, paddingTop, paddingRight, paddingBottom = style["padding-left"], style["padding-top"], style["padding-right"], style["padding-bottom"];
	paddingLeft = self:PercentageToNumber(paddingLeft, parentWidth) or 0;
	paddingRight = self:PercentageToNumber(paddingRight, parentWidth) or 0;
	paddingTop = self:PercentageToNumber(paddingTop, parentWidth) or 0;
    paddingBottom = self:PercentageToNumber(paddingBottom, parentWidth) or 0;
    self:SetPadding(paddingTop, paddingRight, paddingBottom, paddingLeft);
    
    -- 设置盒子类型
    if (style["box-sizing"] == "border-box") then
        self:SetBorderBox(true);
    else  -- content-box
        self:SetBorderBox(false);
    end

	-- 数字化宽高
	local width, height = style.width, style.height;                           -- 支持百分比, px
	if (self:IsBlock() and not width) then width = parentWidth end             -- 块元素默认为父元素宽
	width = self:PercentageToNumber(width, parentWidth);
    height = self:PercentageToNumber(height, parentHeight);
    if (self:IsBorderBox()) then
		self:SetWidthHeight(width, height);
    else
		self:SetWidthHeight(width and (width + paddingLeft + paddingRight + borderLeft + borderRight), height and (height + paddingTop + paddingBottom + borderTop + borderBottom));
	end
	if (width and height) then self:SetFixedSize(true) end
	if (width) then self:SetFixedWidth(true) end
	if (height) then self:SetFixedHeight(true) end

	-- 数字化位置
	local left, top, right, bottom = style.left, style.top, style.right, style.bottom;
	left = self:PercentageToNumber(left, parentWidth);
	right = self:PercentageToNumber(right, parentWidth);
	top = self:PercentageToNumber(top, parentHeight);
	bottom = self:PercentageToNumber(bottom, parentHeight);
	self:SetPosition(top, right, bottom, left);

    LayoutDebug(
        "PrepareLayout:" .. self:GetElement():GetName(), 
        string.format("Element nid = %s, width = %s, height = %s", nid, width, height),
        parentLayout and string.format("ParentElement nid = %s, width = %s, height = %s", parentLayout.nid, parentWidth, parentHeight)
    );
end

-- 更新布局
function Layout:Update()
	local width, height = self:GetWidthHeight();
	local realContentWidth, realContentHeight = self:GetRealContentWidthHeight();
	local marginTop, marginRight, marginBottom, marginLeft = self:GetMargin();
    local paddingTop, paddingRight, paddingBottom, paddingLeft = self:GetPadding();
    local borderTop, borderRight, borderBottom, borderLeft = self:GetBorder();

	if (not self:IsFixedSize() or not realContentWidth or not realContentHeight) then
		self:UpdateRealContentWidthHeight();
		realContentWidth, realContentHeight = self:GetRealContentWidthHeight();
		width = width or (realContentWidth + paddingLeft + paddingRight + borderLeft + borderRight) or 0;
		height = height or (realContentHeight + paddingTop + paddingBottom + borderTop + borderBottom) or 0;
	end

    LayoutDebug.Format("Layout Update Name = %s, width = %s, height = %s, IsFixedSize = %s, realContentWidth = %s, realContentHeight = %s", self:GetName(), width, height, self:IsFixedSize(), realContentWidth, realContentHeight);

	-- 确定元素大小
	self:SetWidthHeight(width, height);

    -- 	self:ApplyPositionStyle();
    -- 	self:ApplyAlignStyle();
    -- 	self:ApplyFloatStyle();

	-- 父元素布局更新
	local parentLayout = self:GetParentLayout();
    if (parentLayout and parentLayout:IsLayoutFinish()) then
        parentLayout:Update();
    end
end

-- 更新内容宽高
function Layout:UpdateRealContentWidthHeight()
	local oldRealContentWidth, oldRealContentHeight = self:GetRealContentWidthHeight();
	local availableX, availableY, realContentWidth, realContentHeight = 0, 0, 0, 0;
	local width, height = self:GetWidthHeight();
	local element = self:GetElement();

	-- 渲染序
	for child in element:ChildElementIterator(true) do
		local childLayout = child:GetLayout();
		local childLeft, childTop = 0, 0;
		local childMarginTop, childMarginRight, childMarginBottom, childMarginLeft = childLayout:GetMargin();
		local childSpaceWidth, childSpaceHeight = childLayout:GetSpaceWidthHeight();
		LayoutDebug(
			string.format("[%s] Layout Add ChildLayout Before ", self:GetName()),
			string.format("Layout availableX = %s, availableY = %s, realContentWidth = %s, realContentHeight = %s, width = %s, height = %s", availableX, availableY, realContentWidth, realContentHeight, width, height),
			string.format("[%s] childLeft = %s, childTop = %s, childSpaceWidth = %s, childSpaceHeight = %s", childLayout:GetName(), childLeft, childTop, childSpaceWidth, childSpaceHeight)
		);
		if (childLayout:IsLayout()) then
			if (not childLayout:IsBlock()) then
				-- 内联元素
				if (width and width < (availableX + childSpaceWidth)) then
					-- 新起一行
					childLeft = childMarginLeft;
					childTop = realContentHeight + childMarginTop;
					availableX = childSpaceWidth;
					availableY = realHeight;
				else 
					-- 同行追加
					childLeft = availableX + childMarginLeft;
					childTop = availableY + childMarginTop;
					availableX = availableX + childSpaceWidth;
					availableY = availableY; -- 可用点的Y坐标不变
				end
				realContentWidth = if_else(realContentWidth > availableX, realContentWidth, availableX);
				local newHeight = availableY + childSpaceHeight;
				realContentHeight = if_else(newHeight > realContentHeight, newHeight, realContentHeight)
			else 
				-- 块元素 新起一行
				childLeft = childMarginLeft;
				childTop = realContentHeight + childMarginTop;
				availableX = 0;                                                      -- 可用位置X坐标置0
				availableY = realContentHeight + childSpaceHeight;                       -- 取最大Y坐标
				realContentWidth = if_else(childSpaceWidth > realContentWidth, childSpaceWidth, realContentWidth);
				realContentHeight = availableY;
			end
		end
		childLayout:SetPos(childLeft, childTop);
		LayoutDebug(
			string.format("[%s] Layout Add ChildLayout After ", self:GetName()),
			string.format("Layout availableX = %s, availableY = %s, realContentWidth = %s, realContentHeight = %s, width = %s, height = %s", availableX, availableY, realContentWidth, realContentHeight, width, height),
			string.format("[%s] childLeft = %s, childTop = %s, childSpaceWidth = %s, childSpaceHeight = %s", childLayout:GetName(), childLeft, childTop, childSpaceWidth, childSpaceHeight)
		);
	end

	-- 设置内容宽高
	self:SetRealContentWidthHeight(realContentWidth, realContentHeight);
	-- 真实内容发生改变
	if (oldRealContentWidth ~= realContentWidth or oldRealContentHeight ~= realContentHeight) then
		self:GetElement():OnRealContentSizeChange();
	end
end

-- 添加子布局
-- function Layout:AddChildLayout(childLayout)
-- 	if (not childLayout:IsLayout()) then return end
-- 	local childStyle = childLayout:GetStyle();
--     -- 定位元素忽略
--     if (childStyle.position == "absolute" or childStyle.position == "fixed" or childStyle.position == "screen") then return end

-- 	local width, height = self:GetWidthHeight();
-- 	local availableX, availableY = self:GetAvailablePos();
--     local realWidth, realHeight = self:GetRealWidthHeight();
-- 	local childMarginTop, childMarginRight, childMarginBottom, childMarginLeft = childLayout:GetMargin();
-- 	local childWidth, childHeight = childLayout:GetWidthHeight();
--     local childLeft, childTop = childLayout:GetPos();
--     LayoutDebug(
--         string.format("[%s] Layout Add ChildLayout Before ", self:GetName()),
--         string.format("Layout availableX = %s, availableY = %s, realWidth = %s, realHeight = %s, width = %s, height = %s", availableX, availableY, realWidth, realHeight, width, height),
--         string.format("[%s] childLeft = %s, childTop = %s, childWidth = %s, childHeight = %s", childLayout:GetName(), childLeft, childTop, childWidth, childHeight)
--     );
-- 	-- 添加元素到父布局
-- 	if (not childLayout:IsBlock()) then
-- 		-- 内联元素
-- 		if (width < (availableX + childWidth + childMarginLeft + childMarginRight)) then
-- 			-- 新起一行
-- 			availableX = childWidth + childMarginLeft + childMarginRight;
-- 			availableY = realHeight;
-- 			childLeft = childMarginLeft;
-- 			childTop = availableY + childMarginTop;
-- 		else 
-- 			availableX = availableX + childWidth + childMarginLeft + childMarginRight;
-- 			availableY = availableY; -- 可用点的Y坐标不变
-- 			childLeft = availableX - childWidth - childMarginRight;
-- 			childTop = availableY + childMarginTop;
-- 		end
-- 		realWidth = if_else(realWidth > availableX, realWidth, availableX);
-- 		local newHeight = availableY + childHeight + childMarginTop + childMarginBottom;
-- 		realHeight = if_else(newHeight > realHeight, newHeight, realHeight)
-- 	else 
-- 		-- 块元素 新起一行
-- 		availableX = 0;                                                   -- 可用位置X坐标置0
-- 		availableY = realHeight + childHeight + childMarginTop + childMarginBottom;      -- 取最大Y坐标
-- 		local newWidth = childWidth + childMarginLeft + childMarginRight;
-- 		realWidth = if_else(newWidth > realWidth, newWidth, realWidth);
-- 		realHeight = availableY;
-- 		childLeft = childMarginLeft;
-- 		childTop = realHeight - childHeight - childMarginBottom;
--     end
--     LayoutDebug(
--         string.format("[%s] Layout Add ChildLayout After ", self:GetName()),
--         string.format("Layout availableX = %s, availableY = %s, realWidth = %s, realHeight = %s, width = %s, height = %s", availableX, availableY, realWidth, realHeight, width, height),
--         string.format("[%s] childLeft = %s, childTop = %s, childWidth = %s, childHeight = %s", childLayout:GetName(), childLeft, childTop, childWidth, childHeight)
--     );
-- 	self:SetAvailablePos(availableX, availableY);    -- 更新父元素的可用位置
-- 	self:SetRealWidthHeight(realWidth, realHeight);  -- 更新父元素的真实大小
-- 	childLayout:SetPos(childLeft, childTop);        -- 更新自己再父元素中相对坐标
-- end

-- 应用CSS的定位样式
-- function ElementLayout:ApplyPositionStyle()
-- 	local style = self:GetStyle();
-- 	local width, height = self:GetWidthHeight();
-- 	local WindowX, WindowY, WindowWidth, WindowHeight = self:GetWindowPosition();
-- 	local ScreenX, ScreenY, ScreenWidth, ScreenHeight = self:GetScreenPosition();
-- 	local float, position, left, top, right, bottom = style.float, style.position, style.left, style.top, style.right, style.bottom;
-- 	-- 浮动与定位不共存
-- 	if (float or not position) then return end
-- 	-- 相对定位
-- 	if (position == "relative") then return self:OffsetPos(left or 0, top or 0) end
-- 	-- 不使用文档流
-- 	self:SetUseSpace(false);
-- 	-- 计算定位
-- 	local relElementLayout = self:GetParentElementLayout();
-- 	if (position == "absolute") then
-- 		-- 绝对定位 取已定位的父元素
-- 		while (relElementLayout and relElementLayout:GetParentElementLayout()) do
-- 			local relStyle = relElementLayout:GetStyle();
-- 			if (relStyle.position and (relStyle.position == "relative" or relStyle.position == "absolute" or relStyle.position == "fixed" or relStyle.position == "screen")) then break end
-- 			relElementLayout = relElementLayout:GetParentElementLayout();
-- 		end
-- 	elseif (position == "fixed") then
-- 		-- 固定定位 取根元素
-- 		while (relElementLayout and relElementLayout:GetParentElementLayout()) do
-- 			relElementLayout = relElementLayout:GetParentElementLayout();
-- 		end
-- 	end
-- 	local relWidth, relHeight = relElementLayout:GetWidthHeight();
-- 	if (position == "screen") then relWidth, relHeight = ScreenWidth, ScreenHeight end
-- 	relWidth, relHeight = relWidth or 0, relHeight or 0;
-- 	if (right and width and not left) then left = relWidth - right - width end
-- 	if (bottom and height and not top) then top = relHeight - bottom - height end
-- 	if (not width) then width = relWidth - (left or 0) - (right or 0) end 
-- 	if (not height) then height = relHeight - (top or 0) - (bottom or 0) end 
-- 	left, top = left or 0, top or 0;
-- 	if (position == "screen") then
-- 		self:SetPos(left - WindowX, top - WindowY);
-- 	else
-- 		self:SetPos(left, top);
-- 	end
-- 	self:SetWidthHeight(math.max(width, 0), math.max(height, 0));
-- end

-- -- 应用排列属性
-- function ElementLayout:ApplyAlignStyle()
-- 	local style = self:GetStyle();
-- 	local parentElementLayout = self:GetParentElementLayout();
-- 	local parentWidth, parentHeight = parentElementLayout:GetWidthHeight();
-- 	local width, height = self:GetWidthHeight();
-- 	local align = self:GetElement():GetAttrValue("align") or style.align;
-- 	local valign = self:GetElement():GetAttrValue("valign") or style.valign;
-- 	local x, y = 0, 0;

-- 	if (parentWidth and width and align) then
-- 		-- align at center. 
-- 		if(align == "center") then 
-- 			x = (parentWidth - width) / 2;
-- 		elseif(align == "right") then
-- 			x = (parentWidth - width);
-- 		else 
-- 			x = 0;
-- 		end	
-- 	end

-- 	if (parentHeight and height and valign) then
-- 		if(valign == "center") then
-- 			y = (parentHeight - height) / 2;
-- 		elseif(valign == "bottom") then
-- 			y = (parentHeight - height);
-- 		else
-- 			y = 0;
-- 		end	
-- 	end

-- 	self:SetPos(x, y);
-- end

-- -- 应用浮动样式
-- function ElementLayout:ApplyFloatStyle()
-- 	local style = self:GetStyle();
-- 	local parentElementLayout = self:GetParentElementLayout();
-- 	local parentWidth, parentHeight = parentElementLayout:GetWidthHeight();
-- 	local width, height = self:GetWidthHeight();
-- 	local float = style.float;
-- 	local left, top = self:GetPos();
-- 	if (float == "right" and parentWidth and width) then
-- 		-- 不使用文档流
-- 		self:SetUseSpace(false);
-- 		self:SetPos(parentWidth - width - (style.marginRight or 0), top);
-- 	end
-- end

-- -- 元素布局更新后
-- function ElementLayout:OnAfterUpdateElementLayout()
-- 	local left, top = self:GetPos();
-- 	local width, height = self:GetWidthHeight();
-- 	self:GetElement():SetGeometry(left, top, width, height);
-- end

-- -- 更新元素布局
-- local function UpdateElementLayout(element, parentElementLayout)
-- 	if (not parentElementLayout) then return end

--     -- 获取当前元素布局
--     local elementLayout = ElementLayout:new():Init(element, parentElementLayout, parentElementLayout:GetWindow());
-- 	echo(string.format("-----------------[tag:%s, nid: %s] begin layout----------------", element:GetName(), elementLayout.nid));
    
--     -- 布局无效 直接退出
--     if (not elementLayout:IsValid() or not element) then return elementLayout end

-- 	-- 元素布局更新前回调
-- 	local isUpdatedElementLayout = false;
-- 	if (type(element.OnBeforeUpdateElementLayout) == "function") then
--         isUpdatedElementLayout = element:OnBeforeUpdateElementLayout(elementLayout, parentElementLayout);
--     else
--         isUpdatedElementLayout = elementLayout:OnBeforeUpdateElementLayout();
-- 	end

-- 	-- 元素布局已更新则直接返回
-- 	if (isUpdatedElementLayout) then return elementLayout end
	
-- 	-- 子元素布局更新前回调
-- 	local isUpdatedChildElementLayout = false;
--     if (type(element.OnBeforeUpdateChildElementLayout) == "function") then
--         isUpdatedChildElementLayout = element:OnBeforeUpdateChildElementLayout(elementLayout, parentElementLayout);
--     else
--         isUpdatedChildElementLayout = elementLayout:OnBeforeUpdateChildElementLayout();
--     end
    
-- 	-- 执行子元素布局  子元素布局未更新则进行更新
-- 	if (not isUpdatedChildElementLayout) then
-- 		for childElement in element:ChildrenElementIterator() do
-- 			UpdateElementLayout(childElement, elementLayout);
-- 		end
-- 	end
	
-- 	-- 执行子元素布局后回调
--     if (type(element.OnAfterUpdateChildElementLayout) == "function") then
--         element:OnAfterUpdateChildElementLayout(elementLayout, parentElementLayout);
--     else
--         elementLayout:OnAfterUpdateChildElementLayout();
-- 	end
	
--     -- 执行元素布局更新
--     if (type(element.OnUpdateElementLayout) == "function") then
--         element:OnUpdateElementLayout(elementLayout, parentElementLayout);
--     else
--         elementLayout:OnUpdateElementLayout();
--     end

-- 	-- 元素布局更新后回调
-- 	if (type(element.OnAfterUpdateElementLayout) == "function") then
--         element:OnAfterUpdateElementLayout(elementLayout, parentElementLayout);
--     else
--         elementLayout:OnAfterUpdateElementLayout();
-- 	end

-- 	echo(string.format("-----------------[tag:%s, nid:%s] end layout----------------", element:GetName(), elementLayout.nid));

--     return elementLayout;
-- end

-- -- 更新元素布局
-- function ElementLayout:UpdateElementLayout(elment, parentElementLayout)
-- 	return UpdateElementLayout(elment, parentElementLayout or self);
-- end