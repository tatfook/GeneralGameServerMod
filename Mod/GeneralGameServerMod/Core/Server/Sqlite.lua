--[[
Title: Sqlite
Author(s): wxa
Date: 2020/6/10
Desc: 世界数据持久化
use the lib: 
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/Sqlite.lua");
local Sqlite = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Sqlite");
-------------------------------------------------------
]]

NPL.load("(gl)script/sqlite/sqlite3.lua");
local Sqlite = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Sqlite"));

echo(sqlite3.open("test.db"));