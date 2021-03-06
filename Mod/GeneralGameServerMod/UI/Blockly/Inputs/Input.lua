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

function Input:GetBlockly()
    return self:GetBlock():GetBlockly();
end

function Input:GetInputBlock()
    return self.inputConnection:GetConnectionBlock();
end

function Input:IsInput()
    return true;
end

function Input:GetInputCode()
    if (not self:GetInputBlock()) then return self:GetValue() end

    return self:GetInputBlock():GetBlockCode();
end

function Input:GetNextBlock()
    return self:GetInputBlock();
end

function Input:GetFieldValue() 
    return self:GetValueAsString();
end

function Input:GetValueAsString()
    return self:GetInputCode();
end

-- 获取xmlNode
function Input:SaveToXmlNode()
    local xmlNode = {name = "Input", attr = {}};
    local attr = xmlNode.attr;
    
    attr.name = self:GetName();
    attr.label = self:GetLabel();
    attr.value = self:GetValue();

    local inputBlock = self:GetInputBlock();

    if (not inputBlock and attr.label == "" and attr.value == "") then return nil end
    
    if (inputBlock) then table.insert(xmlNode, inputBlock:SaveToXmlNode()) end

    return xmlNode;
end

function Input:LoadFromXmlNode(xmlNode)
    local attr = xmlNode.attr;

    self:SetLabel(attr.label);
    self:SetValue(attr.value);

    local inputBlockXmlNode = xmlNode[1];
    if (not inputBlockXmlNode) then return end
    local inputBlock = self:GetBlock():GetBlockly():GetBlockInstanceByXmlNode(inputBlockXmlNode);
    if (not inputBlock) then return end
    if (self:GetType() == "input_value") then
        self.inputConnection:Connection(inputBlock.outputConnection);
    else
        self.inputConnection:Connection(inputBlock.previousConnection);
    end
end