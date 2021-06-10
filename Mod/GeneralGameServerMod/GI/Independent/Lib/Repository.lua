
--[[
Title: Repository
Author(s):  wxa
Date: 2021-06-01
Desc: 仓库管理物品 
use the lib:
------------------------------------------------------------
local Repository = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/Repository.lua");
------------------------------------------------------------
]]

local Repository = inherit(nil, module("Repository"));

local __repositories__ = {};                                      -- 用户仓库集
local __default_repository_name__ = "__default_repository__";     -- 默认仓库名

local function GetRepository(owner, name)
    if (not owner) then return end
    name = name or __default_repository_name__;

    __repositories__[owner] = __repositories__[owner] or {};
    return __repositories__[owner][name];
end

local function SetRepository(owner, name, repository)
    if (not owner) then return end
    name = name or __default_repository_name__;
    
    __repositories__[owner] = __repositories__[owner] or {};
    __repositories__[owner][name] = repository;
end

function Repository:ctor()
    self.GoodsListMap = {};  -- 物品集
end

function Repository:Init(owner, name)
    SetRepository(owner, name, self);

    return self;
end

-- 获取指定物品类型的列表
function Repository:GetGoodsListByGoodsName(goodsname)
    self.GoodsListMap[goodsname] = self.GoodsListMap[goodsname] or {};
    return self.GoodsListMap[goodsname];
end

-- 添加物品
function Repository:AddGoods(goods)
    local goodsname = goods:GetGoodsName();
    local goods_list = self:GetGoodsListByGoodsName(goodsname);
    table.insert(goods_list, goods);
end

-- 移除指定物品
function Repository:DeleteGoods(goods)
    local goodsname = goods:GetGoodsName();
    local goods_list = self:GetGoodsListByGoodsName(goodsname);
    for index, item in ipairs(goods_list) do
        if (item == goods) then
            return table.remove(goods_list, index);
        end
    end
end

-- 清空指定类型物品
function Repository:ClearGoods(goodsname)
    self.GoodsListMap[goodsname] = nil;
end

-- 获取主玩家库
function GetPlayerRepository(name)
    local owner = GetUserName();
    local repository = GetRepository(owner, name);
    if (not repository) then repository = Repository:new():Init(owner, name) end
    return repository;
end
