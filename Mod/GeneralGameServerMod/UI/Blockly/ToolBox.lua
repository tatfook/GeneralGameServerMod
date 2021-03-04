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
local Block = NPL.load("./Block.lua", IsDevEnv);
local LuaBlocks = NPL.load("./Blocks/Lua.lua", IsDevEnv);
local DataBlocks = NPL.load("./Blocks/Data.lua", IsDevEnv);
local VarBlocks = NPL.load("./Blocks/Var.lua", IsDevEnv);
local ControlBlocks = NPL.load("./Blocks/Control.lua", IsDevEnv);
local EventBlocks = NPL.load("./Blocks/Event.lua", IsDevEnv);
local LogBlocks = NPL.load("./Blocks/Log.lua", IsDevEnv);
local HelperBlocks = NPL.load("./Blocks/Helper.lua", IsDevEnv);
local ToolBox = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local categoryFont = "System;18;norm";
local AllBlocks = {};
ToolBox:Property("Blockly");
ToolBox:Property("CurrentCategoryName");


local function AddToAllBlocks(blocks)
    for _, block in ipairs(blocks) do
        table.insert(AllBlocks, #AllBlocks + 1, block);
    end
end

AddToAllBlocks(DataBlocks);
AddToAllBlocks(VarBlocks);
AddToAllBlocks(ControlBlocks);
AddToAllBlocks(EventBlocks);
AddToAllBlocks(LogBlocks);
AddToAllBlocks(HelperBlocks);

function ToolBox:ctor()
    self.leftUnitCount, self.topUnitCount = 0, 0;
    self.widthUnitCount, self.heightUnitCount = 0, 0;
    self.blocks = {};
    self.blockMap = {};
    self.categoryMap = {};
    self.categoryList = {}
    self.categoryTotalHeight = 0;
end

function ToolBox:Init(blockly)
    self:SetBlockly(blockly);
    return self;
end

function ToolBox:GetCategoryList()
    return self.categoryList;
end

function ToolBox:SetCategoryList(categorylist)
    self.categoryList = categorylist;
    self.blocks, self.blockMap, self.categoryMap = {}, {}, {};

    local offsetX, offsetY = 25, 0;
    for _, category in ipairs(categorylist) do
        self.categoryMap[category.name] = category;
        local blocktypes = category.blocktypes;
        category.offsetY = offsetY;
        for _, blocktype in ipairs(blocktypes) do
            local block = self:GetBlockly():GetBlockInstanceByType(blocktype);
            if (block) then
                block.isToolBoxBlock = true;
                offsetY = offsetY + 5; -- 间隙

                local widthUnitCount, heightUnitCount = block:UpdateWidthHeightUnitCount();
                block:SetLeftTopUnitCount(offsetX, offsetY);
                block:UpdateLeftTopUnitCount();
                self.blockMap[blocktype] = {leftUnitCount = offsetX, topUnitCount = offsetY, widthUnitCount = widthUnitCount, heightUnitCount = heightUnitCount};
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
    painter:SetPen("#ffffff");
    painter:DrawLine(categoryWidth, 0, categoryWidth, height);

    local categories = self:GetCategoryList();
    local radius = Const.ToolBoxCategoryWidth / 5;
    for i, category in ipairs(categories) do
        local offsetY = (i - 1) * categoryHeight;
        if (category.name == self:GetCurrentCategoryName()) then
            -- painter:SetPen("#e0e0e0");
            painter:SetPen("#f8f8f8");
            painter:DrawRect(0, offsetY, categoryWidth, categoryHeight);
        end
        painter:SetPen(category.color);
        painter:DrawCircle(categoryWidth / 2, -(offsetY + radius + categoryHeight / 7), 0, radius, "z", true);
        painter:SetFont(categoryFont);
        painter:SetPen("#808080");
        painter:DrawText(categoryWidth / 4 + 2, offsetY + radius * 2 + categoryHeight / 6 + 4, category.text or category.name);
    end
end

function ToolBox:Render(painter)
    self:GetBlockly():EnableDefaultUnitSize();

    local _, _, width, height = self:GetBlockly():GetContentGeometry();
    width = Const.ToolBoxWidth;

    self:RenderCategory(painter);

    painter:SetPen("#ffffff");
    painter:DrawLine(width, 0, width, height);
   
    painter:Save();
    painter:SetClipRegion(0, 0, width, height);

    for _, block in ipairs(self.blocks) do
        local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
        local widthUnitCount, heightUnitCount = block:GetWidthHeightUnitCount();
        if (not ((topUnitCount + heightUnitCount) < 0 or topUnitCount > self.heightUnitCount)) then
            block:Render(painter);
            painter:Flush();
        end
    end

    painter:Restore();

    self:GetBlockly():EnableCurrentUnitSize();
end

function ToolBox:GetMouseUI(x, y)
    if (x > Const.ToolBoxWidth) then return nil end

    self:GetBlockly():EnableDefaultUnitSize();

    for _, block in ipairs(self.blocks) do
        ui = block:GetMouseUI(x, y, event);
        if (ui) then 
            self:GetBlockly():EnableCurrentUnitSize();
            return ui:GetBlock();
        end
    end

    self:GetBlockly():EnableCurrentUnitSize();
    return self;
end

function ToolBox:OnMouseDown(event)
    local blockly = self:GetBlockly();
    local x, y = blockly._super.GetRelPoint(blockly, event.x, event.y);         -- 防止减去偏移量
    if (x > self.categoryTotalWidth or y > self.categoryTotalHeight) then return end
    local categoryHeight = Const.ToolBoxCategoryHeight;
    local index = math.ceil(y / categoryHeight);
    local category = self.categoryList[index];
    if (not category or category.name == self:GetCurrentCategoryName()) then return end
    self:SetCurrentCategoryName(category.name);

    self:GetBlockly():EnableDefaultUnitSize();
    for _, block in ipairs(self.blocks) do
        local blocktype = block:GetType();
        local blockpos = self.blockMap[blocktype];
        block:SetLeftTopUnitCount(blockpos.leftUnitCount, blockpos.topUnitCount - category.offsetY);
        block:UpdateLeftTopUnitCount();
    end
    self:GetBlockly():EnableCurrentUnitSize();
end

function ToolBox:OnMouseMove(event)
end

function ToolBox:OnMouseUp(event)
end

function ToolBox:OnMouseWheel(event)
    local delta = event:GetDelta();             -- 1 向上滚动  -1 向下滚动
    local dist, offset = 5, 5;                  -- 滚动距离为5 * Const.DefaultUnitSize  

    if (#self.blocks == 0) then return end

    if (delta < 0) then
        local block = self.blocks[#self.blocks];
        if ((block.topUnitCount + block.heightUnitCount) <= (self.heightUnitCount - offset)) then return end  
    else
        local block = self.blocks[1];
        if (block.topUnitCount >= offset) then return end
    end

    self:GetBlockly():EnableDefaultUnitSize();
    local categoryName = nil;
    for _, block in ipairs(self.blocks) do
        local left, top = block:GetLeftTopUnitCount();
        top = top + dist * delta;
        if (not categoryName and top > 0) then categoryName = block:GetOption().category end 
        block:SetLeftTopUnitCount(left, top);
        block:UpdateLeftTopUnitCount();
    end
    self:SetCurrentCategoryName(categoryName);
    self:GetBlockly():EnableCurrentUnitSize();
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
    self.widthUnitCount, self.heightUnitCount = math.ceil(Const.ToolBoxWidth / Const.DefaultUnitSize), math.ceil(height / Const.DefaultUnitSize);
end

function ToolBox:IsContainPoint(x, y)
    return x < Const.ToolBoxWidth;
end
