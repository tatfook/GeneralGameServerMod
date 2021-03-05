--[[
Title: InputField
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local BlockInputField = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/BlockInputField.lua");
-------------------------------------------------------
]]
local InputElement = NPL.load("../Window/Elements/Input.lua", IsDevEnv);
local SelectElement = NPL.load("../Window/Elements/Select.lua", IsDevEnv);

local Const = NPL.load("./Const.lua");
local Validator = NPL.load("./Validator.lua", IsDevEnv);

local BlockInputField = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

BlockInputField:Property("ClassName", "BlockInputField");
BlockInputField:Property("Name");
BlockInputField:Property("Type");
BlockInputField:Property("Block");
BlockInputField:Property("Option");
BlockInputField:Property("Color", "#ffffff");                    -- 颜色
BlockInputField:Property("BackgroundColor", "#ffffff");          -- 背景颜色
BlockInputField:Property("Edit", false, "IsEdit");               -- 是否在编辑
BlockInputField:Property("Validator", nil);                      -- 验证器
BlockInputField:Property("Value", "");                           -- 值
BlockInputField:Property("Label", "");                           -- 显示值
BlockInputField:Property("Text", "");                            -- 文本值
BlockInputField:Property("EditElement", nil);                    -- 编辑元素


function BlockInputField:ctor()
    self.leftUnitCount, self.topUnitCount, self.widthUnitCount, self.heightUnitCount = 0, 0, 0, 0;
    self.left, self.top, self.width, self.height = 0, 0, 0, 0;
    self.maxWidthUnitCount, self.maxHeightUnitCount, self.maxWidth, self.maxHeight = 0, 0, 0, 0;
    self.totalWidthUnitCount, self.totalHeightUnitCount, self.totalWidth, self.totalHeight = 0, 0, 0, 0;
end

function BlockInputField:Init(block, option)
    option = option or {};

    self:SetBlock(block);
    self:SetOption(option or {});
    self:SetName(option.name);
    self:SetType(option.type);
    self:SetValidator(option.validator);
    self:SetValue(self:GetOptionText());
    self:SetLabel(tostring(self:GetValue()));
    -- 解析颜色值
    self:SetColor(option.color);

    if (option.name and option.name ~= "") then block.inputFieldMap[option.name] = self end

    return self;
end

-- 获取选项文本, 默认为字段值(value)
function BlockInputField:GetOptionText()
    local opt = self:GetOption();
    if (type(opt.text) == "function") then 
        return opt.text(); 
    elseif (type(opt.text) == "string" or type(opt.text) == "number") then 
        return opt.text; 
    else 
        return "";
    end
end

function BlockInputField:IsField()
    return false;
end

function BlockInputField:IsInput()
    return false;
end

function BlockInputField:IsBlock()
    return false;
end

function BlockInputField:SetTotalWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    self.totalWidthUnitCount, self.totalHeightUnitCount = widthUnitCount, heightUnitCount;
    self.totalWidth, self.totalHeight = widthUnitCount * Const.UnitSize, heightUnitCount * Const.UnitSize;
end

function BlockInputField:GetTotalWidthHeightUnitCount()
    return self.totalWidthUnitCount, self.totalHeightUnitCount;
end

function BlockInputField:SetMaxWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    self.maxWidthUnitCount, self.maxHeightUnitCount = widthUnitCount or self.maxWidthUnitCount or self.widthUnitCount, heightUnitCount or self.maxHeightUnitCount or self.heightUnitCount;
    self.maxWidth, self.maxHeight = self.maxWidthUnitCount * Const.UnitSize, self.maxHeightUnitCount * Const.UnitSize;
end

function BlockInputField:UpdateWidthHeightUnitCount()
    return 0, 0, 0, 0, 0, 0;  -- 最大宽高, 元素宽高, 元素总宽高
end

