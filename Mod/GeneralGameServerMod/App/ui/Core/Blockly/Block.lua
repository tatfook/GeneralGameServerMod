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

local Input = NPL.load("./Inputs/Input.lua", IsDevEnv);
local Connection = NPL.load("./Connection.lua", IsDevEnv);

local FieldSpace = NPL.load("./Fields/Space.lua", IsDevEnv);
local FieldLabel = NPL.load("./Fields/Label.lua", IsDevEnv);
local FieldInput = NPL.load("./Fields/Input.lua", IsDevEnv);
local InputValue = NPL.load("./Inputs/Value.lua", IsDevEnv);

local Block = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
local BlockDebug = GGS.Debug.GetModuleDebug("BlockDebug").Enable();   --Enable  Disable

local Triangle = {{0,0,0}, {0,0,0}, {0,0,0}};       -- 三角形
Block:Property("Blockly");
Block:Property("Output");                   -- 输出链接
Block:Property("PreviousStatement");        -- 上一条语句  nil "null", "string", "number", "boolean", ["string"]
Block:Property("NextStatement");            -- 下一条语句
Block:Property("Color");

function Block:ctor()
    self.inputAndFields = {};                       -- 块内输入
    self.prevBlock = nil;                           -- 上一个Block
    self.nextBlock = nil;                           -- 下一个Block

    self.contentWidthUnitCount, self.contentHeightUnitCount = 0, 0;
    self.widthUnitCount, self.heightUnitCount = 0, 0;
    self.leftUnitCount, self.topUnitCount = 0, 0;
    self.left, self.top, self.width, self.height, self.maxWidth, self.maxHeight = 0, 0, 0, 0, 0, 0;
end

function Block:Init(blockly, opt)
    opt = opt or {
        message0 = "测 %1 你好",
        arg0 = {
            {
                name = "x",
                type = "field_input",
                text = "输入框"
            }
        }, 
        color = StyleColor.ConvertTo16("rgb(37,175,244)"),
        -- output = true,
        previousStatement = true,
        nextStatement = true,
    };

    self:SetBlockly(blockly);
    if (opt.output) then
        self:SetOutput(opt.output);
        self.outputConnection = Connection:new():Init("value", opt.output);
    elseif (opt.previousStatement or opt.nextStatement) then
        self:SetPreviousStatement(opt.previousStatement);
        self:SetNextStatement(opt.nextStatement);
        if (opt.previousStatement) then self.previousConnection = Connection:new():Init("statement", opt.previousStatement) end
        if (opt.nextStatement) then self.nextConnection = Connection:new():Init("statement", opt.nextStatement) end
    end

    self:SetColor(opt.color);
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

function Block:SetMaxWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    local UnitSize = self:GetUnitSize();
    self.maxWidthUnitCount, self.maxHeightUnitCount = widthUnitCount, heightUnitCount;
    self.maxWidth, self.maxHeight = widthUnitCount * UnitSize, heightUnitCount * UnitSize;
end

function Block:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    local UnitSize = self:GetUnitSize();
    self.widthUnitCount, self.heightUnitCount = widthUnitCount, heightUnitCount;
    self.width, self.height = widthUnitCount * UnitSize, heightUnitCount * UnitSize;

    -- 设置连接大小
    self:AdjustConnectionPosition();
end

function Block:SetLeftTopUnitCount(leftUnitCount, topUnitCount)
    local UnitSize = self:GetUnitSize();
    self.leftUnitCount, self.topUnitCount = leftUnitCount, topUnitCount;
    self.left, self.top = leftUnitCount * UnitSize, topUnitCount * UnitSize;

    -- 设置连接大小
    self:AdjustConnectionPosition();
end

function Block:AdjustConnectionPosition()
    local statementConnectionHeight = 12;
    if (self.previousConnection) then
        self.previousConnection:SetGeometry(self.leftUnitCount, self.topUnitCount, self.widthUnitCount, statementConnectionHeight);
    end

    if (self.nextConnection) then
        self.nextConnection:SetGeometry(self.leftUnitCount, self.topUnitCount + self.heightUnitCount + 2 - statementConnectionHeight, self.widthUnitCount, statementConnectionHeight);
    end

    if (self.outputConnection) then
        self.outputConnection:SetGeometry(self.leftUnitCount, self.topUnitCount, self.widthUnitCount, self.heightUnitCount);
    end
