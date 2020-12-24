--[[
Title: Table
Author(s): wxa
Date: 2020/6/30
Desc: 表
use the lib:
-------------------------------------------------------
local Table = NPL.load("Mod/GeneralGameServerMod/UI/Vue/Table.lua");
-------------------------------------------------------
]]


local Table = NPL.export();
local Scope = NPL.load("./Scope.lua");

local TableConcat = table.concat;
local TableInsert = table.insert;
local TableRemove = table.remove;
local TableSort = table.sort;

function GetRealTable(table_, isRead)
    if (not Scope:__is_scope__(table_)) then return table_ end
    if (isRead) then
        table_:__call_index_callback__(table_, nil);
    else
        table_:__call_newindex_callback__(table_, nil);
    end
    return table_:__get_data__();
end

function Table.concat(table_, sep, start, end_)
    return TableConcat(GetRealTable(table_, true), sep, start, end_);
end

function Table.insert(table_, pos, value)
    table_ = GetRealTable(table_, false);   -- 获取真实表
    if (value == nil) then value, pos = pos, #table_ + 1 end 
    value = Scope.__get_val__(value);
    return TableInsert(table_, pos, value);
end

function Table.remove(table_, pos)
    table_ = GetRealTable(table_, false);   -- 获取真实表
    return TableRemove(table_, pos);
end

function Table.sort(table_, comp)
    table_ = GetRealTable(table_, false);   -- 获取真实表
    return TableSort(table_, comp);
end