function BlockInputField:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    widthUnitCount, heightUnitCount = widthUnitCount or self.widthUnitCount or 0, heightUnitCount or self.heightUnitCount or 0;
    self.widthUnitCount, self.heightUnitCount = widthUnitCount, heightUnitCount;
    local width, height = widthUnitCount * Const.UnitSize, heightUnitCount * Const.UnitSize;
    if (width == self.width and height == self.height) then return end
    self.width, self.height = width, height;
    self:SetMaxWidthHeightUnitCount(math.max(widthUnitCount, self.maxWidthUnitCount or 0), math.max(heightUnitCount, self.maxHeightUnitCount or 0));
    self:OnSizeChange();
end

function BlockInputField:GetMaxWidthHeightUnitCount()
    return self.maxWidthUnitCount, self.maxHeightUnitCount;
end

function BlockInputField:GetWidthHeightUnitCount()
    return self.widthUnitCount, self.heightUnitCount;
end

function BlockInputField:UpdateLeftTopUnitCount()
end

function BlockInputField:SetLeftTopUnitCount(leftUnitCount, topUnitCount)
    self.leftUnitCount, self.topUnitCount = leftUnitCount, topUnitCount;
    local left, top = leftUnitCount * Const.UnitSize, topUnitCount * Const.UnitSize;
    if (self.left == left and self.top == top) then return end
    self.left, self.top = left, top;
    self:OnSizeChange();
end

function BlockInputField:GetLeftTopUnitCount()
    return self.leftUnitCount, self.topUnitCount;
end

function BlockInputField:GetAbsoluteLeftTopUnitCount()
    if (self == self:GetBlock()) then return self:GetLeftTopUnitCount() end
    local blockLeftUnitCount, blockTopUnitCount = self:GetBlock():GetLeftTopUnitCount();
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    return blockLeftUnitCount + leftUnitCount, blockTopUnitCount + topUnitCount;
end

function BlockInputField:OnSizeChange()
end

function BlockInputField:GetTextWidthUnitCount(text)
    return math.ceil(_guihelper.GetTextWidth(text or "", self:GetFont()) / self:GetUnitSize())
end

function BlockInputField:GetTextHeightUnitCount()
    return math.ceil(self:GetFontSize() / Const.UnitSize);
end

function BlockInputField:GetLineHeightUnitCount()
    return Const.LineHeightUnitCount;
end

function BlockInputField:GetUnitSize()
    return Const.UnitSize;
end

function BlockInputField:GetFontSize()
    -- return (self:GetLineHeightUnitCount() - 4) * self:GetUnitSize();
    return math.floor(Const.LineHeightUnitCount * Const.UnitSize * 3 / 5);
end

function BlockInputField:GetSingleLineTextHeight()
    return math.floor(self:GetFontSize() * 6 / 5);
end

function BlockInputField:GetFont()
    return string.format("System;%s", self:GetFontSize());
end

function BlockInputField:RenderContent(painter)
end

function BlockInputField:GetOffset()
    return self.left + (self.maxWidth - self.width) / 2, self.top + (self.maxHeight - self.height) / 2;
end

function BlockInputField:Render(painter)
end


function BlockInputField:UpdateLayout()
end

function BlockInputField:OnMouseDown(event)
    self:GetBlock():OnMouseDown(event);
end

function BlockInputField:OnMouseMove(event)
    self:GetBlock():OnMouseMove(event);
end

function BlockInputField:OnMouseUp(event)
    self:GetBlock():OnMouseUp(event);
end

function BlockInputField:GetMouseUI(x, y)
    if (x < self.left or x > (self.left + self.width) or y < self.top or y > (self.top + self.height)) then return end
    return self;
end

function BlockInputField:OnFocusOut()
end

function BlockInputField:OnFocusIn()
end

function BlockInputField:FocusIn()
    local blockly = self:GetBlock():GetBlockly();
    local focusUI = blockly:GetFocusUI();
    if (focusUI == self) then return end
    if (focusUI) then focusUI:OnFocusOut() end
    self:OnFocusIn();