end

function Block:GetUnitSize()
    return self:GetBlockly():GetUnitSize();
end

function Block:GetSpaceUnitCount() 
    return self:GetBlockly():GetSpaceUnitCount()
end

function Block:GetLineHeightUnitCount()
    return self:GetBlockly():GetLineHeightUnitCount();
end

function Block:IsOutput()
    return self:GetOutput() ~= nil;
end

function Block:IsStatement()
    return self:GetPreviousStatement() ~= nil or self:GetNextStatement() ~= nil;
end

function Block:IsStart()

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
    local WidthUnitCount, HeightUnitCount = self.widthUnitCount, self.heightUnitCount;    
    -- 绘制凹陷部分
    painter:SetPen(self:GetColor());
    if (self:IsOutput()) then
        painter:DrawRect(UnitSize, 0, (WidthUnitCount - 2) * UnitSize, UnitSize);
        -- painter:DrawRect(0, UnitSize, WidthUnitCount * UnitSize, UnitSize);
        painter:DrawCircle(UnitSize, -UnitSize, 0, UnitSize, "z", true, nil, math.pi / 2, math.pi);
        painter:DrawCircle(UnitSize * (WidthUnitCount - 1), -UnitSize, 0, UnitSize, "z", true, nil, 0, math.pi / 2);

        painter:Translate(0, 1 * UnitSize);   -- 上边
        offsetY = offsetY + 1 * UnitSize;
    elseif (self:GetPreviousStatement()) then
        painter:DrawCircle(UnitSize, -UnitSize, 0, UnitSize, "z", true, nil, math.pi / 2, math.pi);
        painter:DrawRect(UnitSize, 0, UnitSize * 3, UnitSize);
        painter:DrawRect(0, UnitSize, UnitSize * 4, UnitSize);
        painter:Translate(UnitSize * 4, 0);
        Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, 0, 0, -UnitSize * 2, UnitSize * 2, -UnitSize * 2;
        painter:DrawTriangleList(Triangle);
        painter:Translate(UnitSize * 6, 0);
        Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, -UnitSize * 2, UnitSize * 2, -UnitSize * 2, UnitSize * 2, 0;
        painter:DrawTriangleList(Triangle);
        painter:Translate(UnitSize * 2, 0);
        local remainSize = WidthUnitCount - 13;
        painter:DrawRect(0, 0, UnitSize * remainSize, UnitSize);
        painter:DrawRect(0, UnitSize, UnitSize * (remainSize + 1), UnitSize);
        painter:Translate(UnitSize * remainSize, 0);
        painter:DrawCircle(0, -UnitSize, 0, UnitSize, "z", true, nil, 0, math.pi / 2);
        painter:Translate(-(WidthUnitCount - 1) * UnitSize, 0);

        painter:Translate(0, 2 * UnitSize);   -- 上边
        offsetY = offsetY + 2 * UnitSize;
    else
    end

    -- 内容区
    self:RenderInputAndField(painter);
    painter:Translate(0, self.contentHeightUnitCount * UnitSize);
    offsetY = offsetY + self.contentHeightUnitCount * UnitSize;

    -- 底部
    painter:SetPen(self:GetColor());
    
    if (self:IsOutput()) then
        painter:DrawRect(UnitSize, 0, (WidthUnitCount - 2) * UnitSize, UnitSize);
        painter:DrawCircle(UnitSize, 0, 0, UnitSize, "z", true, nil, math.pi, math.pi * 3 / 4);
        painter:DrawCircle(UnitSize * (WidthUnitCount - 1), 0, 0, UnitSize, "z", true, nil, math.pi * 3 / 4, math.pi * 2);
        painter:Translate(0, 1 * UnitSize);   -- 下边   offsetY = 12 * UnitSize
        offsetY = offsetY + 1 * UnitSize;
    elseif (self:GetNextStatement()) then
        painter:DrawRect(0, 0, WidthUnitCount * UnitSize, UnitSize);
        painter:DrawRect(UnitSize, UnitSize, (WidthUnitCount - 2) * UnitSize, UnitSize);
        painter:DrawCircle(UnitSize, -UnitSize, 0, UnitSize, "z", true, nil, math.pi, math.pi * 3 / 4);
        painter:DrawCircle(UnitSize * (WidthUnitCount - 1), -UnitSize, 0, UnitSize, "z", true, nil, math.pi * 3 / 4, math.pi * 2);
        
        painter:Translate(0, 2 * UnitSize);   -- 下边   offsetY = 12 * UnitSize
        offsetY = offsetY + 2 * UnitSize;
        -- 绘制突出部分
        painter:Translate(4 * UnitSize, 0);
        Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, 0, UnitSize * 2, -UnitSize * 2, UnitSize * 2, 0;
        painter:DrawTriangleList(Triangle);
        painter:Translate(2 * UnitSize, 0);
        painter:DrawRect(0, 0, UnitSize * 4, UnitSize * 2);
        painter:Translate(4 * UnitSize, 0);
        Triangle[1][1], Triangle[1][2], Triangle[2][1], Triangle[2][2], Triangle[3][1], Triangle[3][2] = 0, 0, 0, -UnitSize * 2, UnitSize * 2, 0;
        painter:DrawTriangleList(Triangle);
        painter:Translate(-10 * UnitSize, 0);
    end

    if (self.nextBlock) then
        self.nextBlock:Render(painter);
    end

    painter:Translate(0, -offsetY);
