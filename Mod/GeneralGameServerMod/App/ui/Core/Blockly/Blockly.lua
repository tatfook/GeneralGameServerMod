
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

local Element = NPL.load("../Window/Element.lua", IsDevEnv);

local Block = NPL.load("./Block.lua", IsDevEnv);

local Blockly = commonlib.inherit(Element, NPL.export());

Blockly:Property("Name", "Blockly");
Blockly:Property("UnitSize", 4);

function Blockly:ctor()
    self.blocks = {Block:new():Init(self)};
end

function Blockly:OnRender(painter)
    local x, y, w, h = self:GetGeometry();
    painter:Translate(x, y);

    for _, block in ipairs(self.blocks) do
        block:Render(painter);
    end


    painter:Translate(-x, -y);
end
