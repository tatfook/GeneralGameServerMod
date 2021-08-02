--[[
Title: Goods
Author(s):  wxa
Date: 2021-06-01
Desc: 物品基类 
use the lib:
------------------------------------------------------------
local Goods = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/Goods.lua");
------------------------------------------------------------
]]


local Goods = inherit(ToolBase, module("Goods"));

Goods.ClassName = "Goods";              -- 类名
Goods.ClassifyName = nil;               -- 分类名

Goods:Property("GoodsID");              -- 物品ID
Goods:Property("Amount", 1);            -- 数量
Goods:Property("Config");               -- 配置
Goods:Property("CanTransfer", false, "IsCanTransfer"); -- 是否可以转移

local GoodsID = 0;

local GoodsConfig = {
    [10000] = {
        title = "位置",
        description = "位置物品, 用于玩家到达指定位置获取此物品",
    },
    [10001] = {
        title = "天书卷残",
        description = "荣誉物品"
    }
}

function Goods.GetGoodsById(gsid)
    local goods = Goods:new():Init(GoodsConfig[gsid]);
end

function Goods:ctor()
    GoodsID = GoodsID + 1;

    self.ID = GoodsId;    -- 物品ID 唯一标识一个物品
end

function Goods:Init(config)
    self:SetConfig(config);
    self:SetGoodsID(config.gsid or self.ID);
 
    -- 默认可以转移
    if (config.transfer or config.transfer == nil) then self:SetCanTransfer(true) end

    return self;
end

function Goods:GetGoodsName()
    return self.ClassName;
end

-- function Goods:Merge(goods)
--     self:Increment(goods:GetAmount());
-- end

-- function Goods:Clone()
--     return self;
-- end

-- function Goods:Increment(offset)
--     self:SetAmount(self:GetAmount() + offset);
-- end