end


function Block:UpdateLayout()
    local UnitSize = self:GetUnitSize();
    local maxWidthUnitCount, maxHeightUnitCount = 0, 0;
    local curMaxWidthUnitCount, curMaxHeightUnitCount = 0, 0;
    local blockMaxWidthUnitCount, blockMaxHeightUnitCount = 0, 0;
    local inputAndFieldCount = #(self.inputAndFields);
    for i = 1, inputAndFieldCount do
        local inputAndField = self.inputAndFields[i];
        if (inputAndField:isa(InputStatement)) then
            inputAndField:SetLeftTopUnitCount(0, maxHeightUnitCount);
        else
            inputAndField:SetLeftTopUnitCount(curMaxWidthUnitCount, maxHeightUnitCount);
        end
        local widthUnitCount, heightUnitCount = inputAndField:UpdateLayout();
        blockMaxWidthUnitCount = math.max(blockMaxWidthUnitCount, widthUnitCount);
        blockMaxHeightUnitCount = math.max(blockMaxHeightUnitCount, heightUnitCount);

        inputAndField:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount);
        if (inputAndField:isa(InputStatement)) then
            maxHeightUnitCount = maxHeightUnitCount + curMaxHeightUnitCount + heightUnitCount;
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

        blockMaxWidthUnitCount = math.max(blockMaxWidthUnitCount, maxWidthUnitCount);
        blockMaxHeightUnitCount = math.max(blockMaxHeightUnitCount, maxHeightUnitCount);
    end


    self.contentWidthUnitCount, self.contentHeightUnitCount = maxWidthUnitCount, maxHeightUnitCount;

    if (self:IsOutput()) then maxHeightUnitCount = maxHeightUnitCount + 2
    elseif (self:IsStatement()) then maxHeightUnitCount = maxHeightUnitCount + 4
    end

    maxWidthUnitCount = math.max(maxWidthUnitCount, self:IsStatement() and 16 or 8);
    maxHeightUnitCount = math.max(maxHeightUnitCount, self:IsStatement() and 12 or 10);
    blockMaxWidthUnitCount = math.max(blockMaxWidthUnitCount, maxWidthUnitCount);
    blockMaxHeightUnitCount = math.max(blockMaxHeightUnitCount, maxHeightUnitCount);
    self:SetWidthHeightUnitCount(maxWidthUnitCount, maxHeightUnitCount);
    self:SetMaxWidthHeightUnitCount(blockMaxWidthUnitCount, blockMaxHeightUnitCount);
    
    -- echo({self.contentWidthUnitCount, self.contentHeightUnitCount, self.widthUnitCount, self.heightUnitCount});
    if (self.nextBlock) then 
        local leftUnitCount = self.leftUnitCount;
        local topUnitCount = self.topUnitCount + self.heightUnitCount;
        self.nextBlock:SetLeftTopUnitCount(leftUnitCount, topUnitCount);
        self.nextBlock:UpdateLayout();
    end

    return maxWidthUnitCount, maxHeightUnitCount;
end


