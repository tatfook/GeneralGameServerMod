--[[
Title: Garbage
Author(s):  wxa
Date: 2021-06-01
Desc: 垃圾桶类
use the lib:
]]

local Config = require("./Config.lua");

local Trash = inherit(require("EntityPlayer"), module());

Trash:Property("Category");

function Trash:ctor()
    self.__trash_garbage_info_map__ = {};    -- 垃圾列表
end

function Trash:Init(opts)
    opts = opts or {};
    
    local category = opts.category or Config.GARBAGE_CATEGORY.QITA;
    local trash_config = Config.TRASH_CONFIG_LIST[category];
    opts.assetfile = opts.assetfile or trash_config.assetfile;
    opts.name = opts.name or trash_config.name;
    opts.label = opts.label or trash_config.label;

    Trash._super.Init(self, opts);

    self:SetCategory(category);

    self:ShowHeadOnDisplay();

    return self;
end

function Trash:GetTrashGarbageInfo(garbage, category)
    category = category or self:GetCategory();
    local name = garbage:GetName();

    self.__trash_garbage_info_map__[category] = self.__trash_garbage_info_map__[category] or {};
    self.__trash_garbage_info_map__[category][name] = self.__trash_garbage_info_map__[category][name] or {
        name = name,
        label = garbage:GetLabel(),
        count = 0,
        blockIndex = garbage:GetBlockIndex(),
    };
    return self.__trash_garbage_info_map__[category][name];
end

function Trash:PickUpGarbage(garbage)
    if (garbage:GetCategory() ~= self:GetCategory()) then
        return Tip("不是同类垃圾, 不可拾取...");
    end

    local info = self:GetTrashGarbageInfo(garbage);
    info.count = info.count + 1;

    garbage:Destroy();

    __global__:DestroyGarbage(info.blockIndex);
    __global__:RandomGarbage();

    return Tip("成功拾取垃圾: " .. garbage:GetLabel());
end

function Trash:ShowHeadOnDisplay(G, params)
    if (self.__head_on_displayer_ui__) then self.__head_on_displayer_ui__:CloseWindow() end

    G = G or {};
    G.GlobalScope = self.__scope__;

    params = params or {};
    params.__key__ = format("EntityHeadOnDisplay_%s", tostring(self));
    params.__is_3d_ui__ = true;
    params.__3d_object__ = self:GetInnerObject();
    params.__offset_y__ = params.__offset_y__ or 1.3;
    params.__offset_z__ = params.__offset_z__ or 0.05;
    -- params.__facing__ = -1.57;
    params.width = params.width or 100;
    params.height = params.height or 30;
    params.x = params.x or (-params.width / 2);
    params.parent = GetRootUIObject();
    params.template = params.template or [[
<template style="width: 100%; height: 100%;">
    <div style="color:#cccccc; font-size: 20px; height: 30px; line-height: 30px; text-align: center;">{{__text__}}</div>
</template>
    ]]
    self.__scope__:Set("__text__", self:GetLabel());
    self.__head_on_displayer_ui__ = ShowWindow(G, params);

    return self.__head_on_displayer_ui__;
end


function Trash:SwitchCategory(category)
    local trash_config = Config.TRASH_CONFIG_LIST[category];
    self:SetCategory(category);
    self:SetName(trash_config.name);
    self:SetLabel(trash_config.label);
    self:SetAssetFile(trash_config.assetfile);
    self.__scope__:Set("__text__", self:GetLabel());
end

function Trash:OnClicked()
    self:SwitchCategory((self:GetCategory() + 1) % Config.GARBAGE_CATEGORY_SIZE);
end
