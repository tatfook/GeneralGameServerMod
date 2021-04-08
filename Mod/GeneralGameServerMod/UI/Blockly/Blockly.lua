
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
local Shape = NPL.load("./Shape.lua", IsDevEnv);
local LuaFmt = NPL.load("./LuaFmt.lua", IsDevEnv);
local Toolbox = NPL.load("./Blocks/Toolbox.lua", IsDevEnv);
local Helper = NPL.load("./Helper.lua", IsDevEnv);
local Element = NPL.load("../Window/Element.lua", IsDevEnv);
local ToolBox = NPL.load("./ToolBox.lua", IsDevEnv);
local ContextMenu = NPL.load("./ContextMenu.lua", IsDevEnv);
local Block = NPL.load("./Block.lua", IsDevEnv);
local ShadowBlock = NPL.load("./ShadowBlock.lua", IsDevEnv);
local BlocklyEditor = NPL.load("./BlocklyEditor.lua", IsDevEnv);

local BlocklySimulator = NPL.load("./BlocklySimulator.lua", IsDevEnv);

local Blockly = commonlib.inherit(Element, NPL.export());

Blockly:Property("ClassName", "Blockly");  
Blockly:Property("EditorElement");            -- 编辑元素 用户输入
Blockly:Property("ContextMenu");              -- 上下文菜单
Blockly:Property("MouseCaptureUI");           -- 鼠标捕获UI
Blockly:Property("FocusUI");                  -- 聚焦UI
Blockly:Property("CurrentBlock");             -- 当前拽块
Blockly:Property("Language");                 -- 语言
Blockly:Property("FileManager");              -- 文件管理器
Blockly:Property("ToolBox");                  -- 工具栏
Blockly:Property("ShadowBlock");              -- 占位块
Blockly:Property("Scale", 1);                 -- 缩放

function Blockly:ctor()
    self.offsetX, self.offsetY = 0, 0;
    self.mouseMoveX, self.mouseMoveY = 0, 0;
    self.blocks = {};
    self.block_types = {};
    self.toolbox = ToolBox:new():Init(self);
    self.undos = {}; -- 撤销
    self.redos = {}; -- 恢复
    -- self:SetScale(0.75);
    self:SetScale(1);
    self:SetToolBox(self.toolbox);
end

function Blockly:Init(xmlNode, window, parent)
    Blockly._super.Init(self, xmlNode, window, parent);
    
    local blocklyEditor = BlocklyEditor:new():Init({
        name = "BlocklyEditor",
        attr = {
            style = "position: absolute; left: 0px; top: 0px; width: 0px; height: 0px; overflow: hidden; background-color: #ffffff00;",
        }
    }, window, self);

    table.insert(self.childrens, blocklyEditor);
    blocklyEditor:SetVisible(false);
    blocklyEditor:SetBlockly(self);
    self:SetEditorElement(blocklyEditor);

    local BlocklyContextMenu = ContextMenu:new():Init({
        name = "ContextMenu",
        attr = {
            style = "position: absolute; left: 0px; top: 0px; width: 0px; height: 0px; overflow: hidden; background-color: #383838; color: #ffffff;",
        }
    }, window, self);
    table.insert(self.childrens, BlocklyContextMenu);
    BlocklyContextMenu:SetVisible(false);
    BlocklyContextMenu:SetBlockly(self);
    self:SetContextMenu(BlocklyContextMenu);

    self:SetShadowBlock(ShadowBlock:new():Init(self));

    local typ = self:GetAttrStringValue("type", "");
    local allBlocks, categoryList = Toolbox.GetAllBlocks(typ), Toolbox.GetCategoryList(typ);
    for _, blockOption in ipairs(allBlocks) do self:DefineBlock(blockOption) end
    self.toolbox:SetCategoryList(categoryList);

    return self;
end

function Blockly:GetUnitSize()
    return Const.UnitSize;
end

