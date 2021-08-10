--[[
Title: main
Author(s):  wxa
Date: 2021-06-01
Desc: 入口文件
use the lib:
]]

-- require("@/npc.lua");
local Level = require("%gi%/App/sunzibingfa/Level/Level.lua");
local Level1 = require("%gi%/App/sunzibingfa/Level/Level1.lua");
local Level1_1 = require("%gi%/App/sunzibingfa/Level/Level1_1.lua");
local Level2 = require("%gi%/App/sunzibingfa/Level/Level2.lua");

Emit("UnloadLevel");

-- Level1:EditOld("level1")
-- Level1:Edit("level1")
-- Level1:Export();
-- Level1:Import();

-- Level1_1:EditOld()
-- Level1_1:Edit();
-- Level1_1:Export();
-- Level1_1:Import();

-- Level2:EditOld()
-- Level2:Edit();
-- Level2:Export();
Level2:Import();

function clear()
    cmd("/mode edit");
    cmd("/home");
    -- Level:UnloadMap();
end
