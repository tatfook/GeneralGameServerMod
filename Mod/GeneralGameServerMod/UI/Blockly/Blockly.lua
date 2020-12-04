
--[[
Title: G
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Blockly = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Blockly.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");
local Element = NPL.load("../Window/Element.lua", IsDevEnv);
local LuaBlocks = NPL.load("./Blocks/Lua.lua", IsDevEnv);
local Const = NPL.load("./Const.lua", IsDevEnv);
local Shape = NPL.load("./Shape.lua", IsDevEnv);
local Block = NPL.load("./Block.lua", IsDevEnv);
local BlocklyEditor = NPL.load("./BlocklyEditor.lua", IsDevEnv);
local Blockly = commonlib.inherit(Element, NPL.export());

Blockly:Property("Name", "Blockly");  
Blockly:Property("EditorElement");            -- 编辑元素 用户输入
Blockly:Property("MouseCaptureUI");           -- 鼠标捕获UI
Blockly:Property("FocusUI");                  -- 聚焦UI

local UnitSize = Const.UnitSize;

function Blockly:ctor()
    self.offsetX = 0;
    self.offsetY = 0;
    self.blocks = {};
    local offsetX, offsetY = 5, 5;
    for index, blockOption in ipairs(LuaBlocks) do
        local block = Block:new():Init(self, blockOption);
        block:SetLeftTopUnitCount(offsetX, offsetY);
        local widthUnitCount, heightUnitCount = block:UpdateWidthHeightUnitCount();
        offsetY = offsetY + heightUnitCount + 5;
        table.insert(self.blocks, block);
    end
end

function Blockly:Init(xmlNode, window, parent)
    Blockly._super.Init(self, xmlNode, window, parent);
    local blocklyEditor = BlocklyEditor:new():Init({
        name = "BlocklyEditor",
        attr = {
            style = "position: absolute; left: 0px; top: 0px; width: 0px; height: 0px; overflow: hidden; background-color: #ff0000;",
        }
    }, window, self)
    table.insert(self.childrens, blocklyEditor);
    self:SetEditorElement(blocklyEditor);
    return self;
end

-- 获取所有顶层块
function Blockly:GetBlocks()
    return self.blocks;
end

-- 获取块索引
function Blockly:GetBlockIndex(block)
    for index, _block in ipairs(self.blocks) do
        if (_block == block) then return index end
    end
    return ;
end

-- 移除块
function Blockly:AddBlock(block)
    local index = self:GetBlockIndex(block);
    if (not index) then 
        return table.insert(self.blocks, block);
    end
    
    local tail = #self.blocks;
    self.blocks[tail], self.blocks[index] = self.blocks[index], self.blocks[tail];  -- 放置尾部
end

-- 添加块
function Blockly:RemoveBlock(block)
    local index = self:GetBlockIndex(block);
    if (not index) then return end
    table.remove(self.blocks, index);
end

-- 渲染Blockly
function Blockly:RenderContent(painter)
    local x, y, w, h = self:GetContentGeometry();
    -- 设置绘图类
    -- Shape:SetPainter(painter);

    painter:Translate(x, y);

    painter:Save();
    painter:SetClipRegion(0, 0, w, h);
    painter:Translate(self.offsetX, self.offsetY);
    for _, block in ipairs(self.blocks) do
        block:Render(painter);
        painter:Flush();
    end
    painter:Translate(-self.offsetX, -self.offsetY);
    painter:Restore();

    painter:Translate(-x, -y);
end

-- 布局Blockly
function Blockly:OnAfterUpdateLayout()
    for _, block in ipairs(self.blocks) do
        block:UpdateLayout();
    end
end

-- 捕获鼠标
function Blockly:CaptureMouse(ui)
    self:SetMouseCaptureUI(ui);
    return Blockly._super.CaptureMouse(self);
end

-- 释放鼠标
function Blockly:ReleaseMouseCapture()
    self:SetMouseCaptureUI(nil);
	return Blockly._super.ReleaseMouseCapture(self);
end

-- function Blockly:GetMouseEvent(event)
--     return {
--     }
-- end

-- 获取相对窗口坐标
function Blockly:GetRelPoint(x, y)
    local relx, rely = Blockly._super.GetRelPoint(self, x, y);
    return relx - self.offsetX, rely - self.offsetY;
end

-- 鼠标按下事件
function Blockly:OnMouseDown(event)
    event:accept();
    if (event.target ~= self) then return end

    local x, y = self:GetRelPoint(event.x, event.y);
    local ui = self:GetMouseUI(x, y, event);
    
    -- 失去焦点
    local focusUI = self:GetFocusUI();
    if (focusUI ~= ui and focusUI) then 
        focusUI:OnFocusOut();
        self:SetFocusUI(nil);
    end

    -- 元素被点击 直接返回元素事件处理
    if (ui and ui ~= self) then return ui:OnMouseDown(event) end

    -- 工作区被点击
    self.isMouseDown = true;
    self.startX, self.startY = event.x, event.y;
    self.startOffsetX, self.startOffsetY = self.offsetX, self.offsetY;
end

-- 鼠标移动事件
function Blockly:OnMouseMove(event)
    event:accept();
    if (event.target ~= self) then return end
    
    local x, y = self:GetRelPoint(event.x, event.y);
    local ui = self:GetMouseUI(x, y, event);
    if (ui and ui ~= self) then return ui:OnMouseMove(event) end
    
    if (not self.isMouseDown or not ParaUI.IsMousePressed(0)) then return end
    if (not self.isDragging) then
        if (math.abs(event.x - self.startX) < UnitSize and math.abs(event.y - self.startY) < UnitSize) then return end
        self.isDragging = true;
        self:CaptureMouse(self);
    end
    local offsetX = math.floor((event.x - self.startX) / UnitSize) * UnitSize;
    local offsetY = math.floor((event.y - self.startY) / UnitSize) * UnitSize;
    self.offsetX = self.startOffsetX + offsetX;
    self.offsetY = self.startOffsetY + offsetY;
end

-- 鼠标抬起事件
function Blockly:OnMouseUp(event)
    event:accept();
    if (event.target ~= self) then return end
    
    local x, y = self:GetRelPoint(event.x, event.y);
    local ui = self:GetMouseUI(x, y, event);
    local focusUI = self:GetFocusUI();  -- 获取焦点
    if (focusUI ~= ui and focusUI) then focusUI:OnFocusOut() end
    if (focusUI ~= ui and ui) then ui:OnFocusIn() end
    if (ui and ui ~= self) then 
        self:SetFocusUI(ui);
        return ui:OnMouseUp(event);
    end

    self.isDragging = false;
    self.isMouseDown = false;
    self:ReleaseMouseCapture();
end

-- 获取鼠标元素
function Blockly:GetMouseUI(x, y, event)
    local ui = self:GetMouseCaptureUI();
    if (ui) then return ui end

    local size = #self.blocks;
    for i = size, 1, -1 do
        local block = self.blocks[i];
        ui = block:GetMouseUI(x, y, event);
        if (ui) then return ui end
    end

    return nil;
end

-- 获取代码
function Blockly:GetCode(language)
    local code = "";
    for _, block in ipairs(self.blocks) do
        code = code .. block:GetBlockCode(language) .. "\n";
    end
    return code;
end
