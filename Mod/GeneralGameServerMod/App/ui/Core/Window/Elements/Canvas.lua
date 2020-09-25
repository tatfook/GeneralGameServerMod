--[[
Title: Button
Author(s): wxa
Date: 2020/8/14
Desc: 按钮
-------------------------------------------------------
local Canvas = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/Canvas.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua", IsDevEnv);
local Canvas = commonlib.inherit(Element, NPL.export());

function Canvas:ctor()
    self:SetName("Canvas");
end

function Canvas:OnRender()
end
