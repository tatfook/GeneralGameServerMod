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

local LayoutDebug = GGS.Debug.GetModuleDebug("LayoutDebug").Enable(); --Enable  Disable

-- 属性定义
Layout:Property("Element");                                        -- 元素
Layout:Property("BorderBox", false, "IsBorderBox");                -- 区域盒子
Layout:Property("LayoutFinish", false, "IsLayoutFinish");          -- 是否布局完成
Layout:Property("FixedSize", false, "IsFixedSize");                -- 是否是固定宽高
Layout:Property("FixedWidth", false, "IsFixedWidth");              -- 是否是固定宽
Layout:Property("FixedHeight", false, "IsFixedHeight");            -- 是否是固定高
Layout:Property("UseSpace", true, "IsUseSpace");                   -- 是否使用空间
local nid = 0;

-- 重置布局
function Layout:Reset()
	-- 相对于父元素的位置
	self.top, self.right, self.bottom, self.left = 0, 0, 0, 0;
	-- 元素宽高 
	self.x, self.y, self.width, self.height = 0, 0, nil, nil;
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
	-- 窗口坐标
	-- self.windowX, self.windowY = 0, 0;

	-- 是否固定内容大小
	self:SetFixedSize(false);
	self:SetLayoutFinish(false);
	self:SetUseSpace(true);
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
	return self:GetWindow():GetWindowPosition();
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
-- 获取根布局
function Layout:GetRootLayout()
    return self:GetWindow() and self:GetWindow():GetLayout();
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
	local isRealContentWidthHeightChange = self.realContentWidth ~= width or self.realContentHeight ~= height;
    self.realContentWidth, self.realContentHeight = width, height;
	-- 真实内容发生改变
	if (isRealContentWidthHeightChange) then self:GetElement():OnRealContentSizeChange() end
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
	self.x, self.y = x or 0, y or 0;
	self:GetElement():SetPosition(self.x, self.y);
end
-- 获取位置坐标
function Layout:GetPos()
	return self.x or 0, self.y or 0; 
end
-- 获取内容位置
function Layout:GetContentPos()
	return self.x + self.borderLeft + self.paddingLeft, self.y + self.borderTop + self.paddingTop;
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
	return (not style.display or style.display == "block") and not style.float;
end
-- 是定位元素
function Layout:IsPosition()
	local style = self:GetStyle();
	return style.position == "absoulte" or style.position == "fixed" or style.position == "screen";
end
-- 元素是否布局 false 不布局
function Layout:IsLayout()
	local element = self:GetElement();
    local display = self:GetStyle().display;
    local width, height = self:GetWidthHeight();
    if (not element:IsVisible() or width == 0 or height == 0 or display == "none") then return false end 
    return true;
end
-- 是否溢出
function Layout:IsOverflow()
	return self:IsOverflowX() or self:IsOverflowY();
end
-- 是否溢出
function Layout:IsOverflowX()
	local style = self:GetStyle();
	return style["overflow-x"] ~= "none" and self:IsFixedWidth() and self.realContentWidth and self.realContentWidth > self.contentWidth;
end
-- 是否溢出
function Layout:IsOverflowY()
	local style = self:GetStyle();
	return style["overflow-y"] ~= "none" and self:IsFixedHeight() and self.realContentHeight and self.realContentHeight > self.contentHeight;
end

