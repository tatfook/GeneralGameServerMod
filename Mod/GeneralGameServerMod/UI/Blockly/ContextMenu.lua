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
ContextMenu:Property("BaseStyle", {
	NormalStyle = {
		["position"] = "absolute",
        ["left"] = 0,
        ["top"] = 0,
	}
});


local block_menus = {
    { text = "复制", cmd = "copy"},
    { text = "删除", cmd = "delete"},
}

local blockly_menus = {

}

function ContextMenu:Init(xmlNode, window, parent)
    ContextMenu._super.Init(self, xmlNode, window, parent);
    self:SetVisible(false);
    return self;
end

function ContextMenu:GetMenus()
    local menuType = self:GetMenuType();
    if (menuType == "block") then return block_menus end

    return blockly_menus;
end

function ContextMenu:RenderContent(painter)
end

function ContextMenu:OnMouseDown(event)
    event:Accept();
end

function ContextMenu:OnMouseUp(event)
    event:Accept();
end

-- 定宽不定高
function ContextMenu:OnUpdateLayout()
    local menus = self:GetMenus();
    local width = 120;
    local height = (#menus) * 40;

    self:GetLayout():SetWidthHeight(width, height);
end

function ContextMenu:Show(params)
    self:SetMenuType(params.menuType);

    local menus = self:GetMenus();
    if (#menus == 0) then return end

    self:SetVisible(true);
    self:UpdateLayout();
    self:SetPosition(params.absX or 0, params.absY or 0);
end

function ContextMenu:Hide()
    self:SetVisible(false);
end
