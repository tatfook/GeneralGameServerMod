
local Level = require("Level");


Level:LoadMap();
Level:Edit();

-- Level:Export();
-- print(Level:GetCenterPoint());

function clear()
    cmd("/mode edit");
    cmd("/home");
    Level:UnloadMap();
end