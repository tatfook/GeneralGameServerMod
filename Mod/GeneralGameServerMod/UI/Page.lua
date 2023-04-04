--[[
Title: page
Author(s): wxa
Date: 2020/6/30
Desc: 显示UI入口文件
use the lib:
-------------------------------------------------------
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
-------------------------------------------------------
]]

local Page = NPL.load("script/ide/System/UI/Page.lua");
local PageWrapper = NPL.export();

for name, value in pairs(Page) do
    if(type(value) == "function") then
        PageWrapper[name] = value;
    end
end