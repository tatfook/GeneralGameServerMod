
--[[
Title: App
Author(s):  wxa
Date: 2021-06-23
Desc: Http
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Http/App.lua");
------------------------------------------------------------
]]

local Http = NPL.load("Mod/GeneralGameServerMod/Http/Http.lua");

local App = commonlib.inherit(Http, NPL.export());

App:Get("/", function(ctx)
    ctx:Send("hello world")
end)

App:Get("/json", function(ctx)
    ctx:Send({key = "value"})
end)