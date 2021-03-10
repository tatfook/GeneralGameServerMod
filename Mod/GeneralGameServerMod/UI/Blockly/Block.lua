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
local Shape = NPL.load("./Shape.lua", IsDevEnv);
local Input = NPL.load("./Inputs/Input.lua", IsDevEnv);
local Connection = NPL.load("./Connection.lua", IsDevEnv);
local BlockInputField = NPL.load("./BlockInputField.lua", IsDevEnv);
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
Block:Property("Name", "Block");
Block:Property("TopBlock", false, "IsTopBlock");    -- 是否是顶层块

function Block:ctor()
    self:SetId(nextBlockId);
    nextBlockId = nextBlockId + 1;

    self.isDraggable = true;
    self.isToolBoxBlock = false;
    self.inputFieldContainerList = {};           -- 输入字段容器列表
    self.inputFieldMap = {};
end

function Block:Init(blockly, opt)
    Block._super.Init(self, self, opt);

    self:SetBlockly(blockly);
    
    self.isDraggable = if_else(opt.isDraggable == false, false, true);

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

function Block:Clone()
    local clone = Block:new():Init(self:GetBlockly(), self:GetOption());
    for key, val in pairs(self) do
        if (type(val) ~= "function" and type(val) ~= "table" and rawget(self, key) ~= nil) then clone[key] = val end
    end
    clone:UpdateLayout();
    clone.isDraggable = true;
    clone.isToolBoxBlock = false;
    clone.isNewBlock = true;
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
                inputFieldContainer:AddInputField(FieldLabel:new():Init(self, {text = text}), true);
            end
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
            end
            startPos = pos + 1 + nolen;
        end
        
        message, arg = GetMessageArg();
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
    local isCurrentBlock = self:GetBlockly():GetCurrentBlock() == self;
    Shape:SetPen(self:GetPen());
    Shape:SetBrush(self:GetBrush());
    painter:Translate(self.left, self.top);

    -- 绘制上下连接
    if (self:IsStatement()) then
        Shape:DrawPrevConnection(painter, self.widthUnitCount);
        Shape:DrawNextConnection(painter, self.widthUnitCount, 0, self.heightUnitCount - Const.ConnectionHeightUnitCount);
    else
        -- 绘制左右边缘
        Shape:DrawUpEdge(painter, self.widthUnitCount);
        Shape:DrawDownEdge(painter, self.widthUnitCount, 0, 0, self.heightUnitCount - Const.BlockEdgeHeightUnitCount);
        Shape:DrawLeftEdge(painter, self.heightUnitCount);
        if (self:IsOutput()) then
            Shape:DrawRightEdge(painter, self.heightUnitCount, 0, self.widthUnitCount - Const.BlockEdgeWidthUnitCount);
        end
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
    local maxWidthUnitCount, maxHeightUnitCount, widthUnitCount, heightUnitCount = 0, 0, 0, 0;                                                           -- 方块宽高
    for _, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        local inputFieldContainerMaxWidthUnitCount, inputFieldContainerMaxHeightUnitCount, inputFieldContainerWidthUnitCount, inputFieldContainerHeightUnitCount = inputFieldContainer:UpdateWidthHeightUnitCount();
        inputFieldContainerWidthUnitCount, inputFieldContainerHeightUnitCount = inputFieldContainerWidthUnitCount or inputFieldContainerMaxWidthUnitCount, inputFieldContainerHeightUnitCount or inputFieldContainerMaxHeightUnitCount;
        
        widthUnitCount = math.max(widthUnitCount, inputFieldContainerWidthUnitCount);
        heightUnitCount = heightUnitCount + inputFieldContainerHeightUnitCount;
        maxWidthUnitCount = math.max(maxWidthUnitCount, inputFieldContainerMaxWidthUnitCount);
        maxHeightUnitCount = maxHeightUnitCount + inputFieldContainerMaxHeightUnitCount;
    end
    
    widthUnitCount = math.max(widthUnitCount, not self:IsStatement() and 8 or 14);
    for _, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        if (not inputFieldContainer:IsInputStatementContainer()) then
            inputFieldContainer:SetWidthHeightUnitCount(widthUnitCount, nil);
        end
    end

    if (self:IsStatement()) then 
        heightUnitCount = heightUnitCount + Const.ConnectionHeightUnitCount * 2;
        maxHeightUnitCount = maxHeightUnitCount + Const.ConnectionHeightUnitCount * 2;
    else
        -- widthUnitCount = widthUnitCount + Const.BlockEdgeWidthUnitCount * 2;
        -- maxWidthUnitCount = maxWidthUnitCount + Const.BlockEdgeWidthUnitCount * 2;
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
        offsetY = topUnitCount + Const.BlockEdgeHeightUnitCount
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
    if (self.left < x and x < (self.left + self.width) and ((self.top < y and y < (self.top + height)) or (y > (self.top + self.height - height) and y < (self.top + self.height)))) then return self end
    
    -- 遍历输入
    for _, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        local ui = inputFieldContainer:GetMouseUI(x, y, event);
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
    if (not self.isMouseDown or not event:LeftButton()) then return end
    if (not self.isDraggable) then return end

    local blockly, block = self:GetBlockly(), self;
    local x, y = event.x, event.y;
    if (not block.isDragging) then
        if (not event:IsMove()) then return end
        if (block.isToolBoxBlock) then 
            block = self:Clone();
            block.startLeftUnitCount, block.startTopUnitCount = (block.leftUnitCount * Const.DefaultUnitSize - blockly.offsetX) / Const.UnitSize, (block.topUnitCount * Const.DefaultUnitSize - blockly.offsetY) / Const.UnitSize;
            block:SetLeftTopUnitCount(block.startLeftUnitCount, block.startLeftUnitCount);
            block:UpdateLayout();
            self:GetBlockly():OnCreateBlock(block);
        end

        block.isDragging = true;
        block:GetBlockly():CaptureMouse(block);
        block:GetBlockly():SetCurrentBlock(block);
    end
    local XUnitCount = math.floor((x - block.startX) / Const.UnitSize);
    local YUnitCount = math.floor((y - block.startY) / Const.UnitSize);
    
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
end

