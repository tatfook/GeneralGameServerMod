
--[[
Title: G
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Blockly = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Blockly.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");
local Element = NPL.load("../Window/Element.lua", IsDevEnv);
local LuaBlocks = NPL.load("./Blocks/Lua.lua", IsDevEnv);

local Block = NPL.load("./Block.lua", IsDevEnv);
local BlocklyEditor = NPL.load("./BlocklyEditor.lua", IsDevEnv);
local Blockly = commonlib.inherit(Element, NPL.export());

Blockly:Property("Name", "Blockly");  
Blockly:Property("EditorElement");            -- 编辑元素 用户输入
Blockly:Property("MouseCaptureUI");           -- 鼠标捕获UI
Blockly:Property("FocusUI");                  -- 聚焦UI

function Blockly:ctor()
    -- local block1 = Block:new():Init(self, {
    --     message0 = "测试 %1 你好 %2",
    --     arg0 = {
    --         {
    --             name = "x",
    --             type = "field_input",
    --             text = "输入框"
    --         }, 
    --         {
    --             name = "y",
    --             type = "input_value",
    --             text = "输入框",
    --             shadow = {
    --                 type = "",
    --                 value = "",
    --             }
    --         }
    --     }, 
        
    --     color = StyleColor.ConvertTo16("rgb(37,175,244)"),
    --     -- output = true,
    --     previousStatement = true,
    --     nextStatement = true,
    --     ToNPL = function(self)
    --         return string.format('BecomeTeacherNPC("%s")\n', self:getFieldValue('npcType'));
    --     end,
    -- });
    -- local block2 = Block:new():Init(self, {
    --     message0 = "测试你好",
    --     arg0 = {
    --         {
    --             name = "x",
    --             type = "field_input",
    --             text = ""
    --         }
    --     }, 
    --     message1 = "%1",
    --     arg1 = {
    --         {
    --             name = "code",
    --             type = "input_statement",
    --         }
    --     },
    --     color = StyleColor.ConvertTo16("rgb(160,110,254)"),
    --     -- output = true,
    --     previousStatement = true,
    --     nextStatement = true,
    -- });
    -- local block3 = Block:new():Init(self, {
    --     message0 = "值块",
    --     color = StyleColor.ConvertTo16("rgb(160,110,254)"),
    --     output = true,
    -- });
    -- local block4 = Block:new():Init(self, {
    --     message0 = "测试 %1 你好 %2",
    --     arg0 = {
    --         {
    --             name = "x",
    --             type = "field_select",
    --             text = "下拉列表"
    --         }, 
    --         {
    --             name = "x",
    --             type = "input_value",
    --             text = "输入框",
    --             shadow = {
    --                 type = "",
    --                 value = "",
    --             }
    --         }
    --     }, 
        
    --     color = StyleColor.ConvertTo16("rgb(37,175,244)"),
    --     -- output = true,
    --     previousStatement = true,
    --     nextStatement = true,
    -- });
    -- block1:SetLeftTopUnitCount(5,5);
    -- block2:SetLeftTopUnitCount(20,20);
    -- block3:SetLeftTopUnitCount(40, 40);
    -- block4:SetLeftTopUnitCount(60, 40);
    -- self.blocks = {block1, block2, block3, block4};
    -- self.blocks = {block1, block3};
    self.offsetX = 0;
    self.offsetY = 0;
    self.blocks = {};
    for index, blockOption in ipairs(LuaBlocks) do
        local block = Block:new():Init(self, blockOption);
        block:SetLeftTopUnitCount(5, (index - 1) * 10 + 5);
        table.insert(self.blocks, block);
    end
end

function Blockly:Init(xmlNode, window, parent)
    Blockly._super.Init(self, xmlNode, window, parent);
    local blocklyEditor = BlocklyEditor:new():Init({
        name = "BlocklyEditor",
        attr = {
            style = "position: absolute; left: 0px; top: 0px; width: 0px; height: 0px; overflow: hidden; background-color: #ff0000;",
        }
    }, window, self)
    table.insert(self.childrens, blocklyEditor);
    self:SetEditorElement(blocklyEditor);
    return self;
end

-- 获取所有顶层块
function Blockly:GetBlocks()
    return self.blocks;
end

-- 获取块索引
function Blockly:GetBlockIndex(block)
    for index, _block in ipairs(self.blocks) do
        if (_block == block) then return index end
    end
    return ;
end

-- 移除块
function Blockly:AddBlock(block)
    local index = self:GetBlockIndex(block);
    if (not index) then 
        return table.insert(self.blocks, block);
    end
    
    local tail = #self.blocks;
    self.blocks[tail], self.blocks[index] = self.blocks[index], self.blocks[tail];  -- 放置尾部
end

-- 添加块
function Blockly:RemoveBlock(block)
    local index = self:GetBlockIndex(block);
    if (not index) then return end
    table.remove(self.blocks, index);
end

-- 渲染Blockly
function Blockly:RenderContent(painter)
    local x, y, w, h = self:GetContentGeometry();
    painter:Translate(x, y);

    for _, block in ipairs(self.blocks) do
        block:Render(painter);
        painter:Flush();
    end

    painter:Translate(-x, -y);
end

-- 布局Blockly
function Blockly:OnAfterUpdateLayout()
    for _, block in ipairs(self.blocks) do
        block:UpdateLayout();
    end
end

-- 捕获鼠标
function Blockly:CaptureMouse(ui)
    self:SetMouseCaptureUI(ui);
    return Blockly._super.CaptureMouse(self);
end

-- 释放鼠标
function Blockly:ReleaseMouseCapture()
    self:SetMouseCaptureUI(nil);
	return Blockly._super.ReleaseMouseCapture(self);
end

-- function Blockly:GetMouseEvent(event)
--     return {
--     }
-- end

-- 鼠标按下事件
function Blockly:OnMouseDown(event)
    if (event.target ~= self) then return end

    local x, y = self:GetRelPoint(event.x, event.y);
    local ui = self:GetMouseUI(self.offsetX + x, self.offsetY + y, event);
    
    -- 失去焦点
    local focusUI = self:GetFocusUI();
    if (focusUI ~= ui and focusUI) then 
        focusUI:OnFocusOut();
        self:SetFocusUI(nil);
    end

    if (not ui) then return end
    ui:OnMouseDown(event);
end

-- 鼠标移动事件
function Blockly:OnMouseMove(event)
    if (event.target ~= self) then return end
    
    local x, y = self:GetRelPoint(event.x, event.y);
    local ui = self:GetMouseUI(self.offsetX + x, self.offsetY + y, event);
    if (not ui) then return end
    ui:OnMouseMove(event);
end

-- 鼠标抬起事件
function Blockly:OnMouseUp(event)
    if (event.target ~= self) then return end
    
    local x, y = self:GetRelPoint(event.x, event.y);
    local ui = self:GetMouseUI(self.offsetX + x, self.offsetY + y, event);
    if (not ui) then return end
    ui:OnMouseUp(event);

    -- 获取焦点
    local focusUI = self:GetFocusUI();
    if (focusUI ~= ui) then 
        if (focusUI) then focusUI:OnFocusOut() end
        ui:OnFocusIn();
        self:SetFocusUI(ui);
    end
end

-- 获取鼠标元素
function Blockly:GetMouseUI(x, y, event)
    local ui = self:GetMouseCaptureUI();
    if (ui) then return ui end

    local size = #self.blocks;
    for i = size, 1, -1 do
        local block = self.blocks[i];
        ui = block:GetMouseUI(x, y, event);
        if (ui) then return ui end
    end

    return nil;
end

-- 获取代码
function Blockly:GetCode(language)
    local code = "";
    for _, block in ipairs(self.blocks) do
        code = code .. block:GetBlockCode(language) .. "\n";
    end
    return code;
end
