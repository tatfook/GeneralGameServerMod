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

local FieldSpace = NPL.load("./Fields/Space.lua", IsDevEnv);
local FieldLabel = NPL.load("./Fields/Label.lua", IsDevEnv);
local FieldInput = NPL.load("./Fields/Input.lua", IsDevEnv);
local InputValue = NPL.load("./Inputs/Value.lua", IsDevEnv);
local InputStatement = NPL.load("./Inputs/Statement.lua", IsDevEnv);

local Block = commonlib.inherit(BlockInputField, NPL.export());
local BlockDebug = GGS.Debug.GetModuleDebug("BlockDebug").Enable();   --Enable  Disable

local nextBlockId = 1;
Block:Property("Blockly");
Block:Property("Id");

function Block:ctor()
    self:SetId(nextBlockId);
    nextBlockId = nextBlockId + 1;

    self.inputAndFields = {};                       -- 块内输入
    self.totalMaxWidthUnitCount, self.totalMaxHeightUnitCount = 0, 0;
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
    local index = 0;
    local messageIndex, argIndex = "message" .. tostring(index), "arg" .. tostring(index);
    local message, arg = opt[messageIndex], opt[argIndex];
    while (message) do
        local startPos, len = 1, string.len(message);
        table.insert(self.inputAndFields, FieldSpace:new():Init(self));     -- 起始加空白
        while(startPos <= len) do
            local pos = string.find(message, "%%", startPos);
            if (not pos) then pos = len + 1 end
            local nostr = string.match(message, "%%(%d+)", startPos) or "";
            local no, nolen = tonumber(nostr), string.len(nostr);
            local text = string.sub(message, startPos, pos - 1) or "";
            local textlen = string.len(text);
            text = string.gsub(string.gsub(text, "^%s*", ""), "%s*$", "");
             -- 添加FieldLabel
            if (text ~= "") then
                table.insert(self.inputAndFields, FieldLabel:new():Init(self, text));
                table.insert(self.inputAndFields, FieldSpace:new():Init(self));    -- 加空白
            end
            if (no and arg and arg[no]) then
                -- 添加InputAndField
                local inputField = arg[no];
                if (inputField.type == "field_input" or inputField.type == "field_number") then
                    table.insert(self.inputAndFields, FieldInput:new():Init(self, inputField));
                    table.insert(self.inputAndFields, FieldSpace:new():Init(self));    -- 加空白
                elseif (inputField.type == "input_dummy") then
                    table.insert(self.inputAndFields, InputDummy:new():Init(self, inputField));
                elseif (inputField.type == "input_value") then
                    table.insert(self.inputAndFields, InputValue:new():Init(self, inputField));
                    table.insert(self.inputAndFields, FieldSpace:new():Init(self));    -- 加空白
                elseif (inputField.type == "input_statement") then
                    table.insert(self.inputAndFields, InputStatement:new():Init(self, inputField));
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
        self.previousConnection:SetGeometry(0, 0, Const.ConnectionRegionWidthUnitCount, Const.ConnectionRegionHeightUnitCount);
    end

    if (self.nextConnection) then
        self.nextConnection:SetGeometry(0, self.heightUnitCount + 2 - Const.ConnectionRegionHeightUnitCount, Const.ConnectionRegionWidthUnitCount, Const.ConnectionRegionHeightUnitCount);
    end

    if (self.outputConnection) then
        self.outputConnection:SetGeometry(0, 0, self.widthUnitCount, self.heightUnitCount);
    end

    -- 调整后续块位置
    local nextBlock = self:GetNextBlock();
    if (nextBlock) then nextBlock:SetLeftTopUnitCount(self.leftUnitCount, self.topUnitCount + self.heightUnitCount) end
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

function Block:RenderInputAndField(painter)
    for _, inputAndField in ipairs(self.inputAndFields) do
        painter:Translate(inputAndField.left, inputAndField.top);
        inputAndField:Render(painter);
        painter:Translate(-inputAndField.left, -inputAndField.top);
    end
end

