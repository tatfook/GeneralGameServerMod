--[[
Title: Input
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Input = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Input.lua");
-------------------------------------------------------
]]

local Input = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Input:Property("Block");                    -- 所属块
Input:Property("Type");                     -- statement value dummy

function Input:ctor()
    self.fields = {};
end

function Input:Init(block)
    self:SetBlock(block);

    return self;
end