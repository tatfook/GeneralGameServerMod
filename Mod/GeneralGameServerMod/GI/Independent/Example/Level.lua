
local Level = require("Level");


Level:Edit();

function clear()
    cmd("/mode edit");
    cmd("/home");
    Level:UnloadMap();
end