function Block:Render(painter)
    local offsetX, offsetY = 0, 0;
    local UnitSize = self:GetUnitSize();
    -- 绘制凹陷部分
    painter:SetPen(self:GetColor());
    if (self.outputConnection ~= nil) then
        Shape:DrawUpEdge(painter, self.widthUnitCount);
        painter:Translate(0, 1 * UnitSize);   
        offsetY = offsetY + 1;
    elseif (self.previousConnection ~= nil) then
        Shape:DrawPrevConnection(painter, self.widthUnitCount);
        painter:Translate(0, 2 * UnitSize);
        offsetY = offsetY + 2;
    else
    end

    local contentHeightUnitCount = self.heightUnitCount - offsetY * 2;
    self:RenderInputAndField(painter);

    painter:Translate(0, contentHeightUnitCount * UnitSize);
    offsetY = offsetY + contentHeightUnitCount;

    -- 底部
    painter:SetPen(self:GetColor());
    if (self.outputConnection ~= nil) then
        Shape:DrawDownEdge(painter, self.widthUnitCount);
        painter:Translate(0, 1 * UnitSize);   
        offsetY = offsetY + 1;
    elseif (self.nextConnection ~= nil) then
        -- 下边缘
        Shape:DrawDownEdge(painter, self.widthUnitCount, 1);
        painter:Translate(0, 2 * UnitSize);  
        offsetY = offsetY + 2;
        -- 下连接
        Shape:DrawNextConnection(painter, self.widthUnitCount);
    end

    local nextBlock = self:GetNextBlock();
    if (nextBlock) then nextBlock:Render(painter) end

    painter:Translate(0, -offsetY * UnitSize);
end

function Block:UpdateLayout()
    local UnitSize = self:GetUnitSize();
    local maxWidthUnitCount, maxHeightUnitCount = 0, 0;
    local curMaxWidthUnitCount, curMaxHeightUnitCount = 0, 0;    -- 当前行的最大宽高
    local totalMaxWidthUnitCount, totalMaxHeightUnitCount = 0, 0;
    local inputAndFieldCount = #(self.inputAndFields);
    for i = 1, inputAndFieldCount do
        local inputAndField = self.inputAndFields[i];
        if (inputAndField:isa(InputStatement)) then
            maxHeightUnitCount = maxHeightUnitCount + curMaxHeightUnitCount
            inputAndField:SetLeftTopUnitCount(0, maxHeightUnitCount);
        else
            inputAndField:SetLeftTopUnitCount(curMaxWidthUnitCount, maxHeightUnitCount);
        end
        local widthUnitCount, heightUnitCount = inputAndField:UpdateLayout();
        totalMaxWidthUnitCount = math.max(totalMaxWidthUnitCount, widthUnitCount);
        totalMaxHeightUnitCount = math.max(totalMaxHeightUnitCount, heightUnitCount);

        inputAndField:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount);
        if (inputAndField:isa(InputStatement)) then
            maxHeightUnitCount = maxHeightUnitCount + heightUnitCount;
            curMaxWidthUnitCount, curMaxHeightUnitCount = 0, 0;
        else
            curMaxWidthUnitCount = curMaxWidthUnitCount + widthUnitCount;
            curMaxHeightUnitCount = math.max(curMaxHeightUnitCount, heightUnitCount);
            maxWidthUnitCount = math.max(maxWidthUnitCount, curMaxWidthUnitCount);
            if (i == inputAndFieldCount) then maxHeightUnitCount = maxHeightUnitCount + curMaxHeightUnitCount end 
            for j = i - 1, 1, -1 do
                local lastInputAndField = self.inputAndFields[j];
                if (lastInputAndField:isa(InputStatement)) then break end
                lastInputAndField:SetWidthHeightUnitCount(lastInputAndField.widthUnitCount, math.max(lastInputAndField.heightUnitCount, curMaxHeightUnitCount));
            end
        end

        totalMaxWidthUnitCount = math.max(totalMaxWidthUnitCount, maxWidthUnitCount);
        totalMaxHeightUnitCount = math.max(totalMaxHeightUnitCount, maxHeightUnitCount);
    end

    if (self:IsOutput()) then maxHeightUnitCount = maxHeightUnitCount + 2
    elseif (self:IsStatement()) then maxHeightUnitCount = maxHeightUnitCount + 4
    end

    maxWidthUnitCount = math.max(maxWidthUnitCount, self:IsStatement() and 16 or 8);
    maxHeightUnitCount = math.max(maxHeightUnitCount, self:IsStatement() and 12 or 10);
    self:SetWidthHeightUnitCount(maxWidthUnitCount, maxHeightUnitCount);
    -- BlockDebug.Format("maxWidthUnitCount = %s, maxHeightUnitCount = %s", maxWidthUnitCount, maxHeightUnitCount);
    totalMaxWidthUnitCount = math.max(totalMaxWidthUnitCount, maxWidthUnitCount);
    totalMaxHeightUnitCount = math.max(totalMaxHeightUnitCount, maxHeightUnitCount);
    self:SetMaxWidthHeightUnitCount(totalMaxWidthUnitCount, totalMaxHeightUnitCount);
    -- BlockDebug.Format("maxWidthUnitCount = %s, maxHeightUnitCount = %s", totalMaxWidthUnitCount, totalMaxHeightUnitCount);
    
    local nextBlock = self:GetNextBlock();
    if (nextBlock) then 
        local leftUnitCount = self.leftUnitCount;
        local topUnitCount = self.topUnitCount + self.heightUnitCount;
        nextBlock:SetLeftTopUnitCount(leftUnitCount, topUnitCount);
        local nextTotalMaxWidthUnitCount, nextTotalMaxHeightUnitCount = nextBlock:UpdateLayout();
        totalMaxWidthUnitCount = math.max(totalMaxWidthUnitCount, nextTotalMaxWidthUnitCount);
        totalMaxHeightUnitCount = totalMaxHeightUnitCount + nextTotalMaxHeightUnitCount;
    end

    self:SetTotalWidthHeightUnitCount(totalMaxWidthUnitCount, totalMaxHeightUnitCount);
    return totalMaxWidthUnitCount, totalMaxHeightUnitCount;
