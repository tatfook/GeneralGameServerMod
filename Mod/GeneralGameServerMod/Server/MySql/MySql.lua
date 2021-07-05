--[[
Title: MySql
Author(s):  wxa
Date: 2021-06-30
Desc: MySql
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/MySql/MySql.lua");
------------------------------------------------------------
]]
local mysql = require("luasql.mysql");

local Expr = NPL.load("./Expr.lua", IsDevEnv);
local Query = NPL.load("./Query.lua", IsDevEnv);
local Column = NPL.load("./Column.lua", IsDevEnv);
local Table = NPL.load("./Table.lua", IsDevEnv);
local DataBase = NPL.load("./DataBase.lua", IsDevEnv);

local MySql = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

MySql:Property("DataBaseName");

function MySql:ctor()
    self.__databases__ = {};
end

function MySql:Init(db_user, db_password, db_host, db_port)
    self.__username__, self.__password__, self.__host__, self.__port__ = db_user, db_password, db_host or "localhost", db_port or 3306;
	self.__env__ = assert(mysql.mysql())
    return self;
end

function MySql:GetDataBase(db_name)
    if (self.__databases__[db_name]) then return self.__databases__[db_name] end

	local connection= assert(self.__env__:connect(db_name, self.__username__, self.__password__, self.__host__, self.__port__))
    local db = DataBase:new():Init(connection, db_name);
    self.__databases__[db_name] = db;

    return db;
end

function MySql:Close()
    if (not self.__env__) then return end

    -- 关闭所有数据库
    for _, db in pairs(self.__databases__) do
        db:Close();
    end

    self.__env__:close();
end

MySql:InitSingleton();


function MySql.Test()
    MySql:Init("root", "wuxiangan");
    local __ggs_db__ = MySql:GetDataBase("ggs");

--     __ggs_db__:Execute([[
-- CREATE TABLE IF NOT EXISTS `user`(
--    `user_id` BIGINT AUTO_INCREMENT,
--    `username` VARCHAR(64) NOT NULL,
--    `password` VARCHAR(64) NOT NULL,
--    `register_at` DATE,
--    PRIMARY KEY ( `user_id` )
-- )ENGINE=InnoDB DEFAULT CHARSET=utf8;
--     ]]);

--     __ggs_db__:LoadTable("user");

    local UserTable = __ggs_db__:GetTable("user");
--     -- UserTable:Insert({username = "wxa'test", password = "123456"});
--     UserTable:BatchInsert({{username = "wxa'test", password = "123456"}, {username = "wxatest1", password = "123456"}});

    -- 查询
    local query = __ggs_db__:NewQuery();
    -- echo(query:Select():From("user"):Execute(), true);
    -- echo(query:Select("username as name", "password"):From("user u"):Where(query:Expr("u", "username", "eq", "wxatest")):Execute(), true);

    -- echo(UserTable:FindOne({username = "wxatest"}))
    echo(UserTable:Find({username = {"wxatest", "wxatest1"}}), true)
end


