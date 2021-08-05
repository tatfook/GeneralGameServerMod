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
Goods:Property("CanTransfer", false, "IsCanTransfer"); -- 是否可以转移

local __all_goods__ = {};

local GoodsConfig = {
    [0] = {
        title = "默认物品",
        description = "示例物品",
    },
    [1] = {
        transfer = false,
        title = "触碰死亡",
        description = "拥有此物品的角色被触碰会死亡"
    },
    [2] = {
        transfer = true,
        title = "天书残卷",
        description = "荣誉物品",
    },
    [3] = {
        transfer = true,
        title = "目标位置",
        description = "位置物品",
    },
}

function Goods.GetGoodsById(gsid)
    local goods = Goods:new():Init(GoodsConfig[gsid]);
end

function Goods:ctor()
    self.__name__ = nil;
end

function Goods:Init(config)
    config = config or {};
    
    self:SetConfig(config);
    self:SetGoodsID(config.gsid or 0);
    self:SetGoodsName(config.name);

    local tpl = GoodsConfig[self:GetGoodsID()];
    self:SetTitle(config.title or (tpl and tpl.title));
    self:SetDescription(config.description or (tpl and tpl.description));

    -- 默认可以转移
    local transfer = if_else(config.transfer == nil, tpl and tpl.transfer, config.transfer);
    if (transfer or transfer == nil) then self:SetCanTransfer(true) end

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
    __all_goods__[self.__name__] = nil;
end

function Goods:GetGoodsByName(name)
    return name and __all_goods__[name];
end

function Goods:Activate(entity, triggerEntity)
    local gsid = self:GetGoodsID();

    if (self:IsCanTransfer()) then
        entity:RemoveGoods(self);
        triggerEntity:AddGoods(self);
    end

    if (gsid == 0) then entity:Destroy() end
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