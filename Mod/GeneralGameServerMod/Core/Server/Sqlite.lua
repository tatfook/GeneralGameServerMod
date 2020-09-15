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

local db = sqlite3.open("test.db");

db:exec([[
    drop table if exists Block;
    create table if not exists Block (
        blockIndex	  UNSIGNED INTEGER PRIMARY KEY,
        blockId       UNSIGNED INTEGER,
        blockFlag     INTEGER,
        areaIndex     UNSIGNED INTEGER,
        blockEntity   BLOB
    );
]]);

