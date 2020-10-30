
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

local Block = NPL.load("./Block.lua", IsDevEnv);

local Blockly = commonlib.inherit(Element, NPL.export());

Blockly:Property("Name", "Blockly");
Blockly:Property("UnitSize", 4);              -- 一个单元格4px  默认为4
Blockly:Property("SpaceUnitCount", 2);        -- 字段间间距
Blockly:Property("LineHeightUnitCount", 8);   -- 每行内容高为8

function Blockly:ctor()
    local block = Block:new():Init(self, {
        message0 = "测 %1 你好 %2",
        arg0 = {
            {
                name = "x",
                type = "field_input",
                text = "输入框"
            }, 
            {
                name = "x",
                type = "input_value",
                text = "输入框",
                shadow = {
                    type = "",
                    value = "",
                }
            }
        }, 
        color = StyleColor.ConvertTo16("rgb(37,175,244)"),
        -- output = true,
        previousStatement = true,
        nextStatement = true,
    });
    block.nextBlock = Block:new():Init(self, {
        message0 = "测试你好",
        arg0 = {
            {
                name = "x",
                type = "field_input",
                text = ""
            }
        }, 
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        -- output = true,
        previousStatement = true,
        nextStatement = true,
    });
    self.blocks = {block};
    self.offsetX = 0;
    self.offsetY = 0;
end

function Blockly:RenderContent(painter)
    local x, y, w, h = self:GetContentGeometry();
    painter:Translate(x, y);

    for _, block in ipairs(self.blocks) do
        block:Render(painter);
    end

    painter:Translate(-x, -y);
end

function Blockly:OnAfterUpdateLayout()
    for _, block in ipairs(self.blocks) do
        block:UpdateLayout();
    end
end

function Blockly:OnMouseDown(event)
    local x, y = self:GetRelPoint(event.x, event.y);
    local ui = self:GetMouseUI(self.offsetX + x, self.offsetY + y);
end

function Blockly:GetMouseUI(x, y)
    -- for _, block in ipairs(self.blocks) do
    --     block:GetMouseUI();
    -- end
end