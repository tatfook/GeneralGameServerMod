--[[
Title: MacrosExtend
Author(s): wxa
Date: 2020/6/30
Desc: 宏接口扩展
use the lib:
-------------------------------------------------------
local MacrosExtend = NPL.load("Mod/GeneralGameServerMod/UI/Page/Macro/MacrosExtend.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/Macros.lua");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros");

local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
local MacrosExtend = NPL.export();

function Macros.ShowSubTitlePage(text)
    Page.ShowSubTitlePage({text = text});
end

local inited = false;
function MacrosExtend.StaticInit()
    if (inited) then return end
    GameLogic.GetFilters():add_filter("Macro_BeginRecord", function()
    end);
    GameLogic.GetFilters():add_filter("Macro_EndRecord", function()
    end);
end
