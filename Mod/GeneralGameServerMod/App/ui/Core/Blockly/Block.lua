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

local Const = NPL.load("./Const.lua", IsDevEnv);
local Shape = NPL.load("./Shape.lua", IsDevEnv);
local Input = NPL.load("./Inputs/Input.lua", IsDevEnv);
local Connection = NPL.load("./Connection.lua", IsDevEnv);
local BlockInputField = NPL.load("./BlockInputField.lua", IsDevEnv);
local InputFieldContainer = NPL.load("./InputFieldContainer.lua", IsDevEnv);
local FieldSpace = NPL.load("./Fields/Space.lua", IsDevEnv);
local FieldLabel = NPL.load("./Fields/Label.lua", IsDevEnv);
local FieldInput = NPL.load("./Fields/Input.lua", IsDevEnv);
local FieldSelect = NPL.load("./Fields/Select.lua", IsDevEnv);
local InputValue = NPL.load("./Inputs/Value.lua", IsDevEnv);
local InputStatement = NPL.load("./Inputs/Statement.lua", IsDevEnv);

local Block = commonlib.inherit(BlockInputField, NPL.export());
local BlockDebug = GGS.Debug.GetModuleDebug("BlockDebug").Enable();   --Enable  Disable

local nextBlockId = 1;
local UnitSize = Const.UnitSize;

Block:Property("Blockly");
Block:Property("Id");
Block:Property("Name", "Block");
Block:Property("Language");

function Block:ctor()
    self:SetId(nextBlockId);
    nextBlockId = nextBlockId + 1;

    self.inputFieldContainerList = {};           -- 输入字段容器列表
end

function Block:Init(blockly, opt)
    Block._super.Init(self, self, opt);

    self:SetBlockly(blockly);
    
    if (opt.id) then self:SetId(opt.id) end

    if (opt.output) then
        self.outputConnection = Connection:new():Init(self, "value", opt.output);
    elseif (opt.previousStatement or opt.nextStatement) then
        if (opt.previousStatement) then self.previousConnection = Connection:new():Init(self, "statement", opt.previousStatement) end
        if (opt.nextStatement) then self.nextConnection = Connection:new():Init(self, "statement", opt.nextStatement) end
    end

    self:ParseMessageAndArg(opt);
    return self;
end

function Block:ParseMessageAndArg(opt)
    local index, inputFieldContainerIndex = 0, 1;
    local messageIndex, argIndex = "message" .. tostring(index), "arg" .. tostring(index);
    local message, arg = opt[messageIndex], opt[argIndex];
    local function GetInputFieldContainer(isFillFieldSpace)
        local inputFieldContainer = self.inputFieldContainerList[inputFieldContainerIndex] or InputFieldContainer:new():Init(self, isFillFieldSpace);
        self.inputFieldContainerList[inputFieldContainerIndex] = inputFieldContainer;
        return inputFieldContainer;
    end
    while (message) do
        local startPos, len = 1, string.len(message);
        while(startPos <= len) do
            local inputFieldContainer = GetInputFieldContainer(true);
            local pos = string.find(message, "%%", startPos);
            if (not pos) then pos = len + 1 end
            local nostr = string.match(message, "%%(%d+)", startPos) or "";
            local no, nolen = tonumber(nostr), string.len(nostr);
            local text = string.sub(message, startPos, pos - 1) or "";
            local textlen = string.len(text);
            text = string.gsub(string.gsub(text, "^%s*", ""), "%s*$", "");
             -- 添加FieldLabel
            if (text ~= "") then 
                inputFieldContainer:AddInputField(FieldLabel:new():Init(self, text), true);
            end
            if (no and arg and arg[no]) then
                -- 添加InputAndField
                local inputField = arg[no];
                if (inputField.type == "field_input" or inputField.type == "field_number") then
                    inputFieldContainer:AddInputField(FieldInput:new():Init(self, inputField), true);
                elseif (inputField.type == "field_select" or inputField.type == "field_dropdown") then
                    inputFieldContainer:AddInputField(FieldSelect:new():Init(self, inputField), true);
                elseif (inputField.type == "input_dummy") then
                    inputFieldContainer:AddInputField(InputDummy:new():Init(self, inputField));
                elseif (inputField.type == "input_value") then
                    inputFieldContainer:AddInputField(InputValue:new():Init(self, inputField), true);
                elseif (inputField.type == "input_statement") then
                    inputFieldContainerIndex = inputFieldContainerIndex + 1;
                    inputFieldContainer = GetInputFieldContainer();
                    inputFieldContainer:AddInputField(InputStatement:new():Init(self, inputField));
                    inputFieldContainer:SetInputStatementContainer(true);
                    inputFieldContainerIndex = inputFieldContainerIndex + 1;
                end
            end
            startPos = pos + 1 + nolen;
        end
        
        index = index + 1;
        messageIndex, argIndex = "message" .. tostring(index), "arg" .. tostring(index);
        message, arg = opt[messageIndex], opt[argIndex];
    end
