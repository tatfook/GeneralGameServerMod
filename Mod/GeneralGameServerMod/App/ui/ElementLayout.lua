--[[
Title: ElementLayout
Author(s): wxa
Date: 2020/8/14
Desc: 实现元素CSS属性的应用
------------------------------------------------------------
]]

local ElementLayout = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.createtable("System.Windows.mcml.ElementLayout"));

-- 属性定义
ElementLayout:Property("UseSpace", true, "IsUseSpace");  -- 是否占据文档流空间
ElementLayout:Property("Layout");        -- 元素布局
ElementLayout:Property("ParentLayout");  -- 父元素布局
ElementLayout:Property("Style");         -- 元素样式

local nid = 0;
-- 初始化
function ElementLayout:Init(element)
	self.element = element;
	-- 右侧可用位置
	self.rightAvailableX = 0;
	self.rightAvailableY = 0;
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
	-- 初始化样式
	self:SetStyle({});
	
	nid = nid + 1;
	self.nid = nid;
	
	return self;
end

-- 获取窗口
function ElementLayout:GetWindow()
	return self:GetElement():GetPageCtrl():GetWindow();
end
-- 获取窗口位置 x, y, w, h    (w, h 为宽高, 非坐标)
function ElementLayout:GetWindowPosition()
	return self:GetWindow():GetNativeWindow():GetAbsPosition();
end
-- 获取屏幕(应用程序窗口)位置 x, y, w, h    (w, h 为宽高, 非坐标)
function ElementLayout:GetScreenPosition()
	return ParaUI.GetUIObject("root"):GetAbsPosition();
end

-- 是否为根元素
-- function ElementLayout:IsRootElement()
-- 	local element = self:GetElement();
-- 	local parentElement = element and element:GetParent();
-- 	return if_else(parentElement == nil, true, false);
-- end

-- 获取页面元素
function ElementLayout:GetElement()
	return self.element;
end

-- 获取页面元素的CSS
function ElementLayout:GetElementStyle()
	return self:GetElement() and self:GetElement():GetStyle();
end

-- 获取父元素的元素布局
function ElementLayout:GetParentElementLayout()
	local element = self:GetElement();
	local parentElement = element and element:GetParent();
	if (parentElement) then return parentElement:GetElementLayout() end
	if (not self.parentElementLayout) then 
		self.parentElementLayout = ElementLayout:new():Init(nil);
	end
	local _, _, winWidth, winHeight = self:GetWindowPosition();
	self.parentElementLayout:SetWidthHeight(winWidth, winHeight);
	return self.parentElementLayout;
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
	echo({"----------------SetRealWidthHeight:", self.nid, width, height});
	self.realWidth, self.realHeight = width, height;
end
-- 获取真实宽高
function ElementLayout:GetRealWidthHeight()
	return self.realWidth, self.realHeight;
end
-- 设置可用位置
function ElementLayout:SetAvailablePos(availableX, availableY)
	echo({"----------------SetAvailablePos:", self.nid, availableX, availableY});
	self.availableX, self.availableY = availableX, availableY;
end
-- 获取可用位置
function ElementLayout:GetAvailablePos()
	return self.availableX, self.availableY;
end

-- 更新布局
function ElementLayout:UpdateLayout(parentLayout)
	-- 检测是否符合布局条件
	local css = self:GetElementStyle();
	if (not css or css.display == "none") then return echo("element style is nil") end
	local page = self:GetElement():GetPageCtrl();
	local window = page and page:GetWindow();
	local nativeWindow = window and window:GetNativeWindow();
	if (not nativeWindow) then return echo("native window is nil") end;

	self:SetParentLayout(parentLayout);
	self:SetLayout(parentLayout:clone());

	echo(string.format("-----------------[tag:%s, nid: %s] begin layout----------------", self:GetElement().name, self.nid));

	-- 初始化样式
	self:InitLayout();
	
	-- 应用子布局
	self:ApplyChildLayout();

	-- 调整位置信息
	self:ApplyStyle();

	-- 应用父布局
	self:ApplyParentLayout();

	-- 应用布局
	self:ApplyLayout();

	echo(string.format("-----------------[tag:%s, nid:%s] end layout----------------", self:GetElement().name, self.nid));