end

function BlockInputField:FocusOut()
    self:OnFocusOut();

    local blockly = self:GetBlock():GetBlockly();
    local focusUI = blockly:GetFocusUI();
    if (focusUI == self) then blockly:SetFocusUI(nil) end
end


function BlockInputField:ConnectionBlock(block)
    return ;
end

function BlockInputField:GetNextBlock()
    local block = self:GetBlock();
    local connection = block.nextConnection and block.nextConnection:GetConnection();
    return connection and connection:GetBlock();
end

function BlockInputField:GetLastNextBlock()
    local prevBlock, nextBlock = self:GetBlock(), self:GetNextBlock();
    while (nextBlock) do 
        prevBlock = nextBlock;
        nextBlock = prevBlock:GetNextBlock();
    end
    return prevBlock;
end

function BlockInputField:GetOutputBlock()
    local block = self:GetBlock();
    local connection = block.outputConnection and block.outputConnection:GetConnection();
    return connection and connection:GetBlock();
end

function BlockInputField:GetTopBlock()
    local prevBlock, nextBlock = self:GetPrevBlock() or self:GetOutputBlock(), self:GetBlock();
    while (prevBlock) do 
        nextBlock = prevBlock;
        prevBlock = nextBlock:GetPrevBlock();
    end
    return nextBlock;
end

function BlockInputField:GetPrevBlock()
    local block = self:GetBlock();
    local connection = block.previousConnection and block.previousConnection:GetConnection();
    return connection and connection:GetBlock();
end

function BlockInputField:GetEditorElement()
    return self:GetBlock():GetBlockly():GetEditorElement();
end

function BlockInputField:GetBlocklyElement()
    return self:GetBlock():GetBlockly();
end

function BlockInputField:Debug()
    GGS.DEBUG.Format("left = %s, top = %s, width = %s, height = %s, maxWidth = %s, maxHeight = %s, totalWidth = %s, totalHeight = %s", 
        self.leftUnitCount, self.topUnitCount, self.widthUnitCount, self.heightUnitCount, self.maxWidthUnitCount, self.maxHeightUnitCount, self.totalWidthUnitCount, self.totalHeightUnitCount);
end

function BlockInputField:IsCanEdit()
    return false;
end

function BlockInputField:GetMinEditFieldWidthUnitCount()
    return Const.MinEditFieldWidthUnitCount;
end

function BlockInputField:GetFieldInputEditElement(parentElement)
    local InputEditElement = InputElement:new():Init({
        name = "input",
        attr = {
            style = "width: 100%; height: 100%; border: none; " .. string.format("font-size: %spx; border-radius: %spx; padding: 2px %spx", self:GetFontSize(),Const.UnitSize, Const.UnitSize * (Const.BlockEdgeWidthUnitCount + 1)),
            value = self:GetValue(),
            type = (self:GetType() == "field_number" or (self:GetType() == "input_value" and self:GetShadowType() == "math_number")) and "number" or "text",
        },
    }, parentElement:GetWindow(), parentElement);

    local function InputChange(bFinish)
        local value = InputEditElement:GetValue();
        self:SetFieldValue(value);
        self:SetLabel(tostring(self:GetValue()));
        self:UpdateEditAreaSize();
        if (bFinish) then self:FocusOut() end
    end 

    InputEditElement:SetAttrValue("onkeydown.enter", function() InputChange(true) end);
    InputEditElement:SetAttrValue("onblur", function() InputChange(true) end);
    InputEditElement:SetAttrValue("onchange", function() InputChange(false) end);

    return InputEditElement;
end 