-- 处理布局准备工作, 单位数字化
function Layout:PrepareLayout()
    -- 先重置布局
    self:Reset();

	-- 获取父元素布局
    local parentLayout = self:GetParentLayout();
	
	-- 窗口元素 直接设置宽高
	if (not parentLayout and self:GetElement():IsWindow()) then
		local x, y, w, h = self:GetWindowPosition();
		self:SetPos(x or 0, y or 0);
		self:SetWidthHeight(w or 0, h or 0);
		self:SetFixedSize(true);
		return ;
	end
	
	-- 获取父元素宽高
	local parentWidth, parentHeight = nil, nil;
	if (parentLayout) then parentWidth, parentHeight = parentLayout:GetWidthHeight() end
	
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
	local marginTop, marginRight, marginBottom, marginLeft = style["margin-top"], style["margin-right"], style["margin-bottom"], style["margin-left"];
	marginRight = self:PercentageToNumber(marginRight, parentWidth) or 0;
	marginTop = self:PercentageToNumber(marginTop, parentWidth) or 0;
	marginBottom = self:PercentageToNumber(marginBottom, parentWidth) or 0;
	marginLeft = self:PercentageToNumber(marginLeft, parentWidth) or 0;
    self:SetMargin(marginTop, marginRight, marginBottom, marginLeft);
    
    -- 数字化边框
	local borderTop, borderRight, borderBottom, borderLeft = style["border-top-width"], style["border-right-width"], style["border-bottom-width"], style["border-left-width"];
	borderRight = self:PercentageToNumber(borderRight, parentWidth) or 0;
	borderTop = self:PercentageToNumber(borderTop, parentWidth) or 0;
    borderBottom = self:PercentageToNumber(borderBottom, parentWidth) or 0;
	borderLeft = self:PercentageToNumber(borderLeft, parentWidth) or 0;
    self:SetBorder(borderTop, borderRight, borderBottom, borderLeft);

	-- 数字化填充
	local paddingTop, paddingRight, paddingBottom, paddingLeft = style["padding-top"], style["padding-right"], style["padding-bottom"], style["padding-left"];
	paddingRight = self:PercentageToNumber(paddingRight, parentWidth) or 0;
	paddingTop = self:PercentageToNumber(paddingTop, parentWidth) or 0;
    paddingBottom = self:PercentageToNumber(paddingBottom, parentWidth) or 0;
	paddingLeft = self:PercentageToNumber(paddingLeft, parentWidth) or 0;
    self:SetPadding(paddingTop, paddingRight, paddingBottom, paddingLeft);
    
    -- 设置盒子类型
    if (style["box-sizing"] == "border-box") then
        self:SetBorderBox(true);
    else  -- content-box
        self:SetBorderBox(false);
    end

	-- 数字化宽高
	local width, height = style.width, style.height;                                                     -- 支持百分比, px
	if (self:IsBlock() and not self:IsPosition() and not width and parentLayout) then                    -- 块元素默认为父元素宽
		width = parentLayout:GetContentWidthHeight();
	end             
	width = self:PercentageToNumber(width, parentWidth);
    height = self:PercentageToNumber(height, parentHeight);
	if (style["box-sizing"] == "content-box" and style.width) then
		self:SetWidthHeight(width and (width + paddingLeft + paddingRight + borderLeft + borderRight), height and (height + paddingTop + paddingBottom + borderTop + borderBottom));
	else
		self:SetWidthHeight(width, height);
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

    -- LayoutDebug(
    --     "PrepareLayout:" .. self:GetElement():GetName(), 
    --     string.format("Element nid = %s, width = %s, height = %s", nid, width, height),
    --     parentLayout and string.format("ParentElement nid = %s, width = %s, height = %s", parentLayout.nid, parentWidth, parentHeight)
    -- );
end

-- 更新布局
function Layout:Update()
	local width, height = self:GetWidthHeight();
    local paddingTop, paddingRight, paddingBottom, paddingLeft = self:GetPadding();
    local borderTop, borderRight, borderBottom, borderLeft = self:GetBorder();

	-- 应用定位方式获取宽高
	self:ApplyPositionStyle();
	
	-- 更新真实内容大小 由所有子元素决定
	self:UpdateRealContentWidthHeight();
	local realContentWidth, realContentHeight = self:GetRealContentWidthHeight();

	width = width or (realContentWidth + paddingLeft + paddingRight + borderLeft + borderRight) or 0;
	height = height or (realContentHeight + paddingTop + paddingBottom + borderTop + borderBottom) or 0;

    LayoutDebug.FormatIf(self:GetElement():GetAttrValue("id") == "debug", "Layout Update Name = %s, width = %s, height = %s, IsFixedSize = %s, realContentWidth = %s, realContentHeight = %s", self:GetName(), width, height, self:IsFixedSize(), realContentWidth, realContentHeight);

	-- 确定元素大小
	self:SetWidthHeight(width, height);
	
	-- 设置布局完成
	self:SetLayoutFinish(true);
	
	-- 子元素更新完成, 当父元素存在,非固定宽高时, 需要更新父布局使其有正确的宽高 
	local parentLayout = self:GetParentLayout();
	-- 父布局存在且在布局中则直接跳出
	if (parentLayout and not parentLayout:IsLayoutFinish()) then return end
	
	-- 父布局存在且不为固定宽高则需更新父布局重新计算宽高 
	if (parentLayout and not parentLayout:IsFixedSize()) then return parentLayout:Update() end

	-- 父布局存在且为固定宽高则直接更新父布局的真实宽高即可
	if (parentLayout and parentLayout:IsFixedSize()) then parentLayout:UpdateRealContentWidthHeight() end
