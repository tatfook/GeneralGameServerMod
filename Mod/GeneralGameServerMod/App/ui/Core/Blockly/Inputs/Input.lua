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
local InputField = NPL.load("../InputField.lua", IsDevEnv);
local Input = commonlib.inherit(InputField, NPL.export());

Input:Property("InputBlock");               -- 输入块
Input:Property("Color");

function Input:ctor()
end

function Input:Init(block)
    Input._super.Init(self, block);
    
    return self;
end

function Input:Render(painter)
end
