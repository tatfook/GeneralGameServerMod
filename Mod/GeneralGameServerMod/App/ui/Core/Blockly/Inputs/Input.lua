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
local Connection = NPL.load("../Connection.lua", IsDevEnv);

local Input = commonlib.inherit(BlockInputField, NPL.export());

Input:Property("InputBlock");               -- 输入块

function Input:ctor()
end

function Input:Init(block, opt)
    Input._super.Init(self, block, opt);
    
    self.inputConnection = Connection:new():Init(block);

    return self;
end

function Input:GetInputBlock()
    return self.inputConnection:GetConnectionBlock();
end

function Input:IsInput()
    return true;
end

function Input:GetInputCode()
    if (not self:GetInputBlock()) then return nil end

    return self:GetInputBlock():GetBlockCode(self:GetBlock():GetLanguage());
end
