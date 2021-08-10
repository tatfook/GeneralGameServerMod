--[[
Title: main
Author(s):  wxa
Date: 2021-06-01
Desc: 入口文件
use the lib:
]]

-- require("@/npc.lua");
local Level = require("%gi%/App/sunzibingfa/Level/Level.lua");
local Level1_1 = require("%gi%/App/sunzibingfa/Level/Level1_1.lua")

Emit("UnloadLevel");

-- Level:LoadMap();
-- Level:UnloadMap();
Level1_1:Edit();

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