function Block:GetMouseUI(x, y)
    -- 不在block内
    if (x < self.left or x > (self.left + self.maxWidth) or y < self.top or y > (self.top + self.maxHeight)) then 
        return self.nextBlock and self.nextBlock:GetMouseUI(x, y); 
    end
    
    -- 上下边缘高度
    local height = (self:IsOutput() and 1 or 2) * self:GetUnitSize();

    -- 在block上下边缘
    if (x < (self.left + self.width) and (y < (self.top + height)) or (y > self.height - height)) then return self end
    
    -- 遍历输入
    for _, inputAndField in ipairs(self.inputAndFields) do
        local ui = inputAndField:GetMouseUI(x, y);
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
    self:SetLeftTopUnitCount(self.startLeftUnitCount + XUnitCount, self.startTopUnitCount + YUnitCount);
    if (self.prevBlock) then
        self.prevBlock.nextBlock = nil;
        self.prevBlock = nil;
    end
    self:GetBlockly():AddBlock(self);
end

function Block:OnMouseUp(event)
    self.isMouseDown = false;
    self.isDragging = false;
    self:GetBlockly():ReleaseMouseCapture();
    self:UpdateLayout();
    self:ConnectionBlock();
end

function Block:GetLastNextBlock()
    local nextBlock = self;
    while (nextBlock.nextBlock) do nextBlock = nextBlock.nextBlock end
    return nextBlock;
end

function Block:GetFirstPrevBlock()
    local prevBlock = self;
    while (prevBlock.prevBlock) do prevBlock = prevBlock.prevBlock end
    return prevBlock;
end

function Block:ConnectionBlock()
    local blocks = self:GetBlockly():GetBlocks();

    local leftUnitCount, halfWidthUnitCount, topUnitCount, halfHeightUnitCount = self.leftUnitCount, self.widthUnitCount / 2, self.topUnitCount, self.heightUnitCount / 2;
    local x, y = leftUnitCount + halfWidthUnitCount, topUnitCount + halfHeightUnitCount;

    BlockDebug.Format("SrcBlock leftUnitCount = %s, topUnitCount = %s, widthUnitCount = %s, heightUnitCount = %s", self.leftUnitCount, self.topUnitCount, self.widthUnitCount, self.heightUnitCount);
    local function isIntersect(left, width, top, height)
        local halfWidth, halfHeight = width / 2, height / 2;
        local xx, yy = left + halfWidth, top + halfHeight;
        BlockDebug.Format("srcX = %s, srcY = %s, srcHalfWidth = %s, srcHalfHeight = %s, dstX = %s, dstY = %s, dstHalfWidth = %s,dstHalfHeight = %s", x, y, halfWidthUnitCount, halfHeightUnitCount, xx, yy, halfWidth, halfHeight);
        return math.abs(x - xx) <= (halfWidthUnitCount + halfWidth) and math.abs(y - yy) <= (halfHeightUnitCount + halfHeight);
    end

    local function ConnectionBlock(block)
        if (not block or self == block) then return end
        BlockDebug.Format("TargetBlock leftUnitCount = %s, topUnitCount = %s, widthUnitCount = %s, heightUnitCount = %s, maxWidthUnitCount = %s, maxHeightUnitCount = %s", block.leftUnitCount, block.topUnitCount, block.widthUnitCount, block.heightUnitCount, block.maxWidthUnitCount, block.maxHeightUnitCount);

        if (isIntersect(block.leftUnitCount, block.maxWidthUnitCount, block.topUnitCount, block.maxHeightUnitCount)) then
            BlockDebug(self.previousConnection, block.nextConnection)
            if (self.previousConnection and block.nextConnection and self.previousConnection:IsMatch(block.nextConnection)) then
                self.prevBlock = block;
                self:GetLastNextBlock().nextBlock = block.nextBlock;
                block.nextBlock = self;
                block:UpdateLayout();
            -- elseif (self.nextConnection and block.previousConnection and self.nextConnection:IsMatch(block.previousConnection)) then
            else
                for _, inputAndField in ipairs(block.inputAndFields) do
                    local isConnection = inputAndField:ConnectionBlock(self);
                    if (isConnection) then return true end
                end
            end
        else
            return ConnectionBlock(block.nextBlock);
        end
    end

    for _, block in ipairs(blocks) do
        ConnectionBlock(block);
    end
end
