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

Goods:Property("GoodsID");              -- 物品ID
Goods:Property("Amount", 1);            -- 数量
Goods:Property("Config");               -- 配置
Goods:Property("Title");
Goods:Property("Description");
Goods:Property("Count", 1);             -- 初始数量
Goods:Property("StackCount", 1);        -- 累加数量
Goods:Property("CanStack", false, "IsCanStack");               -- 是否可加累加
Goods:Property("DeadGoods", false, "IsDeadGoods");             -- 被碰撞者消失物品
Goods:Property("DeadPeerGoods", false, "IsDeadPeerGoods");     -- 碰撞者消失物品
Goods:Property("BloodPeerGoods", false, "IsBloodPeerGoods");   -- 对端血量物品
Goods:Property("BloodPeerValue", 0);                           -- 对端血量变化
Goods:Property("CanTransfer", false, "IsCanTransfer");     -- 是否可以转移

local __all_goods__ = {};
local GSID = 0;
function Goods:ctor()
    self.__name__ = nil;
end

--[[
{
    gsid = 1,          -- 物品ID 相当类别
    name = "goods",    -- 物品标识符 方便获取尽量唯一 不唯一可能互相覆盖
    title = "物品名称",
    description = "物品描述",
    dead = false,      -- 拥有物品实体触碰消失
    dead_peer = false, -- 碰撞者消失
    transfer = trie,   -- 碰撞转移物品  默认为true
    stack = true,      -- 同类物品(gsid相同) 是否可以累加  默认为true
    count = 1,         -- 数量 默认1
    stackCount = 1,    -- 累加数量
}
]]
function Goods:Init(config)
    config = config or {};
    GSID = GSID + 1;
    self:SetConfig(config);
    self:SetGoodsID(tostring(config.gsid or self));
    self:SetGoodsName(config.name or "goods");
    self:SetTitle(config.title);
    self:SetDescription(config.description);
    self:SetDeadGoods(config.dead);
    self:SetDeadPeerGoods(config.dead_peer);
    self:SetBloodPeerGoods(config.blood_peer);
    self:SetBloodPeerValue(config.blood_peer_value);
    self:SetCanStack(if_else(config.stack == nil or config.stack, true, false));
    self:SetCanTransfer(if_else(config.transfer == nil or config.transfer, true, false)); 
    self:SetCount(config.count or 1); 
    self:SetStackCount(config.stackCount or self:GetCount());

    return self;
end

function Goods:GetGoodsName()
    return self.__name__;
end

function Goods:SetGoodsName(name)
    if (self.__name__) then __all_goods__[self.__name__] = nil end
    self.__name__ = name;
    if (self.__name__) then __all_goods__[self.__name__] = self end
end

function Goods:Destroy()
    -- if (self.__name__) then __all_goods__[self.__name__] = nil end 
end

function Goods:GetGoodsByName(name)
    return type(name) == "table" and name or __all_goods__[name];
end

function Goods:Activate(entity, triggerEntity)
    local gsid = self:GetGoodsID();

    if (self:IsCanTransfer()) then
        entity:RemoveGoods(self);
        triggerEntity:AddGoods(self);
    end

    if (self:IsDeadGoods()) then entity:Destroy() end
    if (self:IsDeadPeerGoods()) then triggerEntity:Destroy() end 
    if (self:IsBloodPeerGoods()) then triggerEntity:IncrementBlood(self:GetBloodPeerValue()) end 
end

local __api_list__ = {
    "SetGoodsID",
    "SetGoodsName",
    "SetTitle",
    "SetDescription",
};

-- blockly api
for _, funcname in ipairs(__api_list__) do
    _G["Goods" .. funcname] = function(name, ...)
        local goods = Goods:GetGoodsByName(name);
        return goods and (goods[funcname])(goods, ...);
    end
end