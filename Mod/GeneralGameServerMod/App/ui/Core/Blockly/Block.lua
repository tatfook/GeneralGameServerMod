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

local FieldLabel = NPL.load("./Fields/Label.lua", IsDevEnv);
local FieldInput = NPL.load("./Fields/Input.lua", IsDevEnv);

local Block = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local Triangle = {{0,0,0}, {0,0,0}, {0,0,0}};       -- 三角形

Block:Property("Blockly");
Block:Property("Output");                   -- 输出链接
Block:Property("PreviousStatement");        -- 上一条语句  nil "null", "string", "number", "boolean", ["string"]
Block:Property("NextStatement");            -- 下一条语句
Block:Property("Color");
Block:Property("SpaceUnitCount", 2);        -- 字段间间距

function Block:ctor()
    self.inputAndFields = {};                       -- 块内输入
    self.prevBlock = nil;                           -- 上一个Block
    self.nextBlock = nil;                           -- 下一个Block

    self.contentWidthUnitCount, self.contentHeightUnitCount = 0, 0;
    self.widthUnitCount, self.heightUnitCount = 0, 0;
end

function Block:Init(blockly, opt)
    opt = opt or {
        message0 = "测 %1 你好",
        arg0 = {
            {
                name = "x",
                type = "field_input",
                text = ""
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
    elseif (opt.previousStatement or opt.nextStatement) then
        self:SetPreviousStatement(opt.previousStatement);
        self:SetNextStatement(opt.nextStatement);
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
            end
            if (no and arg and arg[no]) then
                -- 添加InputAndField
                local inputField = arg[no];
                if (inputField.type == "field_input" or inputField.type == "field_number") then
                    table.insert(self.inputAndFields, FieldInput:new():Init(self, inputField));
                elseif (inputField.type == "input_dummy") then
                    table.insert(self.inputAndFields, InputDummy:new():Init(self, inputField));
                elseif (inputField.type == "input_value") then
                    table.insert(self.inputAndFields, InputValue:new():Init(self, inputField));
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

function Block:GetUnitSize()
    return self:GetBlockly():GetUnitSize();
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
    WidthUnitCount = math.max(WidthUnitCount, (self:GetPreviousStatement() or self:GetNextStatement()) and 16 or 8);
    HeightUnitCount = math.max(HeightUnitCount, (self:GetPreviousStatement() or self:GetNextStatement()) and 12 or 10);
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
    local SpaceUnitCount= self:GetSpaceUnitCount();
    painter:Translate(SpaceUnitCount * UnitSize, 0);   -- 上边
    self:RenderInputAndField(painter);
    painter:Translate(-SpaceUnitCount * UnitSize, 0);   -- 上边
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
    local SpaceUnitCount= self:GetSpaceUnitCount();
    local maxWidthUnitCount, maxHeightUnitCount = 0, 0;
    local curMaxWidthUnitCount, curMaxHeightUnitCount = 0, 0;
    local inputAndFieldCount = #(self.inputAndFields);
    for i = 1, inputAndFieldCount do
        local inputAndField = self.inputAndFields[i];
        if (inputAndField:isa(InputStatement)) then
            inputAndField:SetLeftTopUnitCount(0, maxHeightUnitCount);
        else
            inputAndField:SetLeftTopUnitCount(curMaxWidthUnitCount, maxHeightUnitCount);
        end
        local widthUnitCount, heightUnitCount = inputAndField:UpdateLayout();
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
    end

    self.contentWidthUnitCount, self.contentHeightUnitCount = maxWidthUnitCount + SpaceUnitCount, maxHeightUnitCount;
    self.widthUnitCount = self.contentWidthUnitCount;
    if (self:IsOutput()) then self.heightUnitCount = self.contentHeightUnitCount + 2;
    elseif (self:IsStatement()) then self.heightUnitCount = self.contentHeightUnitCount + 4
    end

    if (self.nextBlock) then self.nextBlock:UpdateLayout() end

    return self.widthUnitCount, self.heightUnitCount;
end
