--[[
Title: main
Author(s):  wxa
Date: 2021-06-01
Desc: 入口文件
use the lib:
]]

-- require("@/npc.lua");
require("%gi%/App/sunzibingfa/npc.lua");

local Level = require("Level");

Emit("UnloadLevel");
Level:SetLevelName("_level2")

-- Level:LoadMap();
Level:UnloadMap();
Level:Edit();

-- cmd(format("/goto %s %s %s", 10093,11,10069));
-- Level:Export();
-- print(Level:GetCenterPoint());

-- ShowBlocklyCodeEditor({
--     run = function(code)
--     end,
--     restart = function()
--     end
-- });

function clear()
    cmd("/mode edit");
    cmd("/home");
    -- Level:UnloadMap();
end
