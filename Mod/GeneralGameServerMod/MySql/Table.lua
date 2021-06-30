--[[
Title: Table
Author(s):  wxa
Date: 2021-06-30
Desc: MySql
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/MySql/Table.lua");
------------------------------------------------------------
]]
local Expr = NPL.load("./Expr.lua");
local Column = NPL.load("./Column.lua");

local Table = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Table:Property("DataBase");
Table:Property("TableName");

function Table:ctor()
    self.__columns__ = {};
    self.__exprs__ = {};
end

function Table:Init(db, tableName)
    self:SetDataBase(db);
    self:SetTableName(tableName);

    local cursor = self:Execute(string.format([[select * from information_schema.columns where table_schema ='%s' and table_name = '%s']], self:GetDataBase():GetDataBaseName(), self:GetTableName()));
    local row = cursor:fetch({}, "a");
    while (row) do
        local column = Column:new():Init(self, row);
        local colname = column:GetName();
        self.__columns__[colname] = column;
        self.__exprs__[colname] = Expr:new():Init(column);

        row = cursor:fetch({}, "a");
    end
    cursor:close();

    return self;
end

function Table:Execute(sql)
    return self:GetDataBase():Execute(sql);
end

function Table:GetColumn(name)
    return self.__columns__[name];
end

function Table:GetExpr(colname)
    return self.__exprs__[colname];
end

function Table:Insert(data)
    local columns, values = "", "";

    for key, value in pairs(data) do
        local column = self:GetColumn(key);
        if (type(key) == "string" and column) then
            columns = columns .. (columns == "" and "" or ",") .. key;
            values = values .. (values == "" and "" or ",") .. column:ToValue(value);
        end
    end

    if (columns == "") then return false end

    local sql = string.format("insert into `%s` (%s) values(%s)", self:GetTableName(), columns, values);
    local result = self:Execute(sql);

    return result == 1;
end

function Table:BatchInsert(list)
    local columns, values, column, value, cols = "", "", nil, nil, {};
    for colname, col in pairs(self.__columns__) do
        columns = columns .. (columns == "" and "" or ",") .. colname;
        cols[#cols + 1] = col;
    end
    for _, data in ipairs(list) do
        value = "";
        for _, col in ipairs(cols) do
            value = value .. (value == "" and "" or ",") .. col:ToValue(data[col:GetName()]);
        end
        values = values .. (values == "" and "" or ",") .. "(" .. value .. ")";
    end
    local sql = string.format("insert into `%s` (%s) values %s", self:GetTableName(), columns, values);
    local result = self:Execute(sql);
    return result == #list;
end

function Table:Update(data, where)

end

function Table:Delete(where)
end

function Table:Find(where)
end

-- Table:NewQuery():Select():From():Where():OrWhere():AndWhere();