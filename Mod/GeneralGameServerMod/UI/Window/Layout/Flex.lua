--[[
Title: Flex
Author(s): wxa
Date: 2020/6/30
Desc: 弹性布局类
use the lib:
-------------------------------------------------------
local Flex = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Layout/Flex.lua");
-------------------------------------------------------
]]

local Flex = NPL.export();
local FlexDebug = GGS.Debug.GetModuleDebug("FlexDebug").Disable(); --Enable  Disable

local function LayoutElementFilter(el)
	local layout = el:GetLayout();
	return layout:IsLayout() and layout:IsUseSpace();
end 

local function UpdateRow(layout, style)
    local left, top, width, height = layout:GetContentGeometry();
	local lines, line = {}, {layouts = {}, width = 0, height = 0, flexGrow = 0};
	table.insert(lines, line);
	for child in layout:GetElement():ChildElementIterator(true, LayoutElementFilter) do
		local childLayout, childStyle = child:GetLayout(), child:GetStyle();
		local childSpaceWidth, childSpaceHeight = childLayout:GetSpaceWidthHeight();

		if (width and (line.width + childSpaceWidth) > width) then
			line = {layouts = {}, width = 0, height = 0, flexGrow = 0};
			table.insert(lines, line);
		end

		line.flexGrow = line.flexGrow + (childStyle["flex-grow"] or 0);
		line.width = line.width + childSpaceWidth;
		line.height = math.max(line.height, childSpaceHeight);
		table.insert(line.layouts, childLayout);
	end

	-- local totalHeight = 0;
    local offsetLeft, offsetTop, HGap, VGap = left, top, 0, 0;
    local contentWidth, contentHeight = 0, 0;
    local function UpdateChildLayoutPos(layouts)
        for _, childLayout in ipairs(line.layouts) do
            local spaceWidth = childLayout:GetSpaceWidthHeight();
			childLayout:SetPos(offsetLeft, offsetTop);
			-- FlexDebug.Format("child layout left = %s, top = %s", offsetLeft, offsetTop);
            offsetLeft = offsetLeft + spaceWidth + HGap;
        end
    end

    if (height) then
        local totalHeight = 0;
        for _, line in ipairs(lines) do totalHeight = totalHeight + line.height end
        local remainHeight = height - totalHeight;
        if (style["align-items"] == "center") then 
            offsetTop = remainHeight / 2; 
        elseif (style["align-items"] == "flex-end") then 
            offsetTop = remainHeight; 
        elseif (style["align-items"] == "space-between") then 
            local gapCount = #(line.layouts) - 1;
            if (gapCount > 0) then VGap = remainHeight / gapCount end
        elseif (style["align-items"] == "space-around") then 
            local gapCount = #(line.layouts) + 1;
            VGap = remainHeight / gapCount;
            offsetTop = VGap;
        end 
    end
	
	-- FlexDebug(lines);
	
	for _, line in ipairs(lines) do
		if (width) then
			local remainWidth = width - line.width;
			if (line.flexGrow > 0) then
				for _, childLayout in ipairs(line.layouts) do
					childLayout:SetPos(offsetLeft, offsetTop);
					local spaceWidth = childLayout:GetSpaceWidthHeight();
					local flexGrow = childLayout:GetStyle()["flex-grow"] or 0;
					if (childLayout:IsFixedWidth() or flexGrow == 0) then
						offsetLeft = offsetLeft + spaceWidth;
					else 
						local autoWidth= remainWidth * flexGrow / line.flexGrow;
						offsetLeft = offsetLeft + spaceWidth + autoWidth;
						local width, height = childLayout:GetWidthHeight();
						childLayout:SetWidthHeight(width + autoWidth, height); 
						-- 是否重新更新子布局
					end
				end
			else
                if (style["justify-content"] == "center") then 
                    offsetLeft = remainWidth / 2; 
                elseif (style["justify-content"] == "flex-end") then 
                    offsetLeft = remainWidth; 
				elseif (style["justify-content"] == "space-between") then 
					local gapCount = #(line.layouts) - 1;
					if (gapCount > 0) then HGap = remainWidth / gapCount end
                elseif (style["justify-content"] == "space-around") then 
					local gapCount = #(line.layouts) + 1;
					HGap = remainWidth / gapCount;
					offsetLeft = HGap;
				end 
				UpdateChildLayoutPos(line.layouts);
			end
		else 
			UpdateChildLayoutPos(line.layouts);
		end
        contentWidth = math.max(contentWidth, offsetLeft - HGap - left);
		offsetLeft, HGap = left, 0;
        offsetTop = offsetTop + line.height + VGap;
        contentHeight = math.max(contentHeight, offsetTop - VGap - top);
	end

	FlexDebug.Format("left = %s, top = %s, width = %s, height = %s, contentWidth = %s, contentHeight = %s", left, top, width, height, contentWidth, contentHeight);
    layout:SetRealContentWidthHeight(contentWidth, contentHeight);
