
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
local Const = NPL.load("./Const.lua", IsDevEnv);
local LuaFmt = NPL.load("./LuaFmt.lua", IsDevEnv);
local Toolbox = NPL.load("./Blocks/Toolbox.lua", IsDevEnv);
local Helper = NPL.load("./Helper.lua", IsDevEnv);
local Element = NPL.load("../Window/Element.lua", IsDevEnv);
local ToolBox = NPL.load("./ToolBox.lua", IsDevEnv);
local Shape = NPL.load("./Shape.lua", IsDevEnv);
local Block = NPL.load("./Block.lua", IsDevEnv);
local BlocklyEditor = NPL.load("./BlocklyEditor.lua", IsDevEnv);
local EventSimulator = NPL.load("../Window/EventSimulator.lua");
local Blockly = commonlib.inherit(Element, NPL.export());

Blockly:Property("Name", "Blockly");  
Blockly:Property("EditorElement");            -- 编辑元素 用户输入
Blockly:Property("MouseCaptureUI");           -- 鼠标捕获UI
Blockly:Property("FocusUI");                  -- 聚焦UI
Blockly:Property("CurrentBlock");             -- 当前拽块
Blockly:Property("Language");                 -- 语言
Blockly:Property("FileManager");              -- 文件管理器
Blockly:Property("BaseStyle", {
    NormalStyle = {
        ["padding"] = "2px",
    }
});

function Blockly:ctor()
    self.offsetX, self.offsetY = 0, 0;
    self.mouseMoveX, self.mouseMoveY = 0, 0;
    self.blocks = {};
    self.block_types = {};
    self.toolbox = ToolBox:new():Init(self);
    self.undos = {}; -- 撤销
    self.redos = {}; -- 恢复
    self.CurrentUnitSize = Const.DefaultUnitSize;
end

function Blockly:Init(xmlNode, window, parent)
    Blockly._super.Init(self, xmlNode, window, parent);
    
    local blocklyEditor = BlocklyEditor:new():Init({
        name = "BlocklyEditor",
        attr = {
            style = "position: absolute; left: 0px; top: 0px; width: 0px; height: 0px; overflow: hidden; background-color: #ffffff00;",
        }
    }, window, self)
    table.insert(self.childrens, blocklyEditor);
    blocklyEditor:SetVisible(false);
    self:SetEditorElement(blocklyEditor);

    local typ = self:GetAttrStringValue("type", "");
    local allBlocks, categoryList = Toolbox.GetAllBlocks(typ), Toolbox.GetCategoryList(typ);
    for _, blockOption in ipairs(allBlocks) do self:DefineBlock(blockOption) end
    self.toolbox:SetCategoryList(categoryList);

    return self;
end

function Blockly:EnableDefaultUnitSize()
    Const.UnitSize = Const.DefaultUnitSize;
end

function Blockly:EnableCurrentUnitSize()
    Const.UnitSize = self.CurrentUnitSize;
end

-- 操作
function Blockly:Do(cmd)
    local block = cmd.block;
    cmd.startLeftUnitCount = block.startLeftUnitCount;
    cmd.startTopUnitCount = block.startTopUnitCount;
    cmd.endLeftUnitCount = block.leftUnitCount;
    cmd.endTopUnitCount = block.topUnitCount;
    table.insert(self.undos, cmd);

    if (cmd.action == "NewBlock" and EventSimulator.IsRecording()) then   -- 从工具栏新增  NewBlock_Copy
        local event_params = EventSimulator.GetEventParams();
        event_params.action = "Blockly_NewBlock";
        event_params.block_type = block:GetType();
        event_params.block_top = cmd.startTopUnitCount * self.toolbox:GetUnitSize();
    end

    self:OnChange();
end

