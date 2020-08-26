--[[
Title: Slot
Author(s): wxa
Date: 2020/6/30
Desc: 插槽组件
use the lib:
-------------------------------------------------------
local Slot = NPL.load("Mod/GeneralGameServerMod/App/ui/Component.lua");
-------------------------------------------------------

A Component
<template>
    <slot></slot>
</template>
B Component
<template>
    <A>
        <div v-slot="default">slot content</div>
    </A>
</template>
]]
local Component = NPL.load("./Component.lua");
local Slot = commonlib.inherit(Component, NPL.export());

function Slot:ctor()
    self.filename = nil;
end

function Slot:ParseComponent()
    local xmlNode = self.xmlNode.xmlNode;
    -- 解析html 生成element
    self:ParseXmlNode(xmlNode);
    -- 设置元素
    self:SetElement(xmlNode and xmlNode.element);
end

