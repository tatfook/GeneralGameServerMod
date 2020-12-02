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


function BlocklyEditor:OnMouseDown(event)
    event:accept();
end

function BlocklyEditor:OnMouseUp(event)
    event:accept();
end
