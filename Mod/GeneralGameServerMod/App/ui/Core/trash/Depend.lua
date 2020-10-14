--[[
Title: Depend
Author(s): wxa
Date: 2020/6/30
Desc: 组件指令解析器
use the lib:
-------------------------------------------------------
local Depend = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Vue/Depend.lua");
-------------------------------------------------------
]]

local Depend = NPL.export();


local AllDependItems = {};
local DependItems = {}
local Objects = {};

function Depend.Begin()
    DependItems = {}
end

function Depend.AddItem(key)
    DependItems[key] = true;
end

function Depend.End()
    local list = {};
    for key, val in pairs(DependItems) do
        table.insert(list, key);
    end
    return list;
end

function Depend.Watch(dependItems, owner, func)
    if (type(dependItems) == "string") then dependItems = {dependItems} end
    if (type(func) ~= "function") then return end
    if (not Objects[owner]) then Objects[owner] = commonlib.UnorderedArraySet:new() end
    Objects[owner]:add(func);

    for i = 1, #dependItems do
        local dependItem = dependItems[i];
        if (not AllDependItems[dependItem]) then AllDependItems[dependItem] = commonlib.UnorderedArraySet:new() end
        AllDependItems[dependItem]:add(func);
    end
end

function Depend.UnWatch(dependItems, owner, func)
    if (type(dependItems) == "string") then dependItems = {dependItems} end
    if (not dependItems and not owner and not func) then Depend.Clear() end
    local function ClearItem(dependItem, owner, func)
        local list = AllDependItems[dependItem];
        if (not list) then return end
        if (func) then return list:removeByValue(func) end
        local object = Objects[owner];
        if (not object) then return end
        for i = 1, #object do
            list:removeByValue(object[i]);
        end
    end
    if (dependItems) then
        for _, key in ipairs(dependItems) do
            ClearItem(key);
        end
    else
        for key, val in pairs(AllDependItems) do
            ClearItem(key);
        end
    end
end

function Depend.Notify(dependItem, newVal, oldVal)
    local funcs = AllDependItems[dependItem];
    if (not funcs) then return end
    for i = 1, #funcs do
        (funcs[i])(newVal, oldVal);
    end
end

function Depend.GetWatch(dependItem)
    return AllDependItems[dependItem];
end

function Depend.Clear()
    AllDependItems = {}
end

