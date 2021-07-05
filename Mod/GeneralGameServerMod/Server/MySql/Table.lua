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
Table:Property("PageSize", 50);

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

function Table:IsExistColumn(colname)
    return self.__columns__[colname] ~= nil;
end

function Table:GetExpr(colname)
    local expr = self.__exprs__[colname];
    if (expr) then expr:SetTableName(nil) end
    return expr;
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

    local sql = string.format("INSERT INTO `%s` (%s) VALUES(%s)", self:GetTableName(), columns, values);
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
    local sql = string.format("INSERT INTO `%s` (%s) VALUES %s", self:GetTableName(), columns, values);
    local result = self:Execute(sql);
    return result == #list;
end

function Table:Update(data, where)
    local where = self:BuildWhere(where);
    local sql = string.format("UPDATE `%s`", self:GetTableName());
    local set_sql = "";
    local function add_expr(expr) set_sql = expr == nil and set_sql or (set_sql .. (set_sql == "" and "" or ", ") .. expr) end
    for key, value in pairs(data) do
        local expr = self:GetExpr(key);
        if (expr and type(value) ~= "table") then
            add_expr(expr:Eq(value));
        end
    end
    if (set_sql == "") then return 0 end
    sql = sql .. " SET " .. set_sql;
    if (where) then sql = sql .. " WHERE " .. where end
    return self:Execute(sql);
end

function Table:Delete(where)
    local where = self:BuildWhere(where);
    local sql = string.format("DELETE FROM `%s`", self:GetTableName());
    if (where) then sql = sql .. " WHERE " .. where end
    return self:Execute(sql);
end

function Table:Find(where, count)
    local where = self:BuildWhere(where);
    local sql = string.format("SELECT * FROM `%s`", self:GetTableName());
    if (where) then sql = sql .. " WHERE " .. where end
    count = count or self:GetPageSize();
    sql = sql .. " LIMIT " .. count;
    local cursor = self:Execute(sql);
    local list = {};
    local row = cursor:fetch({}, "a");
    while (row) do
        for key, value in pairs(row) do
            local column = self:GetColumn(key);
            row[key] = column and column:FromValue(value) or value;
        end
        table.insert(list, row);
        row = cursor:fetch({}, "a");
    end
    cursor:close();
    return list;
end

function Table:FindOne(where)
    return self:Find(where, 1)[1];
end

function Table:BuildWhere(where)
    local sql = "";
    local function add_and_expr(expr) sql = expr == nil and sql or (sql .. (sql == "" and "" or "and ") .. expr) end
    local function add_or_expr(expr) sql = expr == nil and sql or (sql .. (sql == "" and "" or "or ") .. expr) end

    if (type(where) ~= "table") then return nil end

    for key, value in pairs(where) do
        local expr = self:GetExpr(key);

        if (expr) then
            if (type(value) == "table") then
                if (#value > 0) then
                    add_and_expr(expr:In(value));
                else
                    for op, val in pairs(value) do
                        add_and_expr(expr:Op(op, val));
                    end
                end
            else
                add_and_expr(expr:Eq(value))
            end
        elseif (type(value) == "table" and (key == "or" or key == "and")) then
            for _, val in ipairs(value) do
                if (key == "and") then
                    add_and_expr(self:BuildWhere(val));
                else
                    add_or_expr(self:BuildWhere(val));
                end
            end
        end
    end
    return string.format("(%s)", sql);
end


-- Table:NewQuery():Select():From():Where():OrWhere():AndWhere();