end

-- CSS 相关属性实现
--[[
元素宽高: 包含边框, 填充, 内容 width = border + margin + contentWidth
元素百分比: 取父元素最大大小的百分比 size = parentMaxSize * percentage
]]

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
	local css = self:GetElementStyle();
	local display = css and css.display;
	return not display or display == "block";
end

-- 处理布局准备工作, 单位数字化
function ElementLayout:InitLayout()
	-- 获取样式表
	local css = self:GetElementStyle();
	-- 获取父元素布局
	local parentElementLayout = self:GetParentElementLayout();

	-- 保存布局最大大小
	local parentWidth, parentHeight = parentElementLayout:GetWidthHeight();

	local style = self:GetStyle();
	for key, val in pairs(css) do
		if (type(key) == "string" and (type(val) == "string" or type(val) == "number")) then
			style[key] = val;
		end
	end

	-- 数字最大最小宽高
	local minWidth, minHeight, maxWidth, maxHeight = css["min-width"], css["min-height"], css["max-width"], css["max-height"];
	minWidth = self:PercentageToNumber(minWidth, parentWidth);
	maxWidth = self:PercentageToNumber(maxWidth, parentWidth);
	minHeight = self:PercentageToNumber(minHeight, parentHeight);
	maxHeight = self:PercentageToNumber(maxHeight, parentHeight);
	style.minWidth, style.minHeight, style.maxWidth, style.maxHeight = minWidth, minHeight, maxWidth, maxHeight;
	-- 数字化边距
	local marginLeft, marginTop, marginRight, marginBottom = css:margins();
	marginLeft = self:PercentageToNumber(marginLeft, parentWidth);
	marginRight = self:PercentageToNumber(marginRight, parentWidth);
	marginTop = self:PercentageToNumber(marginTop, parentHeight);
	marginBottom = self:PercentageToNumber(marginBottom, parentHeight);
	style.marginLeft, style.marginTop, style.marginRight, style.marginBottom = marginLeft or 0, marginTop or 0, marginRight or 0, marginBottom or 0;
	-- 数字化填充
	local paddingLeft, paddingTop, paddingRight, paddingBottom = css:paddings();
	paddingLeft = self:PercentageToNumber(paddingLeft, parentWidth);
	paddingRight = self:PercentageToNumber(paddingRight, parentWidth);
	paddingTop = self:PercentageToNumber(paddingTop, parentHeight);
	paddingBottom = self:PercentageToNumber(paddingBottom, parentHeight);
	style.paddingLeft, style.paddingTop, style.paddingRight, style.paddingBottom = paddingLeft or 0, paddingTop or 0, paddingRight or 0, paddingBottom or 0;
	
	-- 数字化宽高
	local width = self:GetElement():GetAttribute("width") or css.width;      -- 支持百分比, px
	local height = self:GetElement():GetAttribute("height") or css.height;   -- 支持百分比, px
	if (self:IsBlockElement() and not width) then width = parentWidth end  -- 块元素默认为父元素宽
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

	if (css.float and (css.float == "left" or css.float == "right")) then style.float = css.float end
	if (css.position and (css.position == "relative" or css.position == "absolute" or css.position == "fixed" or css.position == "static" or css.position == "screen")) then style.position = css.position end
	if (css.align and (css.align == "left" or css.align == "center" or css.align == "right")) then style.align = css.align end
	if (css.valign and (css.valign == "left" or css.valign == "center" or css.valign == "right")) then style.valign = css.valign end

	-- 默认使用文档流
	self:SetUseSpace(true);
	self:SetPos(0, 0);
	self:SetAvailablePos(0, 0);
	self:SetRealWidthHeight(0, 0);
	echo({"nid", self.nid, "parent nid", parentElementLayout.nid});
end

