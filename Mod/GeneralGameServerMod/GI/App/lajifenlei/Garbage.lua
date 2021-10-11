--[[
Title: Garbage
Author(s):  wxa
Date: 2021-06-01
Desc: 垃圾类
use the lib:
]]

local Garbage = inherit(require("Entity"), module());

Garbage:Property("Category");                -- 垃圾分类 cy khs qt yh

function Garbage:Init(opts)
    Garbage._super.Init(self, opts);

    self:SetCategory(opts.category);

    self:ShowHeadOnDisplay();

    return self;
end

function Garbage:OnClicked()
    __global__:PickUpGarbage(self);
end

function Garbage:ShowHeadOnDisplay(G, params)
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
<template style="width: 100%; height: 100%; background-color:#00000080;">
    <div style="color:#cccccc; font-size: 16px; height: 30px; line-height: 30px; text-align: center;">{{__text__}}</div>
</template>
    ]]
    self.__scope__:Set("__text__", self:GetLabel());
    self.__head_on_displayer_ui__ = ShowWindow(G, params);

    return self.__head_on_displayer_ui__;
end