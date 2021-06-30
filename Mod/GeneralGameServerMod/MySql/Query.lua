--[[
Title: Query
Author(s):  wxa
Date: 2021-06-30
Desc: Query
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/MySql/Query.lua");
------------------------------------------------------------
]]

local Expr = NPL.load("./Expr.lua");

local Query = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Query:Property("DataBase");

local __select__ = select;
local OP = Expr.OP;

local function Concat(delimiter, ...)
    local n = select("#", ...);
    local args, arg = "", "";

    delimiter = delimiter or " ";

    for i = 1, n do
        arg = __select__(i, ...);
        args = args .. (args == "" and "" or delimiter) .. arg;
    end

    return args;
end

function Query:ctor()
    self.__sql__ = "";
    self.__action__ = nil;  -- select update delete replace
    self.__select__ = "*";
    self.__update__ = "";
    self.__delete__ = "";
    self.__where__ = "";
    self.__tables__ = {};
    self.__columns__ = {};
end

function Query:Init(database)
    self:SetDataBase(database);
    return self;
end

function Query:PraseTableName(action, ...)
    action = action or self.__action__;

    local sql = "";
    local n = __select__("#", ...);
    for i = 1, n do 
        local arg = __select__(i, ...);
        local tablename, aliasname = string.match(arg, "^([%w_]+).-([%w_]*)$");
        local __table__ = self:GetDataBase():GetTable(tablename);

        aliasname = aliasname == "" and tablename or aliasname;
        
        self.__tables__[tablename] = __table__;
        self.__tables__[aliasname or tablename] = __table__;

        sql = sql .. (sql == "" and "" or ", ") .. "`".. tablename .. "`";
        if (aliasname and aliasname ~= tablename) then
            if (self.__action__ ~= "__delete__" or action ~= "__from__") then
                sql = sql .. " AS `" .. aliasname .. "`";
            end
        end    
    end
    
    return sql;
end

function Query:ParseColumnName(...)
    local n = __select__("#", ...);
    local sql = "";
    for i = 1, n do 
        local arg = __select__(i, ...);
        local tablename, colname, aliasname = string.match(arg, "^([%w_]+)%.?([%w_]*).-([%w_]*)$");
        tablename = tablename and tablename ~= "" and tablename or nil;
        colname = colname and colname ~= "" and colname or nil;
        aliasname = aliasname and aliasname ~= "" and aliasname or nil;
        if (not colname) then colname, tablename = tablename, nil end
        if (tablename) then self.__tables__[tablename] = assert(self:GetDataBase():GetTable(tablename)) end
        local column = self:GetColumn(colname) or colname;
        self.__columns__[colname] = column;
        self.__columns__[aliasname or colname] = column;

        sql = sql .. (sql == "" and "" or ", ") .. self:ColName(tablename, colname, aliasname);
    end
    return sql;
end

function Query:Select(...)
    if (self.__action__) then return self end 
    
    self.__action__ = "__select__";
    self.__select__ = self:ParseColumnName(...);
    if (self.__select__ == "") then self.__select__ = "*" end
    
    return self;
end

function Query:Update(...)
    if (self.__action__) then return self end 
    
    self.__action__ = "__update__";
    self.__update__ = self:PraseTableName(nil, ...);
      
    return self;
end

function Query:Delete(...)
    if (self.__action__) then return self end 
    
    self.__action__ = "__delete__";
    self.__delete__ = self:PraseTableName(nil, ...);

    return self;
end

function Query:From(...)
    if (not self.__action__) then return self end 
    self.__from__ = self:PraseTableName("__from__", ...);

    return self;
end

function Query:Where(...)
    self.__where__ = string.format("(%s)", Concat(nil, ...));
    return self;
end

function Query:OrWhere(...)
    self.__where__ = self.__where__ .. " OR " .. string.format("(%s)", Concat(nil, ...));  
    return self;
end

function Query:AndWhere(...)
    self.__where__ = self.__where__ .. " And " .. string.format("(%s)", Concat(nil, ...));  
    return self;
end

function Query:GetExpr(tablename, colname)
    local t = assert(self.__tables__[tablename]);
    local expr = t:GetExpr(colname);
    expr:SetTableName(tablename);
    return expr;
end

function Query:Expr(tablename, colname, op, value)
    local expr = assert(self:GetExpr(tablename, colname));
    op = OP[string.lower(op)] or OP.op;
    return (expr[op])(expr, value);
end

function Query:OrExpr(tablename, colname, op, value)
    return " OR " .. self:Expr(colname, tablename, op, value);
end

function Query:AndExpr(tablename, colname, op, value)
    return " AND " .. self:Expr(colname, tablename, op, value);
end

function Query:ColName(tablename, colname, aliasname)
    tablename = tablename and tablename ~= "" and tablename or nil;
    aliasname = aliasname and aliasname ~= "" and aliasname or nil;
    if (tablename and aliasname) then return string.format("`%s`.`%s` AS `%s`", tablename, colname, aliasname) end 
    if (tablename and not aliasname) then return string.format("`%s`.`%s`", tablename, colname) end 
    if (not tablename and aliasname) then return string.format("`%s` AS `%s`", colname, aliasname) end 
    return string.format("`%s`", colname); 
end

function Query:Sql()
    local sql = nil;
    if (self.__where__ == "") then 
        sql = string.format([[select %s from %s]], self.__select__, self.__from__);
    else
        sql = string.format([[select %s from %s where %s]], self.__select__, self.__from__, self.__where__); 
    end 
    return sql;
end

function Query:SqlWhere()
    return self.__where__ == "" and "" or ("where " .. self.__where__);
end

function Query:GetColumn(colname)
    local column = self.__columns__[colname] or colname;

    if (type(column) == "table") then return end
    if (type(column) ~= "string") then return end

    for _, __table__ in pairs(self.__tables__) do
        local col = __table__:GetColumn(column);
        if (col) then return col end
    end
end

function Query:Execute()
    local cursor = self:GetDataBase():Execute(self:Sql());
    if (type(cursor) == "number") then return end
    
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
