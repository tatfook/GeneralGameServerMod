--[[
Title: ToolBox
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local BlockInputField = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/BlockInputField.lua");
-------------------------------------------------------
]]

local Const = NPL.load("./Const.lua");
local Shape = NPL.load("./Shape.lua");
local ToolBox = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local categoryFont = "System;12;norm";
ToolBox:Property("ClassName", "ToolBox");
ToolBox:Property("Blockly");
ToolBox:Property("CurrentCategoryName");
ToolBox:Property("Scale", 1);

function ToolBox:ctor()
    self.leftUnitCount, self.topUnitCount = 0, 0;
    self.widthUnitCount, self.heightUnitCount = 0, 0;
    self.blocks = {};
    self.blockPosMap = {};
    self.categoryMap = {};
    self.categoryList = {}
    self.categoryTotalHeight = 0;
    self.MouseWheel = {};
    -- self:SetScale(0.75);
    self:SetScale(1);
end

function ToolBox:Init(blockly)
    self:SetBlockly(blockly);
    return self;
end

function ToolBox:GetUnitSize()
    return Const.UnitSize;
end

function ToolBox:GetCategoryList()
    return self.categoryList;
end

function ToolBox:SetCategoryList(categorylist)
    self.categoryList = categorylist;
    self.blocks, self.blockPosMap, self.categoryMap = {}, {}, {};

    local offsetX, offsetY = 25, 0;
    for _, category in ipairs(categorylist) do
        self.categoryMap[category.name] = category;
        local blocktypes = category.blocktypes;
        category.offsetY = offsetY;
        for _, blocktype in ipairs(blocktypes) do
            local block = self:GetBlockly():GetBlockInstanceByType(blocktype);
            if (block) then
                block:SetToolBoxBlock(true);
                offsetY = offsetY + 5; -- 间隙

                local widthUnitCount, heightUnitCount = block:UpdateWidthHeightUnitCount();
                block:SetLeftTopUnitCount(offsetX, offsetY);
                block:UpdateLeftTopUnitCount();
                self.blockPosMap[blocktype] = {leftUnitCount = offsetX, topUnitCount = offsetY, widthUnitCount = widthUnitCount, heightUnitCount = heightUnitCount, block = block};
                offsetY = offsetY + heightUnitCount;
                table.insert(self.blocks, block);
            end
        end
    end
    self:SetCurrentCategoryName(categorylist[1] and categorylist[1].name);
    self.categoryTotalHeight = #categorylist * Const.ToolBoxCategoryHeight;
    self.categoryTotalWidth = Const.ToolBoxCategoryWidth;
end

-- 绘制分类
function ToolBox:RenderCategory(painter)
    local _, _, _, height = self:GetBlockly():GetContentGeometry();
    local categoryWidth = Const.ToolBoxCategoryWidth;
    local categoryHeight = Const.ToolBoxCategoryHeight;

    -- 绘制背景
    painter:SetPen("#323536");
    painter:DrawRect(0, 0, categoryWidth, height);

    local categories = self:GetCategoryList();
    local circleSize = 26;
    local circleOffsetX, circleOffsetY = 17, 8;
    painter:SetFont(categoryFont);
    for i, category in ipairs(categories) do
        local offsetX = circleOffsetX;
        local offsetY = (i - 1) * categoryHeight + circleOffsetY;
        if (category.name == self:GetCurrentCategoryName()) then
            painter:SetPen("#585D5E");
            painter:DrawRect(0, offsetY - circleOffsetY, categoryWidth, categoryHeight);
        end
        painter:SetPen(category.color);
        painter:DrawRectTexture(offsetX, offsetY, circleSize, circleSize, "Texture/Aries/Creator/keepwork/ggs/blockly/yuan_26X26_32bits.png#0 0 26 26");
        if (category.name == self:GetCurrentCategoryName()) then
            painter:SetPen("#ffffff");
        else 
            painter:SetPen(category.color);
        end
        painter:DrawText(offsetX + 2, offsetY + circleSize + 4, category.text or category.name);
    end
end

function ToolBox:Render(painter)
    local _, _, width, height = self:GetBlockly():GetContentGeometry();
    width = Const.ToolBoxWidth;

    -- 绘制背景
    painter:SetBrush("#ffffff");
    painter:DrawRectTexture(0, 0, Const.ToolBoxWidth, height, "Texture/Aries/Creator/keepwork/ggs/blockly/toolbox_bj_32X32_32bits.png#0 0 32 32:10 10 10 10");

    -- 绘制分类
    self:RenderCategory(painter);

    local UnitSize = self:GetUnitSize();
    Shape:SetUnitSize(UnitSize);

    local scale = self:GetScale();
    local toolboxHeightUnitCount = math.floor(self.heightUnitCount / scale);
    painter:Save();
    painter:SetClipRegion(0, 0, width - 10, height);
    painter:Scale(scale, scale);
    for _, block in ipairs(self.blocks) do
        local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
        local widthUnitCount, heightUnitCount = block:GetWidthHeightUnitCount();
        if (not ((topUnitCount + heightUnitCount) < 0 or topUnitCount > toolboxHeightUnitCount)) then
            block:Render(painter);
        end
    end
    painter:Scale(1 / scale, 1 / scale);
    painter:Restore();
