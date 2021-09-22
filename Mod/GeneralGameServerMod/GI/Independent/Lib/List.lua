--[[
Title: List
Author(s):  wxa
Date: 2021-06-01
Desc: List
use the lib:
------------------------------------------------------------
local List = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/List.lua");
------------------------------------------------------------
]]

local __list_map__ = {};

function list_create(name)
    __list_map__[name] = __list_map__[name] or {};
end

function list_clear(name)
    __list_map__[name] = {};
end

function list_delete(name)
    __list_map__[name] = nil;
end

function list_get(name)
    return type(name) == "table" and name or __list_map__[name];
end

function list_is_exist(name)
    return __list_map__[name] ~= nil;
end

function list_remove_item_by_index(name, index)
    local list = list_get(name);
    return list and table.remove(list, index);
end

function list_get_item_by_index(name, index)
    local list = list_get(name);
    return list and list[index];
end

function list_get_index_by_item(name, item)
    local list = list_get(name);
    if (not list) then return 0 end 
    for index, list_item in ipairs(list) do
        if (list_item == item) then return index end 
    end
    return 0;
end

function list_is_contain_item(name, item)
    return list_get_index_by_item(name, item) ~= 0;    
end

function list_length(name)
    local list = list_get(name);
    return list and #list or 0;
end

function list_insert(name, item)
    local list = list_get(name);
    return list and table.insert(list, #list + 1, item);
end

function list_insert_at(name, index, item)
    local list = list_get(name);
    return list and table.insert(list, index or (#list + 1), item);
end

function list_set_item_by_index(name, index, item)
    local list = list_get(name);
    if (not list) then return end 
    list[index] = item;
end

local __object_map__ = {};

function object_create(name)
    __object_map__[name] = __object_map__[name] or {};
end

function object_clear(name)
    __object_map__[name] = {};
end

function object_delete(name)
    __object_map__[name] = nil;
end

function object_get(name)
    return type(name) == "table" and name or __object_map__[name];
end

function object_get_by_key(name, key)
    local object = object_get(name);
    return object and object[key];
end

function object_set_by_key(name, key, val)
    local object = object_get(name);
    if (object) then object[key] = val end 
end