end

-- 获取鼠标元素
function Block:GetMouseUI(x, y, event)
    -- 不在block内
    if (x < self.left or x > (self.left + self.maxWidth) or y < self.top or y > (self.top + self.maxHeight)) then return self.nextBlock and self.nextBlock:GetMouseUI(x, y, event) end

    -- 上下边缘高度
    local height = (self:IsOutput() and 1 or 2) * self:GetUnitSize();

    -- 在block上下边缘
    if (self.left < x and x < (self.left + self.width) and ((self.top < y and y < (self.top + height)) or (y > (self.top + self.height - height) and y < (self.top + self.height)))) then return self end
    
    -- 遍历输入
    for _, inputAndField in ipairs(self.inputAndFields) do
        local ui = inputAndField:GetMouseUI(x - self.left, y - self.top);

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
    if (not self.isMouseDown) then return end
    local x, y = event.x, event.y;
    local UnitSize = self:GetUnitSize();
    if (not self.isDragging) then
        if (math.abs(x, self.startX) < UnitSize and math.abs(y - self.startY) < UnitSize) then return end
        self.isDragging = true;
        self:GetBlockly():CaptureMouse(self);
    end
    local XUnitCount = math.floor((x - self.startX) / UnitSize);
    local YUnitCount = math.floor((y - self.startY) / UnitSize);
    
    if (self.previousConnection) then self.previousConnection:Disconnection() end

    self:GetBlockly():AddBlock(self);
    self:SetLeftTopUnitCount(self.startLeftUnitCount + XUnitCount, self.startTopUnitCount + YUnitCount);
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
        if (self ~= block and self:IsIntersect(block, false)) then
            if (self:ConnectionBlock(block)) then return true end
        end
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
    if (not self:IsIntersect(block, true)) then
        local nextBlock = block:GetNextBlock();
        return nextBlock and self:ConnectionBlock(nextBlock);
    end

    if (self.topUnitCount > block.topUnitCount and self.previousConnection and block.nextConnection and self.previousConnection:Connection(block.nextConnection)) then
        self:GetBlockly():RemoveBlock(self);
        self:SetLeftTopUnitCount(block.leftUnitCount, block.topUnitCount + block.heightUnitCount);
        BlockDebug("===================previousConnection match nextConnection====================");
        return true;
    elseif (self.topUnitCount < block.topUnitCount and self.nextConnection and block.previousConnection and 
        not self.nextConnection:IsConnection() and not block.previousConnection:IsConnection() and self.nextConnection:Connection(block.previousConnection)) then
        self:GetBlockly():RemoveBlock(block);
        self:SetLeftTopUnitCount(block.leftUnitCount, block.topUnitCount - self.heightUnitCount);
        BlockDebug("===================nextConnection match previousConnection====================");
        return true;
    else
        for _, inputAndField in ipairs(block.inputAndFields) do
            if (inputAndField:ConnectionBlock(self)) then return true end
        end
    end
end
