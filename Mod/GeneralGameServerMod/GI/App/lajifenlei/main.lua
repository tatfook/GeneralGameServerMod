
--[[
Title: main
Author(s):  wxa
Date: 2021-06-01
Desc: 垃圾分类入口文件
use the lib:
]]

local Net = require("./Net.lua");
local Global = require("./Global.lua");

SetCamera(20, 55, -90);
SetCameraLookAtBlockPos(19221,12,19185);

_G.__main_player_trash__ = Global:CreateMainPlayerTrash(19221,12,19185);
__main_player_trash__:TurnLeft(90);

Global:RandomGarbage(50);

-- 联机模式执行此行
Net:Connect();