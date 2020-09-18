--[[
Title: Debug
Author(s): wxa
Date: 2020/6/30
Desc: 调试类
use the lib:
-------------------------------------------------------
local Load = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Load.lua");
-------------------------------------------------------
]]

local Load = NPL.export();

local LoadedMap = {};

function Load.Load(filename, uid, isDebug)

end

setmetatable(Load, {
    __call = function(self, ...)
        return self.Load(...);
    end
});