-- 更新子布局
function ElementLayout:ApplyChildLayout()
	local layout = self:GetLayout();
	local width, height = self:GetWidthHeight();
	layout:SetPos(0, 0);
	layout:ResetUsedSize();
	-- layout:SetSize(width or 0, height or 0);
	if(not self:GetElement():OnBeforeChildLayout(layout)) then
		self:GetElement():UpdateChildLayout(layout);
	end
	local usedWidth, usedHeight = layout:GetUsedSize();
	-- 子元素布局完成必须有宽高
	self:SetWidthHeight(width or usedWidth or 0, height or usedHeight or 0);
	self:SetRealWidthHeight(usedWidth or 0, usedHeight or 0);
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
	local parent = self:GetElement():GetParent();
	if (position == "absolute") then
		-- 绝对定位 取已定位的父元素
		while (parent and parent:GetParent()) do
			local parentStyle = parent:GetElementLayout():GetStyle();
			if (parentStyle.position and (parentStyle.position == "relative" or parentStyle.position == "absolute" or parentStyle.position == "fixed" or parentStyle.position == "screen")) then break end
			parent = parent:GetParent();
		end
	elseif (position == "fixed") then
		-- 固定定位 取根元素
		while (parent and parent:GetParent()) do
			parent = parent:GetParent();
		end
	end
	local relElementLayout = parent and parent:GetElementLayout() or self:GetParentElementLayout();
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
	local align = self:GetElement():GetAttribute("align") or style.align;
	local valign = self:GetElement():GetAttribute("valign") or style.valign;
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
function ElementLayout:ApplyParentLayout()
	if (not self:IsUseSpace()) then return end
	local style = self:GetStyle();
	local parentElementLayout = self:GetParentElementLayout();
	-- local paddingLeft, paddingTop, paddingRight, paddingBottom = style.paddingLeft, style.paddingTop, style.paddingRight, style.paddingBottom;
	local marginLeft, marginTop, marginRight, marginBottom = style.marginLeft, style.marginTop, style.marginRight, style.marginBottom;
	local parentWidth, parentHeight = parentElementLayout:GetWidthHeight();
	local availableX, availableY = parentElementLayout:GetAvailablePos();
	local realWidth, realHeight = parentElementLayout:GetRealWidthHeight();
	local width, height = self:GetWidthHeight();
	local left, top = self:GetPos();
	local isBlockElement = self:IsBlockElement();
	local parentLayout = self:GetParentLayout();
	local isNewLine = true;
	echo({left, top, width, height, "parent layout nid: " .. tostring(parentElementLayout.nid), availableX, availableY, realWidth, realHeight});
	-- 添加元素到父布局
	if (style.float or not isBlockElement) then
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
	echo({left, top, "parent layout nid: " .. tostring(parentElementLayout.nid), availableX, availableY, realWidth, realHeight});
	self:SetPos(left, top);  -- 更新自己再父元素中相对坐标
	parentElementLayout:SetAvailablePos(availableX, availableY);    -- 更新父元素的可用位置
	parentElementLayout:SetRealWidthHeight(realWidth, realHeight);  -- 更新父元素的真实大小

	-- 添加至父布局
	if (isNewLine) then parentLayout:NewLine() end
	parentLayout:AddObject(marginLeft + width + marginRight, marginTop + height + marginBottom);
	
	local attr = self:GetElement().attr or {};
	echo({attr.id or "nil", width, height, {parentLayout:GetUsedSize()}});
end

-- 应用布局
function ElementLayout:ApplyLayout()
	local left, top = self:GetPos();
	local width, height = self:GetWidthHeight();
	self:GetLayout():SetRealSize(self:GetRealWidthHeight());
	self:GetLayout():SetPos(left, top);
	self:GetLayout():SetSize(width, height);
	self:GetLayout():SetUsedSize(width, height);
	self:GetElement():OnAfterChildLayout(self:GetLayout(), left, top, left + width, top + height);
	echo({self:GetElement().name, left, top, left + width, top + height});
end
