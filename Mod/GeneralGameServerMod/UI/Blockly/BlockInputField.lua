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

local Const = NPL.load("./Const.lua", IsDevEnv);
local BlockInputField = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local UnitSize = Const.UnitSize;

BlockInputField:Property("ClassName", "BlockInputField");
BlockInputField:Property("Name");
BlockInputField:Property("Type");
BlockInputField:Property("Block");
BlockInputField:Property("Option");
BlockInputField:Property("Color", "#ffffff");                    -- 颜色
BlockInputField:Property("BackgroundColor", "#ffffff");          -- 背景颜色
BlockInputField:Property("Edit", false, "IsEdit");               -- 是否在编辑
BlockInputField:Property("Value", "");                           -- 值
BlockInputField:Property("Label", "");                           -- 显示值

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

    -- 解析颜色值
    self:SetColor(option.color);

    return self;
end

-- 拷贝
-- function BlockInputField:Clone()
--     local clone = self:new():Init(self:GetBlock(), self:GetOption());
--     for key, val in pairs(self) do
--         local valtype = type(val);
--         if (valtype ~= "function" and valtype ~= "table" and rawget(self, key) ~= nil) then
--             clone[key] = val;
--         end

--         if (valtype == "table" and type(val.Clone) == "function") then
--             clone[key] = val:Clone() or val;
--         end
--     end

--     return clone;
-- end

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
    self.totalWidth, self.totalHeight = widthUnitCount * UnitSize, heightUnitCount * UnitSize;
end

function BlockInputField:GetTotalWidthHeightUnitCount()
    return self.totalWidthUnitCount, self.totalHeightUnitCount;
end

function BlockInputField:SetMaxWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    self.maxWidthUnitCount, self.maxHeightUnitCount = widthUnitCount or self.maxWidthUnitCount or self.widthUnitCount, heightUnitCount or self.maxHeightUnitCount or self.heightUnitCount;
    self.maxWidth, self.maxHeight = self.maxWidthUnitCount * UnitSize, self.maxHeightUnitCount * UnitSize;
end

function BlockInputField:UpdateWidthHeightUnitCount()
    return 0, 0, 0, 0, 0, 0;  -- 最大宽高, 元素宽高, 元素总宽高
end

function BlockInputField:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    widthUnitCount, heightUnitCount = widthUnitCount or self.widthUnitCount or 0, heightUnitCount or self.heightUnitCount or 0;
    if (self.widthUnitCount == widthUnitCount and self.heightUnitCount == heightUnitCount) then return end

    self.widthUnitCount, self.heightUnitCount = widthUnitCount, heightUnitCount;
    self.width, self.height = widthUnitCount * UnitSize, heightUnitCount * UnitSize;

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
    if (self.leftUnitCount == leftUnitCount and self.topUnitCount == topUnitCount) then return end

    self.leftUnitCount, self.topUnitCount = leftUnitCount, topUnitCount;
    self.left, self.top = leftUnitCount * UnitSize, topUnitCount * UnitSize;
    
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

function BlockInputField:GetTopBlock()
    local prevBlock, nextBlock = self:GetPrevBlock(), self:GetBlock();
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

function BlockInputField:GetFieldEditElement(parentElement)
end

function BlockInputField:GetMinEditFieldWidthUnitCount()
    return Const.MinEditFieldWidthUnitCount;
end

function BlockInputField:BeginEdit(opt)
    if (not self:IsCanEdit()) then return end

    local blockly = self:GetBlock():GetBlockly();
    local editor = self:GetEditorElement();
    editor:ClearChildElement();
    editor:SetStyleValue("left", self.left + (self.maxWidth - self.width) / 2 + blockly.offsetX);
    editor:SetStyleValue("top", self.top + (self.maxHeight - self.height) / 2 + blockly.offsetY);
    editor:SetStyleValue("width", math.max(self.width, self:GetMinEditFieldWidthUnitCount() * Const.UnitSize));
    editor:SetStyleValue("height", self.height);
    local fieldEditElement = self:GetFieldEditElement(editor);
    if (not fieldEditElement) then return end
    editor:InsertChildElement(fieldEditElement);
    editor:UpdateLayout();
    editor:SetVisible(true);
    fieldEditElement:OnFocusIn();
    self:SetEdit(true);
    self:GetTopBlock():UpdateLayout();
end

function BlockInputField:EndEdit()
    self:SetEdit(false);

    local editor = self:GetEditorElement();
    editor:SetVisible(false);

    self:GetTopBlock():UpdateLayout();
end

function BlockInputField:OnFocusIn()
    self:BeginEdit();
end

function BlockInputField:OnFocusOut()
    self:EndEdit();
end