--[[
Title: Global
Author(s):  wxa
Date: 2021-06-01
Desc: Global
use the lib:
]]

local Config = require("./Config.lua");
local Garbage = require("./Garbage.lua");
local Trash = require("./Trash.lua");

local Global = inherit(ToolBase, module());

Global:Property("MainPlayerTrash");          -- 主玩家垃圾桶对象
Global:Property("GarbageCount", 0);          -- 当前垃圾数量

local GarbagePosList = {};
local GarbageMap = {};

function Global:ctor()
    self.__trash_map__ = {};
    self.__garbage_pos_list = {};
    self.__garbage_map__ = {};
    self.__map_start_bx__, self.__map_start_by__, self.__map_start_bz__ = 19140, 12, 19140;
    self.__map_end_bx__, self.__map_end_by__, self.__map_end_bz__ = 19259, 13, 19259;
end

function Global:Init()
    for i = self.__map_start_bx__, self.__map_end_bx__ do
        for j = self.__map_start_by__, self.__map_end_by__ do
            for k = self.__map_start_bz__, self.__map_end_bz__ do
                local blockId = GetBlockId(i, j, k);
                if (IsObstructionBlock(i, j - 1, k) and (not blockId or blockId == 0)) then
                    table.insert(self.__garbage_pos_list, {bx = i, by = j, bz = k, blockIndex = ConvertToBlockIndex(i, j, k)});
                end
            end
        end
    end

    return self;
end

function Global:RandomGarbagePos()
    local size = #self.__garbage_pos_list;
    local index = math.random(1, size);
    local pos = self.__garbage_pos_list[index];

    -- 存在垃圾继续随机
    while(self.__garbage_map__[pos.blockIndex]) do
        index = math.random(1, size);
        pos = self.__garbage_pos_list[index];
    end

    return  pos;
end

function Global:RandomGarbage(count)
    count = count or 1;

    for i = 1, count do
        local pos = self:RandomGarbagePos();
        local garbage_config = Config.CATEGORY_LIST[math.random(#Config.CATEGORY_LIST)];
        local garbage = Garbage:new():Init({
            bx = pos.bx, by = pos.by, bz = pos.bz,
            category = garbage_config.category,
            assetfile = garbage_config.assetfile,
            name = garbage_config.name,
            label = garbage_config.label,
        });
        self.__garbage_map__[pos.blockIndex] = garbage;
    end
end

function Global:GetTrashCategoryCount()
    local category_count = {};
    for _, trash in pairs(self.__trash_map__) do
        local category = trash:GetCategory();
        category_count[category] = category_count[category] or 0;
        category_count[category] = category_count[category] + 1;
    end

    return category_count;
end

function Global:GetMinCountTrashCategory()
    local category_count = self:GetTrashCategoryCount();
    local min_count, min_category = nil, Config.GARBAGE_CATEGORY.QITA;
    for category, count in pairs(category_count) do
        if (not min_count or min_count < count) then
            min_count, min_category = count, category;
        end
    end
    return category;
end

-- 创建玩家对象
function Global:CreateMainPlayerTrash(bx, by, bz)
    local trash = Trash:new():Init({
        bx = bx, by = by, bz = bz,
        category = self:GetMinCountTrashCategory(),
        isMainPlayer = true,
    });

    self:SetMainPlayerTrash(trash);

    return trash;
end


-- 全局化
_G.__global__ = Global;

Global:InitSingleton():Init();