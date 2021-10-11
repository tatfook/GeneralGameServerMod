
--[[
Title: main
Author(s):  wxa
Date: 2021-06-01
Desc: 垃圾分类入口文件
use the lib:
]]

local Global = require("./Global.lua");

-- 开始游戏
-- Global:Start("online");     -- 联机模式
-- Global:Start("offline");    -- 单机模式

cmd("/mode game");

ShowWindow({

}, {
    url = "%gi%/App/lajifenlei/ui/start.html",
    height = 120,
    width = 300,
});