-- 撤销命令
function Blockly:Undo()
    local cmd = self.undos[#self.undos];
    if (not cmd) then return end
    table.remove(self.undos, #self.undos);
    local action, block = cmd.action, cmd.block;
    local connection = block and block:GetConnection();

    if (connection) then
        connection:Disconnection();
        connection:GetBlock():GetTopBlock():UpdateLayout();
    end

    if (action == "DeleteBlock" or action == "MoveBlock") then
        self:AddBlock(block);
        block:SetLeftTopUnitCount(cmd.startLeftUnitCount, cmd.startTopUnitCount);
        block:UpdateLeftTopUnitCount();
        block:CheckConnection();
    elseif (action == "NewBlock") then
        self:RemoveBlock(block);
    end
    table.insert(self.redos, cmd);
    self:OnChange();
end

-- 恢复
function Blockly:Redo()
    local cmd = self.redos[#self.redos];
    if (not cmd) then return end
    table.remove(self.redos, #self.redos);
    local action, block = cmd.action, cmd.block;
    local connection = block and block:GetConnection();

    if (connection) then
        connection:Disconnection();
        connection:GetBlock():GetTopBlock():UpdateLayout();
    end

    if (action == "NewBlock" or action == "MoveBlock") then
        self:AddBlock(block);
        block:SetLeftTopUnitCount(cmd.endLeftUnitCount, cmd.endTopUnitCount);
        block:UpdateLeftTopUnitCount();
        block:CheckConnection();
    elseif (action == "DeleteBlock") then
        self:RemoveBlock(block);
    end

    table.insert(self.undos, cmd);
    self:OnChange();
end

-- 设置工具块
function Blockly:SetToolBoxBlockList()
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
    self:SetCurrentBlock(nil);
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
function Blockly:AddBlock(block, isHeadBlock)
    block:SetTopBlock(true);
    local index = self:GetBlockIndex(block);
    if (not index) then 
        if (isHeadBlock) then
            return table.insert(self.blocks, 1, block);
        else
            return table.insert(self.blocks, block); 
        end
    end
    
    local head, tail = 1, #self.blocks;
    if (isHeadBlock) then
        self.blocks[head], self.blocks[index] = self.blocks[index], self.blocks[head];  -- 放置头部
    else
        self.blocks[tail], self.blocks[index] = self.blocks[index], self.blocks[tail];  -- 放置尾部
    end
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

-- 是否在工作区内
function Blockly:IsInnerViewPort(block)
    local x, y, w, h = self:GetContentGeometry();
    local hw, hh = w / 2, h / 2;
    local cx, cy = Const.ToolBoxWidth + self.offsetX + hw, self.offsetY + hh;
    local b_x, b_y, b_hw, b_hh = block.left, block.top, block.width / 2, block.height / 2;
    local b_cx, b_cy = b_x + b_hw, b_y + b_hh;
    return math.abs(b_cx - cx) <= (hw + b_hw) and math.abs(b_cy - cy) <= (hh + b_hh);
end

function Blockly:GetMousePosIndex()
    return self.mousePosIndex;
end

function Blockly:RenderIcons(painter)
    local x, y, w, h = self:GetGeometry();
    local offsetX, offsetY = x + w - 82, y + h - 220;
    painter:Translate(offsetX, offsetY);
    local mx, my = self.mouseMoveX - offsetX + x, self.mouseMoveY - offsetY + y;
    self.mousePosIndex = 0;
    if (10 <= mx and mx <= 42 and 0 <= my and my <= 32) then 
        painter:SetPen("#ffffffff");
        self.mousePosIndex = 1;
    else painter:SetPen("#ffffff80") end
    painter:DrawRectTexture(10, 0, 32, 32, "Texture/Aries/Creator/keepwork/ggs/blockly_icons_128x128_32bit.png;0 64 32 32");
    if (10 <= mx and mx <= 42 and 42 <= my and my <= 74) then 
        painter:SetPen("#ffffffff");
        self.mousePosIndex = 2;
    else painter:SetPen("#ffffff80") end
    painter:DrawRectTexture(10, 42, 32, 32, "Texture/Aries/Creator/keepwork/ggs/blockly_icons_128x128_32bit.png;32 64 32 32");
    if (10 <= mx and mx <= 42 and 84 <= my and my <= 116) then 
        painter:SetPen("#ffffffff");
        self.mousePosIndex = 3;
    else painter:SetPen("#ffffff80") end
    painter:DrawRectTexture(10, 84, 32, 32, "Texture/Aries/Creator/keepwork/ggs/blockly_icons_128x128_32bit.png;64 64 32 32");

    if (0 <= mx and mx <= 42 and 148 <= my and my <= 193) then 
        self.mousePosIndex = 4;
        painter:SetPen("#ffffffff")
        painter:Translate(42, 157);
        painter:Rotate(45);
        painter:DrawRectTexture(-42, -9, 42, 9, "Texture/Aries/Creator/keepwork/ggs/blockly_icons_128x128_32bit.png;0 0 42 9");
        painter:Rotate(-45);
        painter:Translate(-42, -157);
    else 
        painter:SetPen("#ffffff80");
        painter:DrawRectTexture(0, 148, 42, 9, "Texture/Aries/Creator/keepwork/ggs/blockly_icons_128x128_32bit.png;0 0 42 9");
    end
    painter:DrawRectTexture(0, 157, 42, 45, "Texture/Aries/Creator/keepwork/ggs/blockly_icons_128x128_32bit.png;0 9 42 45");
    painter:Translate(-offsetX, -offsetY);
end

-- 渲染Blockly
function Blockly:RenderContent(painter)
    self:RenderIcons(painter);

    local x, y, w, h = self:GetContentGeometry();
    -- 设置绘图类
    -- Shape:SetPainter(painter);
    local CurrentBlock, captureBlock = self:GetCurrentBlock(), self:GetMouseCaptureUI();
    local toolboxWidth = Const.ToolBoxWidth;
    painter:Translate(x, y);
    painter:Save();
    painter:SetClipRegion(toolboxWidth, 0, w - toolboxWidth, h);
    painter:Translate(self.offsetX, self.offsetY);
    for _, block in ipairs(self.blocks) do
        if (CurrentBlock ~= block or CurrentBlock ~= captureBlock) then
            block:Render(painter);
            painter:Flush();
        end
    end
    painter:Translate(-self.offsetX, -self.offsetY);
    painter:Restore();

    self.toolbox:Render(painter);

    if (CurrentBlock and CurrentBlock == captureBlock) then
        painter:Save();
        painter:SetClipRegion(0, 0, w, h);
        painter:Translate(self.offsetX, self.offsetY);
        CurrentBlock:Render(painter);
        painter:Flush();
        painter:Translate(-self.offsetX, -self.offsetY);
        painter:Restore();
    end

    painter:Translate(-x, -y);
end

-- 布局Blockly
function Blockly:UpdateWindowPos()
    Blockly._super.UpdateWindowPos(self);
    for _, block in ipairs(self.blocks) do
        block:UpdateLayout();
    end
    self.toolbox:UpdateLayout();
end

-- 重新布局
function Blockly:ReLayout(oldUnitSize, newUnitSize)
    if (oldUnitSize == newUnitSize) then return end
    for _, block in ipairs(self.blocks) do
        local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
        leftUnitCount = math.floor(leftUnitCount * oldUnitSize / newUnitSize);
        topUnitCount = math.floor(topUnitCount * oldUnitSize / newUnitSize);
        block:SetLeftTopUnitCount(leftUnitCount, topUnitCount);
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

-- 获取相对窗口坐标
function Blockly:GetRelPoint(x, y)
    local relx, rely = Blockly._super.GetRelPoint(self, x, y);
    return relx - self.offsetX, rely - self.offsetY;
end

-- 鼠标按下事件
function Blockly:OnMouseDown(event)
    event:Accept();

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
    
    local mousePosIndex = self:GetMousePosIndex();
    if (mousePosIndex == 1) then         -- 重置
        self.offsetX, self.offsetY = 0, 0;
        local CurrentUnitSize = self.CurrentUnitSize;
        self.CurrentUnitSize = Const.DefaultUnitSize;
        self:EnableCurrentUnitSize();
        self:ReLayout(CurrentUnitSize, self.CurrentUnitSize);
    elseif (mousePosIndex == 2) then     -- 放大
        local CurrentUnitSize = self.CurrentUnitSize;
        self.CurrentUnitSize = self.CurrentUnitSize + 1;
        self.CurrentUnitSize = math.min(self.CurrentUnitSize, 6);
        self:EnableCurrentUnitSize();
        self:ReLayout(CurrentUnitSize, self.CurrentUnitSize);
    elseif (mousePosIndex == 3) then     -- 缩小
        local CurrentUnitSize = self.CurrentUnitSize;
        self.CurrentUnitSize = self.CurrentUnitSize - 1;
        self.CurrentUnitSize = math.max(self.CurrentUnitSize, 2);
        self:EnableCurrentUnitSize();
        self:ReLayout(CurrentUnitSize, self.CurrentUnitSize);
    elseif (mousePosIndex == 4) then
    else
        -- 工作区被点击
        self.isMouseDown = true;
        self.startX, self.startY = event.x, event.y;
        self.startOffsetX, self.startOffsetY = self.offsetX, self.offsetY;
    end
end

-- 鼠标移动事件
function Blockly:OnMouseMove(event)
    local x, y = self:GetRelPoint(event.x, event.y);
    self.mouseMoveX, self.mouseMoveY = x + self.offsetX, y + self.offsetY;

    event:Accept();
    if (event.target ~= self) then return end
    
    local ui = self:GetMouseUI(x, y, event);
    if (ui and ui ~= self) then return ui:OnMouseMove(event) end
    
    if (not self.isMouseDown or not event:IsLeftButton()) then return end
    if (not self.isDragging) then
        if (math.abs(event.x - self.startX) < Const.UnitSize and math.abs(event.y - self.startY) < Const.UnitSize) then return end
        self.isDragging = true;
        self:CaptureMouse(self);
    end
    local offsetX = math.floor((event.x - self.startX) / Const.UnitSize) * Const.UnitSize;
    local offsetY = math.floor((event.y - self.startY) / Const.UnitSize) * Const.UnitSize;
    self.offsetX = self.startOffsetX + offsetX;
    self.offsetY = self.startOffsetY + offsetY;
end

-- 鼠标抬起事件
function Blockly:OnMouseUp(event)
    event:Accept();
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

-- 鼠标滚动事件
function Blockly:OnMouseWheel(event)
    if (self:IsInnerToolBox(event)) then return self.toolbox:OnMouseWheel(event) end
end

-- 键盘事件
function Blockly:OnKeyDown(event)
    if (not self:IsFocus()) then return end

	local keyname = event.keyname;
	if (keyname == "DIK_RETURN") then 
	elseif (event:IsKeySequence("Undo")) then self:Undo()
	elseif (event:IsKeySequence("Redo")) then self:Redo()
	-- elseif (event:IsKeySequence("Copy")) then self:handleCopy(event)
	elseif (event:IsKeySequence("Paste")) then self:handlePaste(event, "Clipboard");
    elseif (event:IsKeySequence("Delete")) then self:handleDelete(event)
    else -- 处理普通输入
	end
end

-- 删除当前块
function Blockly:handleDelete()
    local block = self:GetCurrentBlock();
    if (not block) then return end
    self:RemoveBlock(block);
    self:OnDestroyBlock(block);
    self:SetCurrentBlock(nil);
end

-- 复制当前块
function Blockly:handlePaste()
    local block = self:GetCurrentBlock();
    if (not block) then return end
    local cloneBlock = block:Clone();
    local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
    cloneBlock:SetLeftTopUnitCount(leftUnitCount + 4, topUnitCount + 4);
    cloneBlock:UpdateLeftTopUnitCount();

    self:AddBlock(cloneBlock);
    self:SetCurrentBlock(cloneBlock);
end

-- 获取代码
function Blockly:GetCode(language)
    self:SetLanguage(language or "NPL");
    local code = "";
    for _, block in ipairs(self.blocks) do
        code = code .. (block:GetBlockCode() or "") .. "\n";
    end
    local prettyCode = code;
    local ok, errinfo = pcall(function()
        prettyCode = LuaFmt.Pretty(code);
    end);
    if (not ok) then print("=============code error==========", errinfo) end

    return code, ok and prettyCode or code;
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
    return Helper.Lua2XmlString(self:SaveToXmlNode(), true);
end

-- 发生改变
function Blockly:OnChange(event)
    self:CallAttrFunction("onchange", nil, event);
end

function Blockly:GetSimulatorName()
    return "blockly_simulator";
end

local BlocklySimulator = commonlib.inherit(EventSimulator.Simulator, {});

function BlocklySimulator.Trigger(params, window)
    local event_params = params.event_params;
    if (event_params and event_params.action == "Blockly_NewBlock") then
        local BlocklyName = Blockly:GetName();
        local blockly = window:ForEach(function(element)
            if (element:GetName() == BlocklyName) then return element end
        end);
        if (blockly) then
            blockly.toolbox:SetBlockPos(event_params.block_type, event_params.block_top);
        end
    end
    return BlocklySimulator._super.Trigger(params, window);
end

EventSimulator.Register(Blockly:GetSimulatorName(), BlocklySimulator);