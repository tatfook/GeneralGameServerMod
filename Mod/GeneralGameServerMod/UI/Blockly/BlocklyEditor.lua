--[[
Title: G
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local BlocklyEditor = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/BlocklyEditor.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Window/Element.lua", IsDevEnv);

local BlocklyEditor = commonlib.inherit(Element, NPL.export());

BlocklyEditor:Property("Name", "BlocklyEditor");
BlocklyEditor:Property("Blockly");

function BlocklyEditor:OnMouseDown(event)
    event:Accept();
end

function BlocklyEditor:OnMouseUp(event)
    event:Accept();
end

function BlocklyEditor:RenderStaticElement(painter, root)
    local scale = self:GetBlockly():GetScale();
    painter:Scale(scale, scale);
    BlocklyEditor._super.RenderStaticElement(self, painter, root);
    painter:Scale(1 / scale, 1 / scale);
end