end

-- 大小改变
function Block:OnSizeChange()
    -- 设置连接大小
    if (self.previousConnection) then
        self.previousConnection:SetGeometry(self.leftUnitCount, self.topUnitCount, Const.ConnectionRegionWidthUnitCount, Const.ConnectionRegionHeightUnitCount);
    end

    if (self.nextConnection) then
        self.nextConnection:SetGeometry(self.leftUnitCount, self.topUnitCount + self.heightUnitCount + 2 - Const.ConnectionRegionHeightUnitCount, Const.ConnectionRegionWidthUnitCount, Const.ConnectionRegionHeightUnitCount);
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

function Block:Render(painter)
    -- 绘制凹陷部分
    Shape:SetBrush(self:GetColor());
    -- painter:SetPen(self:GetColor());
    painter:Translate(self.left, self.top);
    -- 绘制左右边缘
    if (self:IsOutput()) then
        Shape:DrawUpEdge(painter, self.widthUnitCount);
        Shape:DrawDownEdge(painter, self.widthUnitCount, 0, 0, self.heightUnitCount - Const.BlockEdgeHeightUnitCount);
        Shape:DrawLeftEdge(painter, self.heightUnitCount);
        Shape:DrawRightEdge(painter, self.heightUnitCount, 0, self.widthUnitCount - Const.BlockEdgeWidthUnitCount);
    end
    -- 绘制上下连接
    if (self:IsStatement()) then
        Shape:DrawPrevConnection(painter, self.widthUnitCount);
        Shape:DrawNextConnection(painter, self.widthUnitCount, 0, self.heightUnitCount - Const.ConnectionHeightUnitCount);
    end
    painter:Translate(-self.left, -self.top);

    -- 绘制输入字段
    for _, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        inputFieldContainer:Render(painter);
    end

    local nextBlock = self:GetNextBlock();
    if (nextBlock) then nextBlock:Render(painter) end
end

function Block:UpdateWidthHeightUnitCount()
    local widthUnitCount, heightUnitCount = 0, 0;                 -- 方块宽高
    for _, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        local inputFieldContainerTotalWidthUnitCount, inputFieldContainerTotalHeightUnitCount = inputFieldContainer:UpdateWidthHeightUnitCount();
        if (not inputFieldContainer:IsInputStatementContainer()) then
            widthUnitCount = math.max(widthUnitCount, inputFieldContainerTotalWidthUnitCount);
        end
        heightUnitCount = heightUnitCount + inputFieldContainerTotalHeightUnitCount;
    end
    
    widthUnitCount = math.max(widthUnitCount, Const.ConnectionRegionWidthUnitCount);
    
    for _, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        if (not inputFieldContainer:IsInputStatementContainer()) then
            inputFieldContainer:SetWidthHeightUnitCount(widthUnitCount, nil);
        end
    end

    if (self:IsOutput()) then 
        widthUnitCount = widthUnitCount + Const.BlockEdgeWidthUnitCount * 2;
        heightUnitCount = heightUnitCount + Const.BlockEdgeHeightUnitCount * 2;
    end

    if (self:IsStatement()) then 
        heightUnitCount = heightUnitCount + Const.ConnectionHeightUnitCount * 2;
    end

    self:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount);
    self:SetMaxWidthHeightUnitCount(widthUnitCount, heightUnitCount);
    BlockDebug.Format("widthUnitCount = %s, heightUnitCount = %s", widthUnitCount, heightUnitCount);
    
    local nextBlock = self:GetNextBlock();
    if (nextBlock) then 
        local nextBlockTotalWidthUnitCount, nextBlockTotalHeightUnitCount = nextBlock:UpdateWidthHeightUnitCount();
        widthUnitCount = math.max(widthUnitCount, nextBlockTotalWidthUnitCount);
        heightUnitCount = heightUnitCount + nextBlockTotalHeightUnitCount;
    end

    self:SetTotalWidthHeightUnitCount(widthUnitCount, heightUnitCount);
    return widthUnitCount, heightUnitCount;
