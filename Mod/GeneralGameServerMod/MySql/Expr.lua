--[[
Title: Expr
Author(s):  wxa
Date: 2021-06-30
Desc: Query
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/MySql/Expr.lua");
------------------------------------------------------------
]]

local Expr = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Expr:Property("Column");
Expr:Property("TableName");



function Expr:ctor()
    self.__sql__ = "";
end

function Expr:Init(column, tablename)
    self:SetColumn(column);
    self:SetTableName(tablename);
    return self;
end

function Expr:GetColumnName()
    local colname = self:GetColumn():GetName();
    local tablename = self:GetTableName();
    if (tablename) then return string.format("`%s`.`%s`", tablename, colname) end 
    return string.format("`%s`", colname);
end

function Expr:GetValue(value)
    return self:GetColumn():ToValue(value);
end

function Expr:Op(op, value)
    return string.format("%s %s %s ", self:GetColumnName(), op, value);
end

function Expr:Neq(value)
    return string.format("%s <> %s ", self:GetColumnName(), self:GetValue(value));
end

function Expr:Eq(value)
    return string.format("%s = %s ", self:GetColumnName(), self:GetValue(value));
end

function Expr:Lt(value)
    return string.format("%s < %s ", self:GetColumnName(), self:GetValue(value));
end

function Expr:Lte(value)
    return string.format("%s <= %s ", self:GetColumnName(), self:GetValue(value));
end

function Expr:Gt(value)
    return string.format("%s > %s ", self:GetColumnName(), self:GetValue(value));
end

function Expr:Gte(value)
    return string.format("%s >= %s ", self:GetColumnName(), self:GetValue(value));
end

function Expr:IsNull()
    return string.format("%s IS NULL ", self:GetColumnName());
end

function Expr:IsNotNull()
    return string.format("%s IS NOT NULL ", self:GetColumnName());
end

function Expr:Prod(value)
    return type(value) ~= "number" and "" or string.format("%s * %s", self:GetColumnName(), value);
end

function Expr:Diff(value)
    return type(value) ~= "number" and "" or string.format("%s - %s", self:GetColumnName(), value);
end

function Expr:Sum(value)
    return type(value) ~= "number" and "" or string.format("%s + %s", self:GetColumnName(), value);
end

function Expr:Quot(value)
    return type(value) ~= "number" and "" or string.format("%s / %s", self:GetColumnName(), value);
end

function Expr:Exists(query)
    return string.format("%s exists (%s) ", self:GetColumnName(), query);
end

local OP = {
    ["eq"] = "Eq",
    ["neq"] = "Neq",
    ["op"] = "Op",
    ["lt"] = "Lt",
    ["lte"] = "Lte",
    ["gt"] = "Gt",
    ["gte"] = "Gte",
    ["isnull"] = "IsNull",
    ["isnotnull"] = "IsNotNull",
    ["prod"] = "Prod",
    ["diff"] = "Diff",
    ["sum"] = "Sum",
    ["quot"] = "Quot",
    ["exists"] = "Exists",
}

Expr.OP = OP;

    -- // Example - $qb->expr()->all($qb2->getDql())
    -- public function all($subquery); // Returns Expr\Func instance

    -- // Example - $qb->expr()->some($qb2->getDql())
    -- public function some($subquery); // Returns Expr\Func instance

    -- // Example - $qb->expr()->any($qb2->getDql())
    -- public function any($subquery); // Returns Expr\Func instance

    -- // Example - $qb->expr()->not($qb->expr()->eq('u.id', '?1'))
    -- public function not($restriction); // Returns Expr\Func instance

    -- // Example - $qb->expr()->in('u.id', array(1, 2, 3))
    -- // Make sure that you do NOT use something similar to $qb->expr()->in('value', array('stringvalue')) as this will cause Doctrine to throw an Exception.
    -- // Instead, use $qb->expr()->in('value', array('?1')) and bind your parameter to ?1 (see section above)
    -- public function in($x, $y); // Returns Expr\Func instance

    -- // Example - $qb->expr()->notIn('u.id', '2')
    -- public function notIn($x, $y); // Returns Expr\Func instance

    -- // Example - $qb->expr()->like('u.firstname', $qb->expr()->literal('Gui%'))
    -- public function like($x, $y); // Returns Expr\Comparison instance

    -- // Example - $qb->expr()->notLike('u.firstname', $qb->expr()->literal('Gui%'))
    -- public function notLike($x, $y); // Returns Expr\Comparison instance

    -- // Example - $qb->expr()->between('u.id', '1', '10')
    -- public function between($val, $x, $y); // Returns Expr\Func


    --     // Example - $qb->expr()->trim('u.firstname')
    --     public function trim($x); // Returns Expr\Func
    
    --     // Example - $qb->expr()->concat('u.firstname', $qb->expr()->concat($qb->expr()->literal(' '), 'u.lastname'))
    --     public function concat($x, $y); // Returns Expr\Func
    
    --     // Example - $qb->expr()->substring('u.firstname', 0, 1)
    --     public function substring($x, $from, $len); // Returns Expr\Func
    
    --     // Example - $qb->expr()->lower('u.firstname')
    --     public function lower($x); // Returns Expr\Func
    
    --     // Example - $qb->expr()->upper('u.firstname')
    --     public function upper($x); // Returns Expr\Func
    
    --     // Example - $qb->expr()->length('u.firstname')
    --     public function length($x); // Returns Expr\Func
    
    --     // Example - $qb->expr()->avg('u.age')
    --     public function avg($x); // Returns Expr\Func
    
    --     // Example - $qb->expr()->max('u.age')
    --     public function max($x); // Returns Expr\Func
    
    --     // Example - $qb->expr()->min('u.age')
    --     public function min($x); // Returns Expr\Func
    
    --     // Example - $qb->expr()->abs('u.currentBalance')
    --     public function abs($x); // Returns Expr\Func
    
    --     // Example - $qb->expr()->sqrt('u.currentBalance')
    --     public function sqrt($x); // Returns Expr\Func
    
    --     // Example - $qb->expr()->mod('u.currentBalance', '10')
    --     public function mod($x); // Returns Expr\Func
    
    --     // Example - $qb->expr()->count('u.firstname')
    --     public function count($x); // Returns Expr\Func
    
    --     // Example - $qb->expr()->countDistinct('u.surname')
    --     public function countDistinct($x); // Returns Expr\Func