-- 操作
function Blockly:Do(cmd)
    local block = cmd.block;
    cmd.startLeftUnitCount = block.startLeftUnitCount;
    cmd.startTopUnitCount = block.startTopUnitCount;
    cmd.endLeftUnitCount = block.leftUnitCount;
    cmd.endTopUnitCount = block.topUnitCount;
    table.insert(self.undos, cmd);

    if (cmd.action == "NewBlock" and BlocklySimulator:IsRecording() and self:IsSupportSimulator()) then   -- 从工具栏新增  NewBlock_Copy
        BlocklySimulator:AddVirtualEvent("Blockly_NewBlock", {
            block_type = block:GetType(),
            block_left = cmd.startLeftUnitCount * self.toolbox:GetUnitSize(),
            block_top = cmd.startTopUnitCount * self.toolbox:GetUnitSize(),
        });
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
        block:TryConnectionBlock();
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
        block:TryConnectionBlock();
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

function Blockly:RenderBG(painter)
    local x, y, w, h = self:GetContentGeometry();
    painter:SetBrush("f9f9f9");
    painter:DrawRect(x, y, w, h);
    -- local x, y, w, h = self:GetContentGeometry();
    -- local BGWidth, BGHeight, scale = 498, 493, self:GetScale();
    -- local row, col = math.ceil(h / (BGHeight * scale)), math.ceil(w / (BGWidth * scale));
    -- x = x + Const.ToolBoxWidth;
    -- painter:Translate(x, y);
    -- painter:Save();
    -- painter:SetClipRegion(0, 0, w - Const.ToolBoxWidth, h);
    -- painter:Scale(scale, scale);
    -- painter:SetBrush("#ffffff");
    -- for i = 1, row do 
    --     for j = 1, col do
    --         painter:DrawRectTexture((j - 1) * BGWidth, (i - 1) * BGHeight, BGWidth, BGHeight, "Texture/Aries/Creator/keepwork/ggs/blockly/huawen_512X512_32bits.png#4 9 498 493");
    --     end
    -- end
    -- painter:Scale(1 / scale, 1 / scale);
    -- painter:Restore();
    -- painter:Translate(-x, -y);
end

-- 渲染Blockly
function Blockly:RenderContent(painter)
    local UnitSize, scale = self:GetUnitSize(), self:GetScale();
    local x, y, w, h = self:GetContentGeometry();
    self:RenderBG(painter);
    self:RenderIcons(painter);
    -- 设置绘图类
    -- Shape:SetPainter(painter);
    local CurrentBlock, captureBlock = self:GetCurrentBlock(), self:GetMouseCaptureUI();
    local toolboxWidth = Const.ToolBoxWidth;
    painter:Translate(x, y);
    self.toolbox:Render(painter);

    Shape:SetUnitSize(UnitSize);
    painter:Save();
    painter:SetClipRegion(toolboxWidth, 0, w - toolboxWidth, h);
    painter:Scale(scale, scale);
    painter:Translate(self.offsetX, self.offsetY);
    for _, block in ipairs(self.blocks) do
        if (CurrentBlock ~= block or CurrentBlock ~= captureBlock) then
            block:Render(painter);
            painter:Flush();
        end
    end
    painter:Translate(-self.offsetX, -self.offsetY);
    painter:Scale(1 / scale, 1 / scale);
    painter:Restore();

    if (CurrentBlock and CurrentBlock == captureBlock) then
        painter:Save();
        painter:SetClipRegion(0, 0, w, h);
        painter:Scale(scale, scale);
        painter:Translate(self.offsetX, self.offsetY);
        CurrentBlock:Render(painter);
        painter:Flush();
        painter:Translate(-self.offsetX, -self.offsetY);
        painter:Scale(1 / scale, 1 / scale);
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

function Blockly:GetLogicViewPoint(event)
    local x, y = Blockly._super.GetRelPoint(self, event.x, event.y);  -- 相对坐标为窗口的缩放后坐标
    local scale = self:GetScale();                                    -- 获取缩放值
    return math.floor(x / scale + 0.5), math.floor(y / scale + 0.5);  -- 转化为逻辑坐标
end

function Blockly:GetLogicAbsPoint(event)
    local x, y = self:GetLogicViewPoint(event);
    return x - self.offsetX, y - self.offsetY;
end