end

-- 更新左上位置
function Block:UpdateLeftTopUnitCount()
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    local offsetX, offsetY = leftUnitCount, topUnitCount;
    
    if (self:IsOutput()) then offsetX, offsetY = leftUnitCount + Const.BlockEdgeWidthUnitCount, topUnitCount + Const.BlockEdgeHeightUnitCount end
    if (self:IsStatement()) then offsetY = topUnitCount + Const.ConnectionHeightUnitCount end

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
    local height = (self:IsOutput() and Const.BlockEdgeHeightUnitCount or Const.ConnectionHeightUnitCount) * self:GetUnitSize();

    -- 在block上下边缘
    if (self.left < x and x < (self.left + self.width) and ((self.top < y and y < (self.top + height)) or (y > (self.top + self.height - height) and y < (self.top + self.height)))) then return self end
    
    -- 遍历输入
    for _, inputAndFieldContainer in ipairs(self.inputFieldContainerList) do
        local ui = inputAndFieldContainer:GetMouseUI(x, y);
        if (ui) then return ui end
    end

    return nil;
end

function Block:OnMouseDown(event)
    self.startX, self.startY = event.x , event.y;
    self.startLeftUnitCount, self.startTopUnitCount = self.leftUnitCount, self.topUnitCount;
    self.isMouseDown = true;
end

function Block:OnMouseMove(event)
    if (not self.isMouseDown or not ParaUI.IsMousePressed(0)) then return end
    
    local x, y = event.x, event.y;
    local UnitSize = self:GetUnitSize();
    if (not self.isDragging) then
        if (math.abs(x - self.startX) < UnitSize and math.abs(y - self.startY) < UnitSize) then return end
        self.isDragging = true;
        self:GetBlockly():CaptureMouse(self);
    end
    local XUnitCount = math.floor((x - self.startX) / UnitSize);
    local YUnitCount = math.floor((y - self.startY) / UnitSize);
    
    if (self.previousConnection and self.previousConnection:IsConnection()) then 
        local connection = self.previousConnection:Disconnection();
        if (connection) then connection:GetBlock():GetTopBlock():UpdateLayout() end
    end

    if (self.outputConnection and self.outputConnection:IsConnection()) then
        local connection = self.outputConnection:Disconnection();
        if (connection) then connection:GetBlock():GetTopBlock():UpdateLayout() end
    end

    self:GetBlockly():AddBlock(self);
    self:SetLeftTopUnitCount(self.startLeftUnitCount + XUnitCount, self.startTopUnitCount + YUnitCount);
    self:UpdateLeftTopUnitCount();
end

function Block:OnMouseUp(event)
    if (self.isDragging) then
        self:CheckConnection();
    end

    self.isMouseDown = false;
    self.isDragging = false;
    self:GetBlockly():ReleaseMouseCapture();
end


function Block:CheckConnection()
    local blocks = self:GetBlockly():GetBlocks();
    for _, block in ipairs(blocks) do
        if (self:ConnectionBlock(block)) then return true end
    end
    return false;
end