function Block:OnMouseUp(event)
    if (self.isDragging) then
        if (self:GetBlockly():IsInnerDeleteArea(event.x, event.y) or self:GetBlockly():GetMousePosIndex() == 4) then
            self:GetBlockly():RemoveBlock(self);
            self:GetBlockly():OnDestroyBlock(self);
            self:GetBlockly():SetCurrentBlock(nil);
            self:GetBlockly():ReleaseMouseCapture();
            -- 移除块
            if (not self.isNewBlock) then self:GetBlockly():Do({action = "DeleteBlock", block = self}) end
            return ;
        else
            self:CheckConnection();
        end
        if (self.isNewBlock) then 
            self:GetBlockly():Do({action = "NewBlock", block = self});
        else
            self:GetBlockly():Do({action = "MoveBlock", block = self});
        end
    end

    self:GetBlockly():SetCurrentBlock(self);
    self.isMouseDown = false;
    self.isDragging = false;
    self.isNewBlock = false;
    self:GetBlockly():ReleaseMouseCapture();
end

function Block:GetConnection()
    if (self.outputConnection) then return self.outputConnection:GetConnection() end
    if (self.previousConnection) then return self.previousConnection:GetConnection() end
    return nil;
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
    local code = ""
    if (language == "lua") then
    else  -- npl
        code = option.ToNPL(self);
    end
    local nextBlock = self:GetNextBlock();
    if (nextBlock) then
        code = code .. nextBlock:GetBlockCode();
    end
    return code;
end


-- 获取xmlNode
function Block:SaveToXmlNode()
    local xmlNode = {name = "Block", attr = {}};
    local attr = xmlNode.attr;
    
    attr.type = self:GetType();
    attr.leftUnitCount, attr.topUnitCount = self:GetLeftTopUnitCount();

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
    
    for _, childXmlNode in ipairs(xmlNode) do
        if (childXmlNode.name == "Block") then
            local nextBlock = self:GetBlockly():GetBlockInstanceByXmlNode(childXmlNode);
            self.nextConnection:Connection(nextBlock.previousConnection);
        else
            local inputField = self:GetInputField(childXmlNode.attr.name);
            if (inputField) then inputField:LoadFromXmlNode(childXmlNode) end
        end
    end
end