-- 鼠标按下事件
function Blockly:OnMouseDown(event)
    event:Accept();
    self:GetContextMenu():Hide();
    if (event.target ~= self or not event:IsLeftButton()) then return end

    local x, y = self:GetLogicAbsPoint(event);
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
        self:UpdateScale();
    elseif (mousePosIndex == 2) then     -- 放大
       self:UpdateScale(0.1);
    elseif (mousePosIndex == 3) then     -- 缩小
       self:UpdateScale(-0.1);
    elseif (mousePosIndex == 4) then
    else
        -- 工作区被点击
        self.isMouseDown = true;
        self.startX, self.startY = self:GetLogicViewPoint(event);
        self.startOffsetX, self.startOffsetY = self.offsetX, self.offsetY;
    end
end

-- 重新布局
function Blockly:UpdateScale(offset)
    local oldScale = self:GetScale();
    local newScale = offset and (oldScale + offset) or 1;
    newScale = math.min(newScale, 4);
    newScale = math.max(newScale, 0.5);
    if (oldScale == newScale) then return end
    self:SetScale(newScale);
    for _, block in ipairs(self.blocks) do
        local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
        leftUnitCount = math.floor(leftUnitCount * oldScale / newScale);
        topUnitCount = math.floor(topUnitCount * oldScale / newScale);
        block:SetLeftTopUnitCount(leftUnitCount, topUnitCount);
        block:UpdateLayout();
    end
end

-- 鼠标移动事件
function Blockly:OnMouseMove(event)
    event:Accept();
    self.mouseMoveX, self.mouseMoveY = Blockly._super.GetRelPoint(self, event.x, event.y);
    if (event.target ~= self or not event:IsLeftButton()) then return end

    local UnitSize = self:GetUnitSize();
    local x, y = self:GetLogicAbsPoint(event);
    local logicViewX, logicViewY = self:GetLogicViewPoint(event);
    local ui = self:GetMouseUI(x, y, event);
    if (ui and ui ~= self) then return ui:OnMouseMove(event) end
    
    if (not self.isMouseDown or not event:IsLeftButton()) then return end
    local offsetX = math.floor((logicViewX - self.startX) / UnitSize) * UnitSize;
    local offsetY = math.floor((logicViewY - self.startY) / UnitSize) * UnitSize;
    if (not self.isDragging) then
        if (offsetX == 0 and offsetY == 0) then return end
        self.isDragging = true;
        self:CaptureMouse(self);
    end
    self.offsetX = self.startOffsetX + offsetX;
    self.offsetY = self.startOffsetY + offsetY;
end

-- 鼠标抬起事件
function Blockly:OnMouseUp(event)
    event:Accept();
    self.isDragging = false;
    self.isMouseDown = false;
    if (event.target ~= self) then return end

    local x, y = self:GetLogicAbsPoint(event);
    local ui = self:GetMouseUI(x, y, event);
    self:ReleaseMouseCapture();

    local focusUI = self:GetFocusUI();  -- 获取焦点
    if (focusUI ~= ui and focusUI) then focusUI:OnFocusOut() end
    if (focusUI ~= ui and ui and event.down_target == ui) then ui:OnFocusIn() end
    
    if (ui and ui ~= self) then 
        self:SetFocusUI(ui);
        ui:OnMouseUp(event);
    end

    if (event:IsRightButton() and not self:IsInnerToolBox(event)) then
        local contextmenu = self:GetContextMenu();
        local absX, absY = self:GetLogicViewPoint(event);
        local menuType = "block";
        contextmenu:SetStyleValue("left", absX);
        contextmenu:SetStyleValue("top", absY);
        if (ui:GetClassName() == "Blockly") then 
            menuType = "blockly";
        else 
            block = ui:GetBlock();
            self:SetCurrentBlock(block);
        end
        self:GetContextMenu():Show(menuType);
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
	elseif (event:IsKeySequence("Paste")) then self:handlePaste();
    elseif (event:IsKeySequence("Delete")) then self:handleDelete()
    else -- 处理普通输入
	end
end

-- 删除当前块
function Blockly:handleDelete()
    local block = self:GetCurrentBlock();
    if (not block) then return end
    block:Disconnection();
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