function Block:IsIntersect(block, isSingleBlock)
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
    local halfWidthUnitCount, halfHeightUnitCount = widthUnitCount / 2, heightUnitCount / 2;
    local centerX, centerY = leftUnitCount + halfWidthUnitCount, topUnitCount + halfHeightUnitCount;

    local blockLeftUnitCount, blockTopUnitCount = block:GetLeftTopUnitCount();
    local blockWidthUnitCount, blockHeightUnitCount = block:GetMaxWidthHeightUnitCount();
    if (not isSingleBlock) then blockWidthUnitCount, blockHeightUnitCount = block:GetTotalWidthHeightUnitCount() end
    local blockHalfWidthUnitCount, blockHalfHeightUnitCount = blockWidthUnitCount / 2, blockHeightUnitCount / 2;
    local blockCenterX, blockCenterY = blockLeftUnitCount + blockHalfWidthUnitCount, blockTopUnitCount + blockHalfHeightUnitCount;
    BlockDebug.Format("Id = %s, left = %s, top = %s, width = %s, height = %s, Id = %s, left = %s, top = %s, width = %s, height = %s", 
        self:GetId(), leftUnitCount, topUnitCount, widthUnitCount, heightUnitCount, block:GetId(), blockLeftUnitCount, blockTopUnitCount, blockWidthUnitCount, blockHeightUnitCount);
    BlockDebug.Format("centerX = %s, centerY = %s, halfWidthUnitCount = %s, halfHeightUnitCount = %s, blockCenterX = %s, blockCenterY = %s, blockHalfWidthUnitCount = %s, blockHalfHeightUnitCount = %s", 
        centerX, centerY, halfWidthUnitCount, halfHeightUnitCount, blockCenterX, blockCenterY, blockHalfWidthUnitCount, blockHalfHeightUnitCount);

    return math.abs(centerX - blockCenterX) <= (halfWidthUnitCount + blockHalfWidthUnitCount) and math.abs(centerY - blockCenterY) <= (halfHeightUnitCount + blockHalfHeightUnitCount);
end

function Block:ConnectionBlock(block)
    if (not block or self == block) then return end
    BlockDebug("==========================BlockConnectionBlock============================");
    -- 是否在整个区域内
    if (not self:IsIntersect(block, false)) then return end

    -- 是否在块区域内
    if (not self:IsIntersect(block, true)) then
        local nextBlock = block:GetNextBlock();
        return nextBlock and self:ConnectionBlock(nextBlock);
    end

    if (self.topUnitCount > block.topUnitCount and self.previousConnection and block.nextConnection and self.previousConnection:IsMatch(block.nextConnection)) then
        self:GetBlockly():RemoveBlock(self);
        local nextConnectionConnection = block.nextConnection:Disconnection();
        self.previousConnection:Connection(block.nextConnection);
        local lastNextBlock = self:GetLastNextBlock();
        if (lastNextBlock.nextConnection) then lastNextBlock.nextConnection:Connection(nextConnectionConnection) end
        self:SetLeftTopUnitCount(block.leftUnitCount, block.topUnitCount + block.heightUnitCount);
        self:GetTopBlock():UpdateLayout();
        BlockDebug("===================previousConnection match nextConnection====================");
        return true;
    elseif (self.topUnitCount < block.topUnitCount and self.nextConnection and block.previousConnection and 
        not self.nextConnection:IsConnection() and not block.previousConnection:IsConnection() and self.nextConnection:IsMatch(block.previousConnection)) then
        self:GetBlockly():RemoveBlock(block);
        self.nextConnection:Connection(block.previousConnection)
        self:SetLeftTopUnitCount(block.leftUnitCount, block.topUnitCount - self.heightUnitCount);
        self:GetTopBlock():UpdateLayout();
        BlockDebug("===================nextConnection match previousConnection====================");
        return true;
    else
        BlockDebug("===================outputConnection match inputConnection====================");
        for _, inputAndFieldContainer in ipairs(block.inputFieldContainerList) do
            if (inputAndFieldContainer:ConnectionBlock(self)) then return true end
        end
    end
end

-- 是否是块
function Block:IsBlock()
    return true;
end

-- 获取字段值
function Block:GetFieldValue(name)
    for _, inputAndFieldContainer in ipairs(block.inputFieldContainerList) do
        local inputAndFields = inputAndFieldContainer:GetInputFields();
        for inputAndField in ipairs(inputAndFields) do
            if (inputAndField:GetName() == name and inputAndField:IsField()) then return inputAndField:GetFieldValue() end
        end
    end
    return ;
end

-- 获取输入代码
function Block:GetInputCode(name)
    for _, inputAndFieldContainer in ipairs(block.inputFieldContainerList) do
        local inputAndFields = inputAndFieldContainer:GetInputFields();
        for inputAndField in ipairs(inputAndFields) do
            if (inputAndField:GetName() == name and inputAndField:IsInput()) then return inputAndField:GetInputCode() end
        end
    end
    return "";
end

-- 获取块代码
function Block:GetBlockCode(language)
    self:SetLanguage(language);
    local option = self:GetOption();
    if (language == "lua") then
    else  -- npl
        return option.ToNPL(self);
    end
    return "";
end
