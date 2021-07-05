
--[[
Title: DataBase
Author(s):  wxa
Date: 2021-06-30
Desc: MySql
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/MySql/DataBase.lua");
------------------------------------------------------------
]]

local Query = NPL.load("./Query.lua");
local Table = NPL.load("./Table.lua");

local DataBase = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

DataBase:Property("DataBaseName");
DataBase:Property("Connection");

function DataBase:ctor()
    self.__tables__ = {};
end

function DataBase:Init(connection, db_name)
    self:SetConnection(connection);
    self:SetDataBaseName(db_name);

    -- 加载表
    self:LoadTables();

    return self;
end

function DataBase:Execute(sql)
    print("Execute SQL:", sql);
    return assert(self:GetConnection():execute(sql));
end

function DataBase:Close()
    if (not self:GetConnection()) then return end
    
    self:GetConnection():close();
    self:SetConnection(nil);
end
    
function DataBase:LoadTable(tableName)
    self.__tables__[tableName] = Table:new():Init(self, tableName);
end

function DataBase:LoadTables()
    local cursor = self:Execute("show tables");
    local row = cursor:fetch(nil, "a");
    while(row) do
        self:LoadTable(row);
        row = cursor:fetch(nil, "a");
    end
    cursor:close();
    return ;
end

function DataBase:GetTable(name)
    return self.__tables__[name];
end

function DataBase:NewQuery()
    return Query:new():Init(self);
end
