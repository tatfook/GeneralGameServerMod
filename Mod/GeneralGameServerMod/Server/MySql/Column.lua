--[[
Title: Column
Author(s):  wxa
Date: 2021-06-30
Desc: MySql
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/MySql/Column.lua");
------------------------------------------------------------
]]

local Column = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Column:Property("Table");
Column:Property("Name");
Column:Property("Type");
Column:Property("DataType");
Column:Property("DefaultValue");
Column:Property("MaxLength");
Column:Property("AllowNull", true, "IsAllowNull");
Column:Property("Comment");
Column:Property("OrdinalPosition");
Column:Property("PrimaryKey", false, "IsPrimaryKey");
function Column:ctor()
end

function Column:Init(t, col)
    self:SetTable(t);

    self:SetName(col["COLUMN_NAME"]);
    self:SetType(col["COLUMN_TYPE"]);
    self:SetDataType(string.lower(col["DATA_TYPE"]));
    self:SetDefaultValue(col["COLUMN_DEFAULT"]);
    self:SetMaxLength(tonumber(col["CHARACTER_MAXIMUM_LENGTH"] or ""));
    self:SetAllowNull(col["IS_NULLABLE"] == "YES");
    self:SetComment(col["COLUMN_COMMENT"]);
    self:SetOrdinalPosition(col["ORDINAL_POSITION"]);

    self:SetPrimaryKey(col["COLUMN_KEY"] == "PRI");
    return self;
end

function Column:IsNumberType()
    local datatype = self:GetDataType();
    return datatype == "bigint" or datatype == "int";
end

function Column:IsStringType()
    local datatype = self:GetDataType();
    return datatype == "varchar";
end

function Column:IsDateType()
    local datatype = self:GetDataType();
    return datatype == "date";
end

function Column:ToValue(value)
    value = value or self:GetDefaultValue();
    if (value == nil) then return "NULL" end
    if (self:IsNumberType()) then return value end
    return string.format("'%s'",string.gsub(value, "'", "\\'"));
end

function Column:FromValue(value)
    if (self:IsNumberType()) then return tonumber(value) end
    return value;
end

