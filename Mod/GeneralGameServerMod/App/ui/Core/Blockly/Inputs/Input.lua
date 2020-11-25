--[[
Title: Input
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Input = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Inputs/Input.lua");
-------------------------------------------------------
]]
local BlockInputField = NPL.load("../BlockInputField.lua", IsDevEnv);
local Input = commonlib.inherit(BlockInputField, NPL.export());

Input:Property("InputBlock");               -- 输入块

function Input:ctor()
end

function Input:Init(block)
    Input._super.Init(self, block);
    
    return self;
end

function Input:Render(painter)
end
