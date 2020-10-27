--[[
Author: wxa
Date: 2020-10-26
Desc: 新手引导 Level
-----------------------------------------------
local Levels = NPL.load("Mod/GeneralGameServerMod/Level/Levels.lua");
-----------------------------------------------
]]

local Level_0 = NPL.load("./Level_0.lua", IsDevEnv);

local Levels = NPL.export();

local __levels__ = {
    ["Level_0"] = Level_0,
};

function Levels.GetLevel(level)
    return __levels__[level];
end