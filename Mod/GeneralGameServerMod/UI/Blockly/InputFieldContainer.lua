--[[
Title: InputFieldContainer
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local InputFieldContainer = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/InputFieldContainer.lua");
-------------------------------------------------------
]]

local Const = NPL.load("./Const.lua");
local Shape = NPL.load("./Shape.lua");
local FieldSpace = NPL.load("./Fields/Space.lua", IsDevEnv);
local BlockInputField = NPL.load("./BlockInputField.lua", IsDevEnv);

local InputFieldContainer = commonlib.inherit(BlockInputField, NPL.export());

InputFieldContainer:Property("InputStatementContainer", false, "IsInputStatementContainer"); -- 是否是输入语句容器

function InputFieldContainer:ctor()
    self.inputFields = {};
end

function InputFieldContainer:Init(block, isFillFieldSpace)
    InputFieldContainer._super.Init(self, block);
    
    -- 默认填充一个空白字段
    if (isFillFieldSpace) then
        table.insert(self.inputFields, FieldSpace:new():Init(self:GetBlock()));
    end
    
    return self;
end

function InputFieldContainer:AddInputField(inputField, isFillFieldSpace)
    if (inputField) then
        table.insert(self.inputFields, inputField);
    end
    if (isFillFieldSpace) then
        table.insert(self.inputFields, FieldSpace:new():Init(self:GetBlock()));
    end
end

function InputFieldContainer:GetInputFields()
    return self.inputFields;
end

function InputFieldContainer:IsEmpty()
    return #self.inputFields == 0;
end

function InputFieldContainer:UpdateWidthHeightUnitCount()
    local maxWidthUnitCount, maxHeightUnitCount, widthUnitCount, heightUnitCount = 0, 0, 0, 0;
    for _, inputField in ipairs(self.inputFields) do
        local inputFieldMaxWidthUnitCount, inputFieldMaxHeightUnitCount, inputFieldWidthUnitCount, inputFieldHeightUnitCount = inputField:UpdateWidthHeightUnitCount();
        inputFieldWidthUnitCount, inputFieldHeightUnitCount = inputFieldWidthUnitCount or inputFieldMaxWidthUnitCount, inputFieldHeightUnitCount or inputFieldMaxHeightUnitCount;
        inputField:SetWidthHeightUnitCount(inputFieldWidthUnitCount, inputFieldHeightUnitCount);
        inputField:SetMaxWidthHeightUnitCount(inputFieldMaxWidthUnitCount, inputFieldMaxHeightUnitCount);
        widthUnitCount = widthUnitCount + inputFieldWidthUnitCount;
        if (inputField:GetType() == "input_statement") then widthUnitCount = widthUnitCount + Const.ConnectionWidthUnitCount end
        heightUnitCount = math.max(heightUnitCount, inputFieldHeightUnitCount);
        maxWidthUnitCount = maxWidthUnitCount + inputFieldMaxWidthUnitCount;
        maxHeightUnitCount = math.max(maxHeightUnitCount, inputFieldMaxHeightUnitCount);
    end

    for _, inputField in ipairs(self.inputFields) do
        inputField:SetMaxWidthHeightUnitCount(nil, maxHeightUnitCount);
    end

    if (not self:IsInputStatementContainer()) then
        widthUnitCount = widthUnitCount + Const.BlockEdgeWidthUnitCount * 2;
        maxWidthUnitCount = maxWidthUnitCount + Const.BlockEdgeWidthUnitCount * 2;
    end

    self:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount);
    self:SetMaxWidthHeightUnitCount(maxWidthUnitCount, maxHeightUnitCount);
    return maxWidthUnitCount, maxHeightUnitCount, widthUnitCount, heightUnitCount;
end

function InputFieldContainer:UpdateLeftTopUnitCount()
    local offsetX, offsetY = self:GetLeftTopUnitCount();
    if (not self:IsInputStatementContainer()) then
        offsetX = offsetX + Const.BlockEdgeWidthUnitCount;
    end
    for _, inputField in ipairs(self.inputFields) do
        local maxWidthUnitCount, maxHeightUnitCount = inputField:GetMaxWidthHeightUnitCount();
        inputField:SetLeftTopUnitCount(offsetX, offsetY);
        inputField:UpdateLeftTopUnitCount();
        offsetX = offsetX + maxWidthUnitCount;
    end
end

function InputFieldContainer:ConnectionBlock(block)
    for _, inputField in ipairs(self.inputFields) do
        if (inputField:ConnectionBlock(block)) then return true end
    end
    return false;
end

function InputFieldContainer:GetMouseUI(x, y, event)
    local blockWidth = self:GetBlock().width;
    if (x < self.left or x > (self.left + self.maxWidth) or y < self.top or y > (self.top + self.maxHeight)) then return end

    for _, inputField in ipairs(self.inputFields) do
        local ui = inputField:GetMouseUI(x, y, event);
        if (ui) then return ui end
    end
    if (x < self.left or x > (self.left + self.width) or y < self.top or y > (self.top + self.height)) then return end
    if (self:IsInputStatementContainer()) then
        local UnitSize = self:GetUnitSize(); 
        local offsetX, offsetY = Const.StatementWidthUnitCount * UnitSize, (Const.ConnectionHeightUnitCount + Const.BlockEdgeHeightUnitCount) * UnitSize;
        local left, top, width, height = self.left + offsetX, self.top + offsetY, self.width - offsetX, self.height - offsetY * 2;
        if (left < x and x < (left + width) and top < y and y < (top + height)) then return nil end 
    end
    return self;
end

function InputFieldContainer:Render(painter, offsetXUnitCount, offsetYUnitCount)
    if (not self:IsInputStatementContainer() and self:GetBlock():IsStatement()) then
        Shape:SetBrush(self:GetBlock():GetBrush());
        Shape:DrawRect(painter, self.widthUnitCount, self.heightUnitCount, self.leftUnitCount, self.topUnitCount);
    end
    local UnitSize = self:GetUnitSize();
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);
    for _, inputField in ipairs(self.inputFields) do
        inputField:Render(painter);
    end
    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

function InputFieldContainer:ForEach(callback)
    for _, inputField in ipairs(self.inputFields) do
        if (type(callback) == "function") then callback(inputField) end

        local nextBlock = inputField:GetNextBlock();
        if (nextBlock) then
            if (type(callback) == "function") then callback(nextBlock) end
            nextBlock:ForEach(callback);
        end
    end
end