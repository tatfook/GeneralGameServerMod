
--[[
Title: G
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Blockly = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/Blockly.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");
local LuaFmt = NPL.load("./LuaFmt.lua", IsDevEnv);
local Helper = NPL.load("./Helper.lua", IsDevEnv);
local Sandbox = NPL.load("./Sandbox/Sandbox.lua", IsDevEnv);
local Element = NPL.load("../Window/Element.lua", IsDevEnv);
local ToolBox = NPL.load("./ToolBox.lua", IsDevEnv);
local Const = NPL.load("./Const.lua", IsDevEnv);
local Shape = NPL.load("./Shape.lua", IsDevEnv);
local Block = NPL.load("./Block.lua", IsDevEnv);
local BlocklyEditor = NPL.load("./BlocklyEditor.lua", IsDevEnv);
local Blockly = commonlib.inherit(Element, NPL.export());

Blockly:Property("Name", "Blockly");  
Blockly:Property("EditorElement");            -- 编辑元素 用户输入
Blockly:Property("MouseCaptureUI");           -- 鼠标捕获UI
Blockly:Property("FocusUI");                  -- 聚焦UI
Blockly:Property("DragBlock");                -- 拖拽块
Blockly:Property("Language");                 -- 语言
Blockly:Property("FileManager");              -- 文件管理器

local UnitSize = Const.UnitSize;

function Blockly:ctor()
    self.widthUnitCount, self.heightUnitCount = 0, 0;
    self.offsetX, self.offsetY = 0, 0;
    self.blocks = {};
    self.block_types = {};
    self.toolbox = ToolBox:new():Init(self);
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
    blocklyEditor:SetVisible(false);
    self:SetEditorElement(blocklyEditor);

    -- self:SetFileManager()
    return self;
end

-- 定义块
function Blockly:DefineBlock(block)
    self.block_types[block.type] = block;
end

-- 获取块
function Blockly:GetBlockInstanceByType(typ)
    local opts = self.block_types[typ];
    if (not opts) then return nil end
    return Block:new():Init(self, opts);
end

-- 获取块
function Blockly:GetBlockInstanceByXmlNode(xmlNode)
    local block = self:GetBlockInstanceByType(xmlNode.attr.type);
    if (not block) then return nil end
    block:LoadFromXmlNode(xmlNode);
    return block;
end

-- 获取所有顶层块
function Blockly:GetBlocks()
    return self.blocks;
end

-- 清空所有块
function Blockly:ClearBlocks()
    self.blocks = {};
    self:SetDragBlock(nil);
end

-- 遍历
function Blockly:ForEach(callback)
    for _, block in ipairs(self.blocks) do
        if (type(callback) == "function") then callback(block) end
        block:ForEach(callback);
    end
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
    block:SetTopBlock(true);
    local index = self:GetBlockIndex(block);
    if (not index) then 
        return table.insert(self.blocks, block);
    end
    
    local tail = #self.blocks;
    self.blocks[tail], self.blocks[index] = self.blocks[index], self.blocks[tail];  -- 放置尾部
end

-- 添加块
function Blockly:RemoveBlock(block)
    block:SetTopBlock(false);
    local index = self:GetBlockIndex(block);
    if (not index) then return end
    table.remove(self.blocks, index);
end

-- 创建block
function Blockly:OnCreateBlock(block)
end

function Blockly:OnDestroyBlock(block)
end

-- 渲染Blockly
function Blockly:RenderContent(painter)
    local x, y, w, h = self:GetContentGeometry();
    -- 设置绘图类
    -- Shape:SetPainter(painter);
    local dragBlock = self:GetDragBlock();
    local toolboxWidth = Const.ToolBoxWidthUnitCount * Const.UnitSize;
    painter:Translate(x, y);

    painter:Save();
    painter:SetClipRegion(toolboxWidth, 0, w - toolboxWidth, h);
    painter:Translate(self.offsetX, self.offsetY);
    for _, block in ipairs(self.blocks) do
        if (dragBlock ~= block) then
            block:Render(painter);
            painter:Flush();
        end
    end
    painter:Translate(-self.offsetX, -self.offsetY);
    painter:Restore();

    self.toolbox:Render(painter);

    if (dragBlock) then
        painter:Translate(self.offsetX, self.offsetY);
        dragBlock:Render(painter);
        painter:Flush();
        painter:Translate(-self.offsetX, -self.offsetY);
    end

    painter:Translate(-x, -y);
end

-- 布局Blockly
function Blockly:UpdateWindowPos()
    Blockly._super.UpdateWindowPos(self);
    
    for _, block in ipairs(self.blocks) do
        block:UpdateLayout();
    end
    local _, _, width, height = self:GetContentGeometry();
    self.widthUnitCount = math.ceil(width / UnitSize);
    self.heightUnitCount = math.ceil(height / UnitSize);
    self.toolbox:SetWidthHeightUnitCount(nil, self.heightUnitCount);
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
    if (ui ~= self) then 
        event.down_target = ui;
        return ui:OnMouseDown(event);
    end
    
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
    self.isDragging = false;
    self.isMouseDown = false;
    if (event.target ~= self) then return end

    local x, y = self:GetRelPoint(event.x, event.y);
    local ui = self:GetMouseUI(x, y, event);
    self:ReleaseMouseCapture();

    local focusUI = self:GetFocusUI();  -- 获取焦点

    if (focusUI ~= ui and focusUI) then focusUI:OnFocusOut() end
    if (focusUI ~= ui and ui and event.down_target == ui) then ui:OnFocusIn() end
    
    if (ui and ui ~= self) then 
        self:SetFocusUI(ui);
        return ui:OnMouseUp(event);
    end
end

-- 获取鼠标元素
function Blockly:GetMouseUI(x, y, event)
    local ui = self:GetMouseCaptureUI();
    if (ui) then return ui end

    if (self:IsInnerToolBox(event)) then
        ui = self.toolbox:GetMouseUI(x + self.offsetX, y + self.offsetY, event);
        return ui or self.toolbox;
    end
    
    local size = #self.blocks;
    for i = size, 1, -1 do
        local block = self.blocks[i];
        ui = block:GetMouseUI(x, y, event);
        if (ui) then return ui end
    end

    return self;
end

function Blockly:IsInnerToolBox(event)
    local x, y = Blockly._super.GetRelPoint(self, event.x, event.y);         -- 防止减去偏移量
    if (self.toolbox:IsContainPoint(x, y)) then return true end
    return false;
end

-- 是否在删除区域
function Blockly:IsInnerDeleteArea(x, y)
    local x, y = Blockly._super.GetRelPoint(self, x, y);                      -- 防止减去偏移量
    if (self.toolbox:IsContainPoint(x, y)) then return true end
    return false;
end

function Blockly:OnMouseWheel(event)
    if (self:IsInnerToolBox(event)) then return self.toolbox:OnMouseWheel(event) end
end

-- 获取代码
function Blockly:GetCode(language)
    self:SetLanguage(language or "NPL");
    local code = "";
    for _, block in ipairs(self.blocks) do
        code = code .. (block:GetBlockCode() or "") .. "\n";
    end
    return code, LuaFmt.Pretty(code);
end

-- 执行代码
function Blockly:ExecCode(code)
    return Sandbox.ExecCode(code);
end

-- 转换成xml
function Blockly:SaveToXmlNode()
    local xmlNode = {name = "Blockly", attr = {}};
    local attr = xmlNode.attr;

    attr.offsetX = self.offsetX;
    attr.offsetY = self.offsetY;

    for _, block in ipairs(self.blocks) do
        table.insert(xmlNode, block:SaveToXmlNode());
    end

    return xmlNode;
    -- return Helper.Lua2XmlString(xmlNode);
end

function Blockly:LoadFromXmlNode(xmlNode)
    if (not xmlNode or xmlNode.name ~= "Blockly") then return end

    local attr = xmlNode.attr;

    self.offsetX = tonumber(attr.offsetX) or 0;
    self.offsetY = tonumber(attr.offsetY) or 0;

    for _, blockXmlNode in ipairs(xmlNode) do
        local block = self:GetBlockInstanceByXmlNode(blockXmlNode);
        table.insert(self.blocks, block);
    end

    for _, block in ipairs(self.blocks) do
        block:UpdateLayout();
    end
end

function Blockly:LoadFromXmlNodeText(text)
    self:ClearBlocks();
    local xmlNode = Helper.XmlString2Lua(text);
    if (not xmlNode) then return end
    local blocklyXmlNode = xmlNode and commonlib.XPath.selectNode(xmlNode, "//Blockly");
    self:LoadFromXmlNode(blocklyXmlNode);
end

function Blockly:SaveToXmlNodeText()
    return Helper.Lua2XmlString(self:SaveToXmlNode());
end

