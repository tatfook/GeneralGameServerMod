--[[
Author: wxa
Date: 2020-10-26
Desc: 新手引导 Level
-----------------------------------------------
local Level = NPL.load("Mod/GeneralGameServerMod/Level/Level.lua");
local Level = Level_0:new():Init(tutorial);
-----------------------------------------------
]]

local Level = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Level:Property("Tutorial");

function Level:ctor()
end

function Level:Init(tutorial)
    self:SetTutorial(tutorial);
    return self;
end

function Level:GetCodeEnv()
    return self:GetTutorial():GetCodeEnv();
end

function Level:GetCodeBlock()
    return self:GetTutorial():GetCodeBlock();
end