end

function ToolBox:GetMouseUI(x, y, event)
    local blockly = self:GetBlockly();
    local scale = self:GetScale();
    x, y = blockly._super.GetRelPoint(blockly, event.x, event.y);
    if (x > Const.ToolBoxWidth) then return nil end
    if (x <= Const.ToolBoxCategoryWidth) then return self end
    x, y = math.floor(x / scale + 0.5), math.floor(y / scale + 0.5);
    for _, block in ipairs(self.blocks) do
        ui = block:GetMouseUI(x, y, event);
        if (ui) then 
            return ui:GetTopBlock();
        end
    end
    return self;
end

function ToolBox:OnMouseDownCategory(event)
    local blockly = self:GetBlockly();
    local x, y = blockly._super.GetRelPoint(blockly, event.x, event.y);         -- 防止减去偏移量
    if (x > self.categoryTotalWidth or y > self.categoryTotalHeight) then return end
    local categoryHeight = Const.ToolBoxCategoryHeight;
    local index = math.ceil(y / categoryHeight);
    local category = self.categoryList[index];
    if (not category or category.name == self:GetCurrentCategoryName()) then return end
    self:SetCurrentCategoryName(category.name);

    for _, block in ipairs(self.blocks) do
        local blocktype = block:GetType();
        local blockpos = self.blockPosMap[blocktype];
        block:SetLeftTopUnitCount(blockpos.leftUnitCount, blockpos.topUnitCount - category.offsetY);
        block:UpdateLeftTopUnitCount();
    end
end


function ToolBox:OnMouseDown(event)
    local blockly = self:GetBlockly();
    local x, y = blockly._super.GetRelPoint(blockly, event.x, event.y);         -- 防止减去偏移量
    if (x <= Const.ToolBoxCategoryWidth) then return self:OnMouseDownCategory(event) end

    if (self:GetBlockly():IsTouchMode()) then
        self.MouseWheel.mouseX, self.MouseWheel.mouseY = event:GetScreenXY();
        self.MouseWheel.isStartWheel = true;
    end
end

function ToolBox:OnMouseMove(event)
    if (self.MouseWheel.isStartWheel) then
        local x, y = event:GetScreenXY();
        if (y ~= self.MouseWheel.mouseY) then
            local mouse_wheel = y < self.MouseWheel.mouseY and 1 or -1;
            self.MouseWheel.mouseX, self.MouseWheel.mouseY = x, y;
            event.mouse_wheel = mouse_wheel;
            self:OnMouseWheel(event);
        end
    end
end

function ToolBox:OnMouseUp(event)
    if (self.MouseWheel.isStartWheel) then self.MouseWheel.isStartWheel = false end
end

function ToolBox:OnMouseWheel(event)
    local delta = event:GetDelta();             -- 1 向上滚动  -1 向下滚动
    local dist, offset = 8, 5;                  -- 滚动距离为5 * Const.DefaultUnitSize  

    if (#self.blocks == 0) then return end
    local scale = self:GetScale();
    local heightUnitCount = math.floor(self.heightUnitCount / scale);
    if (delta < 0) then
        local block = self.blocks[#self.blocks];
        if ((block.topUnitCount + block.heightUnitCount) <= (heightUnitCount - offset)) then return end  
    else
        local block = self.blocks[1];
        if (block.topUnitCount >= offset) then return end
    end

    local categoryName = nil;
    for _, block in ipairs(self.blocks) do
        local left, top = block:GetLeftTopUnitCount();
        top = top + dist * delta;
        if (not categoryName and top > 0) then categoryName = block:GetOption().category end 
        block:SetLeftTopUnitCount(left, top);
        block:UpdateLeftTopUnitCount();
    end
    self:SetCurrentCategoryName(categoryName);
end

function ToolBox:OnFocusOut()
end

function ToolBox:OnFocusIn()
end

function ToolBox:FocusIn()
end

function ToolBox:FocusOut()
end

function ToolBox:UpdateLayout(widthUnitCount, heightUnitCount)
    local _, _, width, height = self:GetBlockly():GetContentGeometry();
    self.widthUnitCount, self.heightUnitCount = math.ceil(Const.ToolBoxWidth / self:GetUnitSize()), math.ceil(height / self:GetUnitSize());
end

function ToolBox:IsContainPoint(x, y)
    return x < Const.ToolBoxWidth;
end

function ToolBox:SetBlockPos(block_type, block_top)
    local blockpos = self.blockPosMap[block_type];
    if (not blockpos) then return end
    local block = blockpos.block;
    local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
    block_top = block_top / self:GetUnitSize();
    if (topUnitCount == block_top) then return end
    offset = block_top - topUnitCount;

    for _, block in ipairs(self.blocks) do
        local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
        block:SetLeftTopUnitCount(leftUnitCount, topUnitCount + offset);
        block:UpdateLeftTopUnitCount();
    end 
end
