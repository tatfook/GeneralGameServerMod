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

local Const = NPL.load("./Const.lua", IsDevEnv);
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
    local widthUnitCount, heightUnitCount = 0, 0;
    for _, inputField in ipairs(self.inputFields) do
        local inputFieldTotalWidthUnitCount, inputFieldTotalHeightUnitCount, inputFieldWidthUnitCount, inputFieldHeightUnitCount = inputField:UpdateWidthHeightUnitCount();
        inputField:SetWidthHeightUnitCount(inputFieldWidthUnitCount or inputFieldTotalWidthUnitCount, inputFieldHeightUnitCount or inputFieldTotalHeightUnitCount);
        widthUnitCount = widthUnitCount + inputFieldTotalWidthUnitCount;
        heightUnitCount = math.max(heightUnitCount, inputFieldTotalHeightUnitCount);
    end
    for _, inputField in ipairs(self.inputFields) do
        inputField:SetMaxWidthHeightUnitCount(nil, heightUnitCount);
    end
    self:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount);
    self:SetMaxWidthHeightUnitCount(widthUnitCount, heightUnitCount);
    return widthUnitCount, heightUnitCount;
end

function InputFieldContainer:UpdateLeftTopUnitCount()
    local offsetX, offsetY = self:GetLeftTopUnitCount();
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

function InputFieldContainer:GetMouseUI(x, y)
    if (not InputFieldContainer._super.GetMouseUI(self, x, y)) then return end
    for _, inputField in ipairs(self.inputFields) do
        local ui = inputField:GetMouseUI(x, y);
        if (ui) then return ui end
    end
    return self;
end

function InputFieldContainer:Render(painter)
    if (not self:IsInputStatementContainer()) then
        painter:SetPen(self:GetBlock():GetColor());
        painter:DrawRect(self.left, self.top, self.width, self.height);
    end
    for _, inputField in ipairs(self.inputFields) do
        inputField:Render(painter);
    end
end
