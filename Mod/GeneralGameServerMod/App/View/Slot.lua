--[[
Title: Component
Author(s): wxa
Date: 2020/6/30
Desc: 组件基类
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/App/View/Component.lua");
local Window = commonlib.gettable("Mod.GeneralGameServerMod.App.View.Component");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/mcml.lua");
NPL.load("Mod/GeneralGameServerMod/App/View/Component.lua");
local mcml = commonlib.gettable("System.Windows.mcml");
local Slot = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.App.View.Component"), commonlib.gettable("Mod.GeneralGameServerMod.App.View.Slot"));

function Slot:ctor()
    self.filename = nil;
end

function Slot:ParseComponent()
    local xmlNode = self:GetSlotNode();
    local class_type = xmlNode and mcml:GetClassByTagName(xmlNode.name or "div");
    self:SetElement(class_type and class_type:createFromXmlNode(xmlNode));
end

function Slot:GetSlotNode()
    echo("--------------------------------------------d");
    local slotName = self.attr and self.attr.name;
    local parentComponent = self:GetParentComponent();
    while(parentComponent) do
        local bContinue = false;
        echo(parentComponent.childNodes);
        for i, childNode in ipairs(parentComponent.childNodes) do
            if (childNode.attr and childNode.attr["v-slot"] == slotName) then
                return childNode;
            end
            if (string.lower(childNode.name) == "slot" and childNode.attr and childNode.attr.name == slotName) then
                bContinue = true;
            end
        end
        if (bContinue) then
            parentComponent = parentComponent:GetParentComponent();
        else
            parentComponent = nil;
        end
    end
end

Slot:Register("Slot");