end

-- 更新内容宽高
function Layout:UpdateRealContentWidthHeight()
	local availableX, availableY, rightAvailableX, rightAvailableY, realContentWidth, realContentHeight = 0, 0, 0, 0, 0, 0;
	local width, height = self:GetWidthHeight();
	local element = self:GetElement();
	local isFalseWidth = false;

	if (not width) then
		width = 1000000; -- 虚拟出假宽度
		isFalseWidth = true;
	end

	-- 渲染序
	for child in element:ChildElementIterator(true) do
		local childLayout, childStyle = child:GetLayout(), child:GetStyle();
		local childLeft, childTop = 0, 0;
		local childMarginTop, childMarginRight, childMarginBottom, childMarginLeft = childLayout:GetMargin();
		local childSpaceWidth, childSpaceHeight = childLayout:GetSpaceWidthHeight();
		local childWidth, childHeight = childLayout:GetWidthHeight();
		local isRightFloat = childStyle.float == "right";
		if (childLayout:IsLayout() and childLayout:IsUseSpace()) then
			LayoutDebug.If(
				element:GetAttrValue("id") == "debug",
				string.format("[%s] Layout Add ChildLayout Before ", self:GetName()),
				string.format("Layout availableX = %s, availableY = %s, realContentWidth = %s, realContentHeight = %s, width = %s, height = %s", availableX, availableY, realContentWidth, realContentHeight, width, height),
				-- string.format("child margin: %s, %s, %s, %s", childMarginTop, childMarginRight, childMarginBottom, childMarginLeft), childStyle,
				string.format("[%s] childLeft = %s, childTop = %s, childSpaceWidth = %s, childSpaceHeight = %s, childWidth = %s, childHeight = %s", childLayout:GetName(), childLeft, childTop, childSpaceWidth, childSpaceHeight, childWidth, childHeight)
			);
			if (not childLayout:IsBlock()) then
				-- 内联元素
				if ((width - availableX - rightAvailableX) < childSpaceWidth) then
					-- 新起一行
					if (isRightFloat) then
						childLeft, childTop = (width - childSpaceWidth + childMarginLeft), realContentHeight + childMarginTop;
						availableX, availableY = 0, realContentHeight;
						rightAvailableX, rightAvailableY = childSpaceWidth, realContentHeight;
					else
						childLeft, childTop = childMarginLeft, realContentHeight + childMarginTop;
						availableX, availableY = childSpaceWidth, realContentHeight;
						rightAvailableX, rightAvailableY = 0, realContentHeight;
					end
				else 
					-- 同行追加
					if (isRightFloat) then
						childLeft, childTop = (width - rightAvailableX - childSpaceWidth + childMarginLeft), rightAvailableY + childMarginTop;
						availableX, availableY = availableX, availableY;
						rightAvailableX, rightAvailableY = rightAvailableX + childSpaceWidth, rightAvailableY;
					else
						childLeft, childTop = availableX + childMarginLeft, availableY + childMarginTop;
						availableX, availableY = availableX + childSpaceWidth, availableY;
						rightAvailableX, rightAvailableY = rightAvailableX, rightAvailableY;
					end
				end
				realContentWidth = if_else(realContentWidth > (availableX + rightAvailableX), realContentWidth, availableX + rightAvailableX);
				local newHeight = availableY + childSpaceHeight;
				realContentHeight = if_else(newHeight > realContentHeight, newHeight, realContentHeight)
			else 
				-- 块元素 新起一行
				childLeft, childTop = childMarginLeft, realContentHeight + childMarginTop;
				availableX, availableY = 0, realContentHeight + childSpaceHeight;    -- 可用位置X坐标置0 取最大Y坐标
				rightAvailableX, rightAvailableY = availableX, availableY;
				realContentWidth = if_else(childSpaceWidth > realContentWidth, childSpaceWidth, realContentWidth);
				realContentHeight = availableY;
			end
			childLayout:SetPos(childLeft, childTop);
			LayoutDebug.If(
				element:GetAttrValue("id") == "debug",
				string.format("[%s] Layout Add ChildLayout After ", self:GetName()),
				string.format("Layout availableX = %s, availableY = %s, realContentWidth = %s, realContentHeight = %s, width = %s, height = %s", availableX, availableY, realContentWidth, realContentHeight, width, height),
				string.format("[%s] childLeft = %s, childTop = %s, childSpaceWidth = %s, childSpaceHeight = %s", childLayout:GetName(), childLeft, childTop, childSpaceWidth, childSpaceHeight)
			);
		end
	end
	local paddingTop, paddingRight, paddingBottom, paddingLeft = self:GetPadding();
    local borderTop, borderRight, borderBottom, borderLeft = self:GetBorder();
	-- 假宽度右浮动元素需要调整
	for child in element:ChildElementIterator(true) do
		local childLayout, childStyle = child:GetLayout(), child:GetStyle(); 
		local left, top = childLayout:GetPos();
		if (childStyle.float == "right") then
			if (isFalseWidth) then left = left - width + realContentWidth end
			left = left - paddingRight - borderRight;
		else
			left = left + paddingLeft + borderLeft
		end
		top = top + paddingTop + borderTop;
		childLayout:SetPos(left, top);
		LayoutDebug.If(
			element:GetAttrValue("id") == "debug",
			string.format("[%s] Adjust Pos Left = %s, Top = %s ", child:GetName(), left, top)
		);
	end

	-- 设置内容宽高
	self:SetRealContentWidthHeight(realContentWidth, realContentHeight);
