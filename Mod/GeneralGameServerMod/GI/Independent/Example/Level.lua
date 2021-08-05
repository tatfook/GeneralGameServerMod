
local Level = require("Level");


Level:Edit("level");

-- Level:Export();
-- print(Level:GetCenterPoint());

function clear()
    cmd("/mode edit");
    cmd("/home");
    Level:UnloadMap();
end