function BlockInputField:GetFieldSelectEditElement(parentElement, isAllowCreate)
    local SelectEditElement = SelectElement:new():Init({
        name = "select",
        attr = {
            -- style = "width: 100%; height: 100%; border: none; " .. string.format("font-size: %spx; border-radius: %spx; padding: 2px %spx", self:GetFontSize(), Const.UnitSize, Const.UnitSize * (Const.BlockEdgeWidthUnitCount + 1)),
            style = "width: 100%; height: 100%; border: none; padding: 2px 4px; " .. string.format("font-size: %spx; border-radius: %spx; ", self:GetFontSize(), Const.UnitSize),
            value = self:GetValue(),
            options = self:GetOptions(),
            AllowCreate = isAllowCreate,
        },
    }, parentElement:GetWindow(), parentElement);

    SelectEditElement:SetAttrValue("onselect", function(value, label)
        self:SetValue(value);
        self:SetLabel(label);
        self:FocusOut();
    end);

    return SelectEditElement;
end

function BlockInputField:UpdateEditAreaSize()
    if (not self:IsEdit()) then return end
    self:GetTopBlock():UpdateLayout();
    local blockly = self:GetBlock():GetBlockly();
    local editor = self:GetEditorElement();
    local offsetX, offsetY = 2, 2;
    editor:SetStyleValue("left", self.left + (self.maxWidth - self.width) / 2 + blockly.offsetX + offsetX);
    editor:SetStyleValue("top", self.top + (self.maxHeight - self.height) / 2 + blockly.offsetY + offsetY);
    editor:SetStyleValue("width", self.width);
    editor:SetStyleValue("height", self.height);
    editor:UpdateLayout();
end

function BlockInputField:GetFieldEditType()
    return "input";
end

function BlockInputField:GetFieldEditElement(parentElement)
    local editElement = self:GetEditElement();
    if (editElement) then return editElement end

    local edittype = self:GetFieldEditType();
    if (edittype == "input") then
        editElement = self:GetFieldInputEditElement(parentElement);
    elseif (edittype == "select") then
        editElement = self:GetFieldSelectEditElement(parentElement, true);
    end

    self:SetEditElement(editElement);
    return editElement;
end

function BlockInputField:BeginEdit(opt)
    if (not self:IsCanEdit()) then return end

    -- 获取编辑器元素
    local editor = self:GetEditorElement();
    -- 清空旧编辑元素
    editor:ClearChildElement();
    -- 获取编辑元素
    local fieldEditElement = self:GetFieldEditElement(editor);
    -- 不存在退出
    if (not fieldEditElement) then return end
    -- 添加编辑元素
    editor:InsertChildElement(fieldEditElement);
    -- 设置元素编辑状态
    self:SetEdit(true);
    -- 更新布局
    self:UpdateEditAreaSize();
    -- 显示编辑
    editor:SetVisible(true);
    -- 全选
    if (self:GetFieldEditType() == "input") then fieldEditElement:handleSelectAll() end
end

function BlockInputField:EndEdit()
    self:SetEdit(false);

    local editor = self:GetEditorElement();
    editor:SetVisible(false);

    self:GetTopBlock():UpdateLayout();
end

function BlockInputField:OnBeginEdit()
    local editElement = self:GetEditElement();
    if (editElement) then editElement:FocusIn() end
end

function BlockInputField:OnEndEdit()
    local editElement = self:GetEditElement();
    if (editElement) then editElement:FocusOut() end
end

function BlockInputField:OnFocusIn()
    self:BeginEdit();
    self:OnBeginEdit();
end

function BlockInputField:OnFocusOut()
    self:EndEdit();
    self:OnEndEdit();
end

function BlockInputField:GetLanguage()
    return self:GetBlock():GetBlockly():GetLanguage();
end

function BlockInputField:GetFieldValue()
    return self:GetValue();
end

function BlockInputField:SetFieldValue(value)
    local validator = self:GetValidator();
    if (type(validator) == "function") then value = validator(value) end
    if (type(validator) == "string" and type(Validator[validator]) == "function") then value = (Validator[validator])(value) end
    self:SetValue(value);
end