end

-- 应用CSS的定位样式
function Layout:ApplyPositionStyle()
	local style = self:GetStyle();
	local width, height = self:GetWidthHeight();
	local WindowX, WindowY, WindowWidth, WindowHeight = self:GetWindowPosition();
	local ScreenX, ScreenY, ScreenWidth, ScreenHeight = self:GetScreenPosition();
	local top, right, bottom, left = self:GetPosition()
	local float, position  = style.float, style.position;
	-- 浮动与定位不共存
	if (float or not position or position == "static") then return end
	-- 相对定位
	if (position == "relative") then return end  -- self:OffsetPos(left or 0, top or 0)
	-- 不使用文档流
	self:SetUseSpace(false);
	-- 计算定位
	local relLayout = self:GetParentLayout();
	
	if (position == "absolute") then
		-- 绝对定位 取已定位的父元素
		-- while (relLayout and relLayout:GetParentLayout()) do
		-- 	local relStyle = relLayout:GetStyle();
		-- 	if (relStyle.position and (relStyle.position == "relative" or relStyle.position == "absolute" or relStyle.position == "fixed" or relStyle.position == "screen")) then break end
		-- 	relLayout = relLayout:GetParentLayout();
		-- end
	elseif (position == "fixed") then
		-- 固定定位 取根元素
		relLayout = self:GetRootLayout();
	end

	local relWidth, relHeight = nil, nil;
	if (relLayout) then relWidth, relHeight = relLayout:GetWidthHeight() end
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
	LayoutDebug.FormatIf(self:GetElement():GetAttrValue("id") == "debug", "ApplyPositionStyle, left = %s, top = %s, right = %s, bottom = %s, width = %s, height = %s, relWidth = %s, relHeight = %s", left, top, right, bottom, width, height, relWidth, relHeight);
	self:SetWidthHeight(math.max(width, 0), math.max(height, 0));
end

