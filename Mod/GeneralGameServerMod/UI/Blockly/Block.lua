--[[
Title: G
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Block = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Block.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");
local Const = NPL.load("./Const.lua");
local Shape = NPL.load("./Shape.lua");
local Connection = NPL.load("./Connection.lua", IsDevEnv);
local BlockInputField = NPL.load("./BlockInputField.lua", IsDevEnv);
local Input = NPL.load("./Inputs/Input.lua", IsDevEnv);
local Field = NPL.load("./Fields/Field.lua", IsDevEnv);
local InputFieldContainer = NPL.load("./InputFieldContainer.lua", IsDevEnv);
local FieldSpace = NPL.load("./Fields/Space.lua", IsDevEnv);
local FieldLabel = NPL.load("./Fields/Label.lua", IsDevEnv);
local FieldInput = NPL.load("./Fields/Input.lua", IsDevEnv);
local FieldTextarea = NPL.load("./Fields/Textarea.lua", IsDevEnv);
local FieldJson = NPL.load("./Fields/Json.lua", IsDevEnv);
local FieldSelect = NPL.load("./Fields/Select.lua", IsDevEnv);
local FieldVariable = NPL.load("./Fields/Variable.lua", IsDevEnv);
local InputValue = NPL.load("./Inputs/Value.lua", IsDevEnv);
local InputStatement = NPL.load("./Inputs/Statement.lua", IsDevEnv);

local Block = commonlib.inherit(BlockInputField, NPL.export());
local BlockDebug = GGS.Debug.GetModuleDebug("BlockDebug").Disable();   --Enable  Disable

local nextBlockId = 1;
local BlockPen = {width = 1, color = "#ffffff"};
local CurrentBlockPen = {width = 2, color = "#cccccc"};
local BlockBrush = {color = "#ffffff"};
local CurrentBlockBrush = {color = "#ffffff"};

Block:Property("Blockly");
Block:Property("Id");
Block:Property("ClassName", "Block");
Block:Property("TopBlock", false, "IsTopBlock");                               -- 是否是顶层块
Block:Property("InputShadowBlock", false, "IsInputShadowBlock");               -- 是否是输入shadow块
Block:Property("ToolBoxBlock", false, "IsToolBoxBlock");                       -- 是否是工具箱块
Block:Property("Draggable", true, "IsDraggable");                              -- 是否可以拖拽
Block:Property("Dragging", true, "IsDragging");                                -- 是否在拖拽中
Block:Property("ProxyBlock");                                                  -- 代理块


function Block:ctor()
    self:SetId(nextBlockId);
    nextBlockId = nextBlockId + 1;

    self.inputFieldContainerList = {};           -- 输入字段容器列表
    self.inputFieldMap = {};
    self.inputFieldOptionList = {};

    self:SetToolBoxBlock(false);
    self:SetDraggable(true);
    self:SetDragging(false);
end

function Block:Init(blockly, opt)
    Block._super.Init(self, self, opt);
    
    self:SetBlockly(blockly);
    self:SetDraggable(if_else(opt.isDraggable == false, false, true));

    if (opt.id) then self:SetId(opt.id) end

    if (opt.output) then self.outputConnection = Connection:new():Init(self, "output_connection", opt.output) end
    if (opt.previousStatement) then self.previousConnection = Connection:new():Init(self, "previous_connection", opt.previousStatement) end
    if (opt.nextStatement) then self.nextConnection = Connection:new():Init(self, "next_connection", opt.nextStatement) end

    self:ParseMessageAndArg(opt);
    return self;
end

function Block:Clone(clone)
    clone = clone or Block:new():Init(self:GetBlockly(), self:GetOption());
    clone:SetLeftTopUnitCount(self.leftUnitCount, self.topUnitCount);
    for i, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        for j, inputField in ipairs(inputFieldContainer.inputFields) do
            local cloneInputField = clone.inputFieldContainerList[i].inputFields[j];
            if (inputField:IsCanEdit()) then
                cloneInputField:SetLabel(inputField:GetLabel());
                cloneInputField:SetValue(inputField:GetValue());
            end
            if (inputField:IsInput() and inputField.inputConnection:IsConnection()) then
                local connectionBlock = inputField.inputConnection:GetConnectionBlock();
                local cloneConnectionBlock = connectionBlock:Clone(connectionBlock:IsInputShadowBlock() and cloneInputField.inputConnection:GetConnectionBlock() or nil);
                cloneInputField.inputConnection:Connection(cloneConnectionBlock.outputConnection or cloneConnectionBlock.previousConnection);
                if (connectionBlock:GetProxyBlock() == self) then cloneConnectionBlock:SetProxyBlock(clone) end
            end
        end
    end 
    clone:UpdateLayout();
    clone:SetDraggable(self:IsDraggable());
    clone:SetInputShadowBlock(self:IsInputShadowBlock());
    return clone;
end

function Block:ParseMessageAndArg(opt)
    local index, inputFieldContainerIndex = 0, 1;

    local function GetMessageArg()
        local messageIndex, argIndex = "message" .. tostring(index), "arg" .. tostring(index);
        local message, arg = opt[messageIndex], opt[argIndex];
        if (index == 0) then message, arg = opt.message or message, opt.arg or arg end
        index = index + 1;
        return message, arg;
    end

    local function GetInputFieldContainer(isFillFieldSpace)
        local inputFieldContainer = self.inputFieldContainerList[inputFieldContainerIndex] or InputFieldContainer:new():Init(self, isFillFieldSpace);
        self.inputFieldContainerList[inputFieldContainerIndex] = inputFieldContainer;
        return inputFieldContainer;
    end

    local message, arg = GetMessageArg();
    while (message) do
        local lastNo = 0;
        local startPos, len = 1, string.len(message);
        while(startPos <= len) do
            local inputFieldContainer = GetInputFieldContainer(true);
            local pos = string.find(message, "%%", startPos);
            if (not pos) then pos = len + 1 end
            local nostr = string.match(message, "%%([%*%d]+)", startPos) or "";
            local no, nolen = tonumber(nostr), string.len(nostr);
            local text = string.sub(message, startPos, pos - 1) or "";
            local textlen = string.len(text);
            text = string.gsub(string.gsub(text, "^%s*", ""), "%s*$", "");
             -- 添加FieldLabel
            if (text ~= "") then 
                inputFieldContainer:AddInputField(FieldLabel:new():Init(self, {text = text}), true);
            end
            no = no or (nolen > 0 and lastNo + 1 or nil);
            if (no and arg and arg[no]) then
                -- 添加InputAndField
                local inputField = arg[no];
                if (inputField.type == "field_input" or inputField.type == "field_number") then
                    inputFieldContainer:AddInputField(FieldInput:new():Init(self, inputField), true);
                elseif (inputField.type == "field_textarea") then
                    inputFieldContainer:AddInputField(FieldTextarea:new():Init(self, inputField), true);
                elseif (inputField.type == "field_json") then
                    inputFieldContainer:AddInputField(FieldJson:new():Init(self, inputField), true);
                elseif (inputField.type == "field_select" or inputField.type == "field_dropdown") then
                    inputFieldContainer:AddInputField(FieldSelect:new():Init(self, inputField), true);
                elseif (inputField.type == "field_variable") then
                    inputFieldContainer:AddInputField(FieldVariable:new():Init(self, inputField), true);
                elseif (inputField.type == "input_dummy") then
                    -- inputFieldContainer:AddInputField(InputDummy:new():Init(self, inputField));
                elseif (inputField.type == "input_value") then
                    inputFieldContainer:AddInputField(InputValue:new():Init(self, inputField), true);
                elseif (inputField.type == "input_statement") then
                    -- inputFieldContainer:AddInputField(FieldSpace:new():Init(self));
                    inputFieldContainerIndex = inputFieldContainerIndex + 1;
                    inputFieldContainer = GetInputFieldContainer();
                    inputFieldContainer:AddInputField(InputStatement:new():Init(self, inputField));
                    inputFieldContainer:SetInputStatementContainer(true);
                    inputFieldContainerIndex = inputFieldContainerIndex + 1;
                end

                table.insert(self.inputFieldOptionList, inputField);
            end
            startPos = pos + 1 + nolen;
            lastNo = no;
        end
        
        message, arg = GetMessageArg();
    end

    if (#self.inputFieldContainerList == 0) then GetInputFieldContainer(true) end
end

-- 大小改变
function Block:OnSizeChange()
    -- 设置连接大小
    if (self.previousConnection) then
        self.previousConnection:SetGeometry(self.leftUnitCount, self.topUnitCount, self.widthUnitCount, Const.ConnectionRegionHeightUnitCount);
    end

    if (self.nextConnection) then
        self.nextConnection:SetGeometry(self.leftUnitCount, self.topUnitCount + self.heightUnitCount + 2 - Const.ConnectionRegionHeightUnitCount, self.widthUnitCount, Const.ConnectionRegionHeightUnitCount);
    end

    if (self.outputConnection) then
        self.outputConnection:SetGeometry(self.leftUnitCount, self.topUnitCount, self.widthUnitCount, self.heightUnitCount);
    end
end

function Block:IsOutput()
    return self.outputConnection ~= nil;
end

function Block:IsStatement()
    return self.previousConnection ~= nil or self.nextConnection ~= nil;
end

function Block:IsStart()
    return self.previousConnection == nil and self.nextConnection ~= nil;
end

function Block:GetPen()
    local isCurrentBlock = self:GetBlockly():GetCurrentBlock() == self;
    return isCurrentBlock and CurrentBlockPen or BlockPen;
end

function Block:GetBrush()
    local isCurrentBlock = self:GetBlockly():GetCurrentBlock() == self;
    local brush = isCurrentBlock and CurrentBlockBrush or BlockBrush;
    brush.color = self:GetColor();
    return brush;
end

function Block:Render(painter)
    -- 绘制凹陷部分
    Shape:SetPen(self:GetPen());
    Shape:SetBrush(self:GetBrush());
    painter:Translate(self.left, self.top);
    -- 绘制上下连接
    if (self:IsStatement()) then
        Shape:DrawPrevConnection(painter, self.widthUnitCount);
        Shape:DrawNextConnection(painter, self.widthUnitCount, 0, self.heightUnitCount - Const.ConnectionHeightUnitCount);
    else
        Shape:DrawOutput(painter, self.widthUnitCount, self.heightUnitCount);
    end
    painter:Translate(-self.left, -self.top);

    -- 绘制输入字段
    local UnitSize = self:GetUnitSize();
    for i, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        local prev, next = self.inputFieldContainerList[i - 1], self.inputFieldContainerList[i + 1];
        local isOffset = prev and prev:IsInputStatementContainer() and next and next:IsInputStatementContainer() and (not inputFieldContainer:IsInputStatementContainer());
        if (isOffset) then inputFieldContainer:Render(painter, 0, -1)
        else inputFieldContainer:Render(painter) end 
    end

    local nextBlock = self:GetNextBlock();
    if (nextBlock) then nextBlock:Render(painter) end
end

function Block:UpdateWidthHeightUnitCount()
    local maxWidthUnitCount, maxHeightUnitCount, widthUnitCount, heightUnitCount = 0, 0, 0, 0;                                                           -- 方块宽高
    for _, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        local inputFieldContainerMaxWidthUnitCount, inputFieldContainerMaxHeightUnitCount, inputFieldContainerWidthUnitCount, inputFieldContainerHeightUnitCount = inputFieldContainer:UpdateWidthHeightUnitCount();
        inputFieldContainerWidthUnitCount, inputFieldContainerHeightUnitCount = inputFieldContainerWidthUnitCount or inputFieldContainerMaxWidthUnitCount, inputFieldContainerHeightUnitCount or inputFieldContainerMaxHeightUnitCount;
        
        widthUnitCount = math.max(widthUnitCount, inputFieldContainerWidthUnitCount);
        heightUnitCount = heightUnitCount + inputFieldContainerHeightUnitCount;
        maxWidthUnitCount = math.max(maxWidthUnitCount, inputFieldContainerMaxWidthUnitCount);
        maxHeightUnitCount = maxHeightUnitCount + inputFieldContainerMaxHeightUnitCount;
    end
    
    widthUnitCount = math.max(widthUnitCount, not self:IsStatement() and 8 or 16);
    heightUnitCount = math.max(heightUnitCount, Const.LineHeightUnitCount);
    maxWidthUnitCount = math.max(widthUnitCount, maxWidthUnitCount);
    maxHeightUnitCount = math.max(heightUnitCount, maxHeightUnitCount);

    for _, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        inputFieldContainer:SetWidthHeightUnitCount(widthUnitCount, nil);
    end

    if (self:IsStatement()) then 
        heightUnitCount = heightUnitCount + Const.ConnectionHeightUnitCount * 2;
        maxHeightUnitCount = maxHeightUnitCount + Const.ConnectionHeightUnitCount * 2;
    else
        heightUnitCount = heightUnitCount + Const.BlockEdgeHeightUnitCount * 2;
        maxHeightUnitCount = maxHeightUnitCount + Const.BlockEdgeHeightUnitCount * 2;
    end

    self:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount);
    self:SetMaxWidthHeightUnitCount(maxWidthUnitCount, maxHeightUnitCount);
    -- BlockDebug.Format("widthUnitCount = %s, heightUnitCount = %s, maxWidthUnitCount = %s, maxHeightUnitCount = %s", widthUnitCount, heightUnitCount, maxWidthUnitCount, maxHeightUnitCount);
    
    local nextBlock = self:GetNextBlock();
    if (nextBlock) then 
        local _, _, _, _, nextBlockTotalWidthUnitCount, nextBlockTotalHeightUnitCount = nextBlock:UpdateWidthHeightUnitCount();
        self:SetTotalWidthHeightUnitCount(math.max(maxWidthUnitCount, nextBlockTotalWidthUnitCount), maxHeightUnitCount + nextBlockTotalHeightUnitCount);
    else
        self:SetTotalWidthHeightUnitCount(maxWidthUnitCount, maxHeightUnitCount);
    end
    local totalWidthUnitCount, totalHeightUnitCount = self:GetTotalWidthHeightUnitCount();
    return maxWidthUnitCount, maxHeightUnitCount, widthUnitCount, heightUnitCount, totalWidthUnitCount, totalHeightUnitCount;
end

-- 更新左上位置
function Block:UpdateLeftTopUnitCount()
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    local offsetX, offsetY = leftUnitCount, topUnitCount;
    
    if (self:IsStatement()) then 
        offsetY = topUnitCount + Const.ConnectionHeightUnitCount;
    else
        offsetY = topUnitCount + Const.BlockEdgeHeightUnitCount;
    end

    for _, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        local inputFieldContainerTotalWidthUnitCount, inputFieldContainerTotalHeightUnitCount = inputFieldContainer:GetWidthHeightUnitCount();
        inputFieldContainer:SetLeftTopUnitCount(offsetX, offsetY);
        inputFieldContainer:UpdateLeftTopUnitCount();
        offsetY = offsetY + inputFieldContainerTotalHeightUnitCount;
    end
   
    local nextBlock = self:GetNextBlock();
    if (nextBlock) then
        local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
        nextBlock:SetLeftTopUnitCount(leftUnitCount, topUnitCount + heightUnitCount);
        nextBlock:UpdateLeftTopUnitCount();
    end
end

function Block:UpdateLayout()
    self:UpdateWidthHeightUnitCount();
    self:UpdateLeftTopUnitCount();
end

-- 获取鼠标元素
function Block:GetMouseUI(x, y, event)
    -- 整个块区域内
    if (x < self.left or x > (self.left + self.totalWidth) or y < self.top or y > (self.top + self.totalHeight)) then return end
    
    -- 不在block内
    if (x < self.left or x > (self.left + self.maxWidth) or y < self.top or y > (self.top + self.maxHeight)) then 
        local nextBlock = self:GetNextBlock();
        return nextBlock and nextBlock:GetMouseUI(x, y, event);
    end

    -- 上下边缘高度
    local height = (not self:IsStatement() and Const.BlockEdgeHeightUnitCount or Const.ConnectionHeightUnitCount) * self:GetUnitSize();

    -- 在block上下边缘
    if (self.left < x and x < (self.left + self.width)) then
        if (self.top < y and y < (self.top + height)) then return self end
        if (y > (self.top + self.height - height) and y < (self.top + self.height + (self.nextConnection and height or 0))) then return self end
    end
    
    -- 遍历输入
    for _, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        local ui = inputFieldContainer:GetMouseUI(x, y, event);
        if (ui) then return ui end
    end

    return nil;
end

function Block:OnMouseDown(event)
    self.startX, self.startY = self:GetBlockly():GetLogicViewPoint(event);
    self.lastMouseMoveX, self.lastMouseMoveY = self.startX, self.startY;
    self.startLeftUnitCount, self.startTopUnitCount = self.leftUnitCount, self.topUnitCount;
    self.isMouseDown = true;
end

function Block:OnMouseMove(event)
    if (not self.isMouseDown or not event:IsLeftButton()) then return end
    if (not self:IsDraggable()) then return end
    local x, y = self:GetBlockly():GetLogicViewPoint(event);
    if (x == self.lastMouseMoveX and y == self.lastMouseMoveY) then return end
    self.lastMouseMoveX, self.lastMouseMoveY = x, y;

    local blockly, block = self:GetBlockly(), self;
    local scale, toolboxScale = blockly:GetScale(), blockly:GetToolBox():GetScale();
    if (not block:IsDragging()) then
        if (not event:IsMove()) then return end
        if (block:IsToolBoxBlock()) then 
            clone = self:Clone();
            clone:SetToolBoxBlock(false);
            clone.isNewBlock = true;
            clone.startX, clone.startY, clone.lastMouseMoveX, clone.lastMouseMoveY, clone.isMouseDown = block.startX, block.startY, block.lastMouseMoveX, block.lastMouseMoveY, block.isMouseDown;
            local blockX, blockY = math.floor(block.leftUnitCount * block:GetUnitSize() * toolboxScale / scale + 0.5) - blockly.offsetX, math.floor(block.topUnitCount * block:GetUnitSize() * toolboxScale / scale + 0.5) - blockly.offsetY; 
            clone.startLeftUnitCount = math.floor(blockX / clone:GetUnitSize());
            clone.startTopUnitCount = math.floor(blockY / clone:GetUnitSize());
            clone:SetLeftTopUnitCount(clone.startLeftUnitCount, clone.startTopUnitCount);
            clone:UpdateLayout();
            self:GetBlockly():OnCreateBlock(clone);
            block = clone;
        end
        block:SetDragging(true);
        blockly:CaptureMouse(block);
    end
    if (block:IsDragging() and blockly:GetMouseCaptureUI() ~= block) then blockly:CaptureMouse(block) end
    blockly:SetCurrentBlock(block);

    local UnitSize = block:GetUnitSize();
    local XUnitCount = math.floor((x - block.startX) / UnitSize);
    local YUnitCount = math.floor((y - block.startY) / UnitSize);
    
    if (block.previousConnection and block.previousConnection:IsConnection()) then 
        local connection = block.previousConnection:Disconnection();
        if (connection) then connection:GetBlock():GetTopBlock():UpdateLayout() end
    end

    if (block.outputConnection and block.outputConnection:IsConnection()) then
        local connection = self.outputConnection:Disconnection();
        if (connection) then connection:GetBlock():GetTopBlock():UpdateLayout() end
    end

    block:GetBlockly():AddBlock(block);
    block:SetLeftTopUnitCount(block.startLeftUnitCount + XUnitCount, block.startTopUnitCount + YUnitCount);
    block:UpdateLeftTopUnitCount();
    blockly:GetShadowBlock():Shadow(block);

end

function Block:OnMouseUp(event)
    local blockly = self:GetBlockly();
    blockly:GetShadowBlock():Shadow(nil);

    local function delete_block()
        blockly:RemoveBlock(self);
        blockly:OnDestroyBlock(self);
        blockly:SetCurrentBlock(nil);
        blockly:ReleaseMouseCapture();
        -- 移除块
        if (not self.isNewBlock) then 
            blockly:Do({action = "DeleteBlock", block = self});
            blockly:PlayDestroyBlockSound();
        end
        self:SetDragging(false);
        self.isMouseDown = false;
        self.isNewBlock = false;
    end

    if (self:IsDragging()) then
        if (blockly:IsInnerDeleteArea(event.x, event.y) or blockly:GetMousePosIndex() == 4) then
            return delete_block();
        else
            local isConnection = self:TryConnectionBlock();
            if (isConnection) then 
                blockly:PlayConnectionBlockSound();
            else
                if ((false and self:IsOutput()) or (self.previousConnection and not self.previousConnection:IsConnection() and self.previousConnection:GetCheck())) then
                    return delete_block();
                end
            end
        end
        if (self.isNewBlock) then 
            blockly:Do({action = "NewBlock", block = self});
        else
            blockly:Do({action = "MoveBlock", block = self});
        end
    end

    blockly:SetCurrentBlock(self);
    self.isMouseDown = false;
    self.isNewBlock = false;
    self:SetDragging(false);
    blockly:ReleaseMouseCapture();
end

function Block:Disconnection()
    local previousConnection = self.previousConnection and self.previousConnection:Disconnection();
    local nextConnection = self.nextConnection and self.nextConnection:Disconnection();

    if (previousConnection) then
        previousConnection:Connection(nextConnection);
        previousConnection:GetBlock():GetTopBlock():UpdateLayout();
    else 
        if (nextConnection) then
            self:GetBlockly():AddBlock(nextConnection:GetBlock());
        end
    end

    if (self.outputConnection) then self.outputConnection:Disconnection() end
end

function Block:GetConnection()
    if (self.outputConnection) then return self.outputConnection:GetConnection() end
    if (self.previousConnection) then return self.previousConnection:GetConnection() end
    return nil;
end

function Block:TryConnectionBlock(targetBlock)
    local blocks = self:GetBlockly():GetBlocks();
    for _, block in ipairs(blocks) do
        if (block:ConnectionBlock(targetBlock or self)) then return true end
    end
    return false;
end

function Block:IsIntersect(block, isSingleBlock)
    local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
    local widthUnitCount, heightUnitCount = block:GetWidthHeightUnitCount();
    local halfWidthUnitCount, halfHeightUnitCount = widthUnitCount / 2, heightUnitCount / 2;
    local centerX, centerY = leftUnitCount + halfWidthUnitCount, topUnitCount + halfHeightUnitCount;

    local blockLeftUnitCount, blockTopUnitCount = self:GetLeftTopUnitCount();
    local blockWidthUnitCount, blockHeightUnitCount = self:GetMaxWidthHeightUnitCount();
    if (not isSingleBlock) then blockWidthUnitCount, blockHeightUnitCount = self:GetTotalWidthHeightUnitCount() end
    local blockHalfWidthUnitCount, blockHalfHeightUnitCount = blockWidthUnitCount / 2, blockHeightUnitCount / 2;
    local blockCenterX, blockCenterY = blockLeftUnitCount + blockHalfWidthUnitCount, blockTopUnitCount + blockHalfHeightUnitCount;
    BlockDebug.Format("Id = %s, left = %s, top = %s, width = %s, height = %s, Id = %s, left = %s, top = %s, width = %s, height = %s", 
        block:GetId(), leftUnitCount, topUnitCount, widthUnitCount, heightUnitCount, block:GetId(), blockLeftUnitCount, blockTopUnitCount, blockWidthUnitCount, blockHeightUnitCount);
    BlockDebug.Format("centerX = %s, centerY = %s, halfWidthUnitCount = %s, halfHeightUnitCount = %s, blockCenterX = %s, blockCenterY = %s, blockHalfWidthUnitCount = %s, blockHalfHeightUnitCount = %s", 
        centerX, centerY, halfWidthUnitCount, halfHeightUnitCount, blockCenterX, blockCenterY, blockHalfWidthUnitCount, blockHalfHeightUnitCount);

    return math.abs(centerX - blockCenterX) <= (halfWidthUnitCount + blockHalfWidthUnitCount) and math.abs(centerY - blockCenterY) <= (halfHeightUnitCount + blockHalfHeightUnitCount);
end

function Block:ConnectionBlock(block)
    if (not block or self == block) then return end
    if (block.isShadowBlock and block.shadowBlock == self) then return end

    BlockDebug("==========================BlockConnectionBlock============================");
    -- 是否在整个区域内
    if (not self:IsIntersect(block, false)) then return end

    -- 是否在块区域内
    if (not self:IsIntersect(block, true)) then
        local nextBlock = self:GetNextBlock();
        return nextBlock and nextBlock:ConnectionBlock(block);
    end

    if ((self.topUnitCount + self.heightUnitCount - Const.ConnectionRegionHeightUnitCount) < block.topUnitCount 
        and self.nextConnection and block.previousConnection and self.nextConnection:IsMatch(block.previousConnection)) then
        self:GetBlockly():RemoveBlock(block);
        local nextConnectionConnection = self.nextConnection:Disconnection();
        self.nextConnection:Connection(block.previousConnection);
        local lastNextBlock = block:GetLastNextBlock();
        if (lastNextBlock.nextConnection) then lastNextBlock.nextConnection:Connection(nextConnectionConnection) end
        block:SetLeftTopUnitCount(self.leftUnitCount, self.topUnitCount + self.heightUnitCount);
        block:GetTopBlock():UpdateLayout();
        BlockDebug("===================previousConnection match nextConnection====================");
        return true;
    elseif (self.topUnitCount > block.topUnitCount and self.previousConnection and block.nextConnection and 
        not self.previousConnection:IsConnection() and not block.nextConnection:IsConnection() and self.previousConnection:IsMatch(block.nextConnection)) then
        self:GetBlockly():RemoveBlock(self);
        self.previousConnection:Connection(block.nextConnection)
        block:SetLeftTopUnitCount(self.leftUnitCount, self.topUnitCount - block.heightUnitCount);
        block:GetTopBlock():UpdateLayout();
        BlockDebug("===================nextConnection match previousConnection====================");
        return true;
    else
        BlockDebug("===================outputConnection match inputConnection====================");
        for _, inputAndFieldContainer in ipairs(self.inputFieldContainerList) do
            if (inputAndFieldContainer:ConnectionBlock(block)) then return true end
        end
    end
end

-- 遍历
function Block:ForEach(callback)
    for _, inputAndFieldContainer in ipairs(self.inputFieldContainerList) do
        inputAndFieldContainer:ForEach(callback);
    end
    local nextBlock = self:GetNextBlock();
    if (nextBlock) then
        if (type(callback) == "function") then callback(nextBlock) end
        nextBlock:ForEach(callback);
    end
end

-- 是否是块
function Block:IsBlock()
    return true;
end

-- 设置所有字段值
function Block:SetFieldsValue(value)
    local values = commonlib.split(value, ' ');
    for i, opt in ipairs(self.inputFieldOptionList) do
        local field = self:GetInputField(opt.name);
        if (field) then field:SetFieldValue(values[i]) end 
    end
end

-- 获取所有字段值
function Block:GetFieldsValue()
    local value = "";
    for i, opt in ipairs(self.inputFieldOptionList) do
        local fieldValue = self:GetFieldValue(opt.name);
        if (i == 1) then value = fieldValue
        else value = value .. " " .. fieldValue end 
    end
    return value;
end

-- 获取字段值
function Block:GetFieldValue(name)
    local inputAndField = self.inputFieldMap[name];
    return inputAndField and inputAndField:GetFieldValue() or nil;
end

-- 获取字段
function Block:GetValueAsString(name)
    local inputAndField = self.inputFieldMap[name];
    return inputAndField and inputAndField:GetValueAsString() or "";
end

-- 获取字段值
function Block:getFieldValue(name)
    return self:GetFieldValue(name);
end
-- 获取字符串字段
function Block:getFieldAsString(name)
    return self:GetFieldValue(name);
end

-- 获取输入字段
function Block:GetInputField(name)
    return self.inputFieldMap[name];
end

-- 获取块代码
function Block:GetBlockCode()
    local language = self:GetLanguage();
    local option = self:GetOption();
    local ToCode = nil;

    if (type(option["To" .. language]) == "function") then
        ToCode = option["To" .. language];
    elseif (type(option.ToCode) == "function") then
        ToCode = option.ToCode;
    else 
        print("---------------------图块转换函数不存在---------------------")
        echo(option, true);
    end

    local code = ToCode(self) or "";
    local nextBlock = self:GetNextBlock();
    if (nextBlock) then code = code .. nextBlock:GetBlockCode() end
    return code;
end

-- 获取xmlNode
function Block:SaveToXmlNode()
    local xmlNode = {name = "Block", attr = {}};
    local attr = xmlNode.attr;
    
    attr.type = self:GetType();
    attr.leftUnitCount, attr.topUnitCount = self:GetLeftTopUnitCount();
    attr.isInputShadowBlock = self:IsInputShadowBlock() and "true" or "false";
    attr.isDraggable = self:IsDraggable() and "true" or "false";

    for _, inputAndField in pairs(self.inputFieldMap) do
        local subXmlNode = inputAndField:SaveToXmlNode();
        if (subXmlNode) then table.insert(xmlNode, subXmlNode) end
    end

    local nextBlock = self:GetNextBlock();
    if (nextBlock) then table.insert(xmlNode, nextBlock:SaveToXmlNode()) end

    return xmlNode;
end

-- 加载xmlNode
function Block:LoadFromXmlNode(xmlNode)
    local attr = xmlNode.attr;

    self:SetLeftTopUnitCount(tonumber(attr.leftUnitCount) or 0, tonumber(attr.topUnitCount) or 0);
    self:SetInputShadowBlock(attr.isInputShadowBlock == "true");
    self:SetDraggable(if_else(attr.isDraggable == "false", false, true));

    for _, childXmlNode in ipairs(xmlNode) do
        if (childXmlNode.name == "Block") then
            local nextBlock = self:GetBlockly():GetBlockInstanceByXmlNode(childXmlNode);
            if (nextBlock) then
                self.nextConnection:Connection(nextBlock.previousConnection);
            end
        else
            local inputField = self:GetInputField(childXmlNode.attr.name);
            if (inputField) then 
                inputField:LoadFromXmlNode(childXmlNode);
            end
        end
    end
end