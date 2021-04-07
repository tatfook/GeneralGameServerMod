--[[
Title: ContextMenu
Author(s): wxa
Date: 2020/6/30
Desc: ContextMenu
use the lib:
-------------------------------------------------------
local ContextMenu = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/ContextMenu.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Window/Element.lua", IsDevEnv);

local ContextMenu = commonlib.inherit(Element, NPL.export());

ContextMenu:Property("Name", "ContextMenu");
ContextMenu:Property("MenuType", "blockly");
ContextMenu:Property("Blockly");

local MenuItemWidth = 120;
local MenuItemHeight = 30;
local block_menus = {
    { text = "复制", cmd = "copy"},
    { text = "删除", cmd = "delete"},
}

local blockly_menus = {
    { text = "撤销", cmd = "undo"},
    { text = "重做", cmd = "redo"},
}

function ContextMenu:Init(xmlNode, window, parent)
    ContextMenu._super.Init(self, xmlNode, window, parent);

    self.selectedIndex = 0;
    return self;
end

function ContextMenu:GetMenus()
    local menuType = self:GetMenuType();
    if (menuType == "block") then return block_menus end

    return blockly_menus;
end

function ContextMenu:GetMenuItem(index)
    local menus = self:GetMenus();
    return menus[index];
end

function ContextMenu:GetMenuItemCount()
    local menus = self:GetMenus();
    return #menus;
end

function ContextMenu:RenderContent(painter)
    local x, y = self:GetPosition();
    local menus = self:GetMenus();

    painter:SetBrush("#285299")
    painter:DrawRect(x, y + self.selectedIndex * MenuItemHeight, MenuItemWidth, MenuItemHeight);
    painter:SetBrush(self:GetColor());
    for i, menu in ipairs(menus) do
        painter:DrawText(x + 20 , y + (i - 1) * MenuItemHeight + 8, menu.text);
    end
end

function ContextMenu:SelectMenuItem(event)
    local mouseMoveX, mouseMoveY = self:GetRelPoint(event.x, event.y);
    self.selectedIndex = math.floor(mouseMoveY / MenuItemHeight);
    self.selectedIndex = math.min(self.selectedIndex, self:GetMenuItemCount() - 1);
    return self.selectedIndex;
end

function ContextMenu:OnMouseDown(event)
    event:Accept();
    self:Hide();
    local menuitem = self:GetMenuItem(self:SelectMenuItem(event) + 1);
    if (not menuitem) then return end
    local blockly = self:GetBlockly();
    if (menuitem.cmd == "copy") then
        blockly:handlePaste();
    elseif (menuitem.cmd == "delete") then
        blockly:handleDelete();
    elseif (menuitem.cmd == "undo") then
        blockly:Undo();
    elseif (menuitem.cmd == "redo") then
        blockly:Redo();
    end 
end

function ContextMenu:OnMouseMove(event)
    event:Accept();
    self:SelectMenuItem(event);
end

function ContextMenu:OnMouseUp(event)
    event:Accept();
end

-- 定宽不定高
function ContextMenu:OnUpdateLayout()
    self:GetLayout():SetWidthHeight(MenuItemWidth, self:GetMenuItemCount() * MenuItemHeight);
end

function ContextMenu:Show(menuType)
    self:SetMenuType(menuType);
    local menus = self:GetMenus();
    if (#menus == 0) then return end

    self.selectedIndex = 0;
    self:SetVisible(true);
    self:UpdateLayout();
end

function ContextMenu:Hide()
    self:SetVisible(false);
end

 