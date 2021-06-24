--[[
Title: SandBox
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local SandBox = NPL.load("Mod/GeneralGameServerMod/GI/Independent/SandBox.lua");
------------------------------------------------------------
]]

local Independent = NPL.load("./Independent.lua", IsDevEnv);

local SandBox = commonlib.inherit(Independent, NPL.export());

function SandBox:ctor()
    self:SetErrorExit(false);
    self:SetShareMouseKeyBoard(true);
end

function SandBox:GetAPI()
	-- print("===========================SandBox:GetAPI==================================");
    self:Start();
    return self:GetCodeEnv();
end

SandBox:InitSingleton():Init();