end

local function UpdateCol(layout, style)
    local left, top, width, height = layout:GetContentGeometry();
	local lines, line = {}, {layouts = {}, width = 0, height = 0, flexGrow = 0};
	table.insert(lines, line);
	for child in layout:GetElement():ChildElementIterator(true, LayoutElementFilter) do
		local childLayout, childStyle = child:GetLayout(), child:GetStyle();
		local childSpaceWidth, childSpaceHeight = childLayout:GetSpaceWidthHeight();

		if (height and (line.height + childSpaceHeight) > height) then
			line = {layouts = {}, width = 0, height = 0, flexGrow = 0};
			table.insert(lines, line);
		end

		line.flexGrow = line.flexGrow + (childStyle["flex-grow"] or 0);
		line.height = line.height + childSpaceHeight;
		line.width = math.max(line.width, childSpaceWidth);
		table.insert(line.layouts, childLayout);
	end

	-- local totalHeight = 0;
    local offsetLeft, offsetTop, HGap, VGap = left, top, 0, 0;
    local contentWidth, contentHeight = 0, 0;
    local function UpdateChildLayoutPos(layouts)
        for _, childLayout in ipairs(line.layouts) do
            local spaceWidth, spaceHeight = childLayout:GetSpaceWidthHeight();
            childLayout:SetPos(offsetLeft, offsetTop);
            offsetTop = offsetTop + spaceHeight + VGap;
        end
    end

    if (width) then
        local totalWidth = 0;
        for _, line in ipairs(lines) do totalWidth = totalWidth + line.width end
        local remainWidth = width - totalWidth;
        if (style["align-items"] == "center") then 
            offsetLeft = remainWidth / 2; 
        elseif (style["align-items"] == "flex-end") then 
            offsetLeft = remainWidth; 
        elseif (style["align-items"] == "space-between") then 
            local gapCount = #(line.layouts) - 1;
            if (gapCount > 0) then HGap = remainWidth / gapCount end
        elseif (style["align-items"] == "space-around") then 
            local gapCount = #(line.layouts) + 1;
            HGap = remainWidth / gapCount;
            offsetLeft = HGap;
        end 
    end
    
	for _, line in ipairs(lines) do
		if (height) then
			local remainHeight = height - line.height;
			if (line.flexGrow > 0) then
				for _, childLayout in ipairs(line.layouts) do
					childLayout:SetPos(offsetLeft, offsetTop);
					local spaceWidth, spaceHeight = childLayout:GetSpaceWidthHeight();
					local flexGrow = childLayout:GetStyle()["flex-grow"] or 0;
					if (childLayout:IsFixedHeight() or flexGrow == 0) then
						offsetTop = offsetTop + spaceHeight;
					else 
						local autoHeight= remainHeight * flexGrow / line.flexGrow;
						offsetTop = offsetTop + spaceHeight + autoHeight;
						local width, height = childLayout:GetWidthHeight();
						childLayout:SetWidthHeight(width, height + autoHeight); 
						-- 是否重新更新子布局
					end
				end
			else
                if (style["justify-content"] == "center") then 
                    offsetTop = remainHeight / 2; 
                elseif (style["justify-content"] == "flex-end") then 
                    offsetTop = remainHeight; 
				elseif (style["justify-content"] == "space-between") then 
					local gapCount = #(line.layouts) - 1;
					if (gapCount > 0) then VGap = remainHeight / gapCount end
                elseif (style["justify-content"] == "space-around") then 
					local gapCount = #(line.layouts) + 1;
					VGap = remainHeight / gapCount;
					offsetTop = VGap;
				end 
				UpdateChildLayoutPos(line.layouts);
			end
		else 
			UpdateChildLayoutPos(line.layouts);
        end
        contentHeight = math.max(contentHeight, offsetTop - VGap - top);
        offsetTop, VGap = top, 0;
        offsetLeft = offsetLeft + line.width + HGap;
        contentWidth = math.max(contentWidth, offsetLeft - HGap - left);
    end
    layout:SetRealContentWidthHeight(contentWidth, contentHeight);
end

local function Update(layout)
    local style = layout:GetStyle();
    if (style.display ~= "flex") then return end

	local flexDirection = style["flex-direction"] or "row";
    if (flexDirection == "row" or flexDirection == "row-reverse") then
        UpdateRow(layout, style);
    end

    if (flexDirection == "column" or flexDirection == "column-reverse") then
        UpdateCol(layout, style);
    end
end

function Flex.Update(layout)
    Update(layout);
end
