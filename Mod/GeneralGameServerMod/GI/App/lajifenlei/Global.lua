--[[
Title: Global
Author(s):  wxa
Date: 2021-06-01
Desc: 全局对象 __global__ 
use the lib:
]]

local Config = require("./Config.lua");
local Garbage = require("./Garbage.lua");
local Trash = require("./Trash.lua");
local Net = require("./Net.lua");

local Global = inherit(ToolBase, module());

Global:Property("MainPlayerTrash");          -- 主玩家垃圾桶对象
Global:Property("GarbageCount", 0);          -- 当前垃圾数量
Global:Property("Mode", "offline");          -- online 联机模式  offline 离线模式

local GarbagePosList = {};
local GarbageMap = {};

local INIT_GARBAGE_COUNT = 50;

Global.Garbage = Garbage;
Global.Trash = Trash;

function Global:ctor()
    self.__trash_map__ = {};                 -- 玩家垃圾桶集
    self.__garbage_pos_list = {};            -- 可用放置垃圾地块的列表  
    self.__state__ = {
        -- 垃圾存放的地图信息  此对象暂时为响应式变量 统一垃圾信息 
        __garbage_map__ = {},
    }
    self.__map_start_bx__, self.__map_start_by__, self.__map_start_bz__ = 19140, 12, 19140;               -- 地图开始坐标  
    self.__map_end_bx__, self.__map_end_by__, self.__map_end_bz__ = 19259, 13, 19259;                     -- 地图结束坐标

    -- debug
    -- INIT_GARBAGE_COUNT = 10;
    -- self.__map_start_bx__, self.__map_start_by__, self.__map_start_bz__ = 19218,12,19172;               -- 地图开始坐标  
    -- self.__map_end_bx__, self.__map_end_by__, self.__map_end_bz__ = 19224,12,19207;                     -- 地图结束坐标
end

-- 全局初始化
function Global:Init()
    -- 搜集可以放置垃圾的地块位置信息列表
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

-- 开始游戏
function Global:Start(mode)
    self:SetMode(mode);
    
    SetCamera(20, 55, -90);
    SetCameraLookAtBlockPos(19221,12,19185);
    self:CreateMainPlayerTrash(19221,12,19185):TurnLeft(90);

    self:RandomGarbageMap();

    -- 联机模式
    if (self:IsOnlineMode()) then
        -- 联机并出示一致性数据
        self.__state__ = Net:Connect(self.__state__);
        -- log(self.__state__)
    end

    -- 加载地图
    self:LoadGarbageMap();
end

function Global:GetGarbageMap()
    return self.__state__ and self.__state__.__garbage_map__;
end

-- 是否是联机模式
function Global:IsOnlineMode()
    return self:GetMode() == "online";
end

-- 随机垃圾位置
function Global:RandomGarbagePos()
    local size = #self.__garbage_pos_list;
    local index = math.random(1, size);
    local pos = self.__garbage_pos_list[index];

    local garbageMap = self:GetGarbageMap();
    -- 存在垃圾继续随机
    while(garbageMap[pos.blockIndex]) do
        index = math.random(1, size);
        pos = self.__garbage_pos_list[index];
    end

    return  pos;
end

function Global:RandomGarbageInfo()
    local pos = self:RandomGarbagePos();
    local garbageConfigIndex = math.random(#Config.GARBAGE_CONFIG_LIST);
    return {
        key = UUID(),
        blockIndex = pos.blockIndex,
        garbageConfigIndex = garbageConfigIndex,
    };

end

function Global:LoadGarbageInfo(info)
    local bx, by, bz = ConvertToBlockPositionFromBlockIndex(info.blockIndex);
    local garbageConfig = Config.GARBAGE_CONFIG_LIST[info.garbageConfigIndex];
    local garbage = Garbage:new():Init({
        key = info.key,
        bx = bx, by = by, bz = bz,
        category = garbageConfig.category,
        assetfile = garbageConfig.assetfile,
        name = garbageConfig.name,
        label = garbageConfig.label,
    });
    return garbage;
end


-- 随机生成垃圾地图信息
function Global:RandomGarbageMap()
    local map = self:GetGarbageMap();
    for i = 1, INIT_GARBAGE_COUNT do
        local info = self:RandomGarbageInfo();
        map[info.key] = info;
    end
end

-- 加载垃圾地图数据
function Global:LoadGarbageMap()
    ForEachEntity(function(entity)
        if (entity:isa(Garbage)) then
            entity:Destroy();
        end
    end);

    local map = self:GetGarbageMap();

    for _, info in pairs(map) do
        self:LoadGarbageInfo(info);
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

-- 创建垃圾
function Global:CreatePlayerTrash(opts)
    return Trash:new():Init(opts);
end

function Global:PickUpGarbage(garbage)
    local mainPlayerTrash = self:GetMainPlayerTrash();
    if (not mainPlayerTrash:PickUpGarbage(garbage)) then return end 
    self:OnGarbageDestory(garbage);
    -- 随机产生一个替换垃圾
    self:OnGarbageCreate(self:RandomGarbageInfo());
end

-- 同步垃圾拾取的网络事件
function Global:OnGarbageDestory(garbage)
    print("--------------OnGarbageDestory---------------", garbage:GetBlockIndex());
    -- 置空地图信息
    self:GetGarbageMap()[garbage:GetKey()] = nil;
    -- 非联机直接返回
    if (not self:IsOnlineMode()) then return end  
    -- 发送网络事件
    Net:DestroyGarbage(garbage);
end

-- 同步垃圾创建网络事件
function Global:OnGarbageCreate(info)
    print("--------------OnGarbageCreate---------------", info.blockIndex);
    self:GetGarbageMap()[info.key] = info;
    if (not self:IsOnlineMode()) then return end  
    Net:CreateGarbage(info);
end

-- 导出全局化
_G.__global__ = Global;

Global:InitSingleton():Init();