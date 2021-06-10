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

Goods:Property("Amount", 0);            -- 数量

local GoodsID = 0;

function Goods:ctor()
    GoodsID = GoodsID + 1;

    self.ID = GoodsId;    -- 物品ID 唯一标识一个物品
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