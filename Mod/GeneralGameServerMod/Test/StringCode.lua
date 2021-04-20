
local G = {};
local string_code = [[
    key = 1;
    type = "test";

    (function()
        _G.key = 3; 
    end)()

]]

local func, errmsg = loadstring(string_code);
if (not func) then 
    print("===============================Exec Code Error=================================", errmsg) 
    return "";
end

setfenv(func, G);
func();
echo(G, true)
echo(type)
-- local Timer = NPL.load("Mod/GeneralGameServerMod/Test/StringCode.lua", true);
