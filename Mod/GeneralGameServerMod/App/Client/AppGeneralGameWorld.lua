--[[
Title: AppEntityOtherPlayer
Author(s): wxa
Date: 2020/7/9
Desc: 世界类
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameWorld.lua");
local AppGeneralGameWorld = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameWorld");
-------------------------------------------------------
]]
NPL.load("Mod/GeneralGameServerMod/Core/Client/GeneralGameWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenu.lua");
local DesktopMenu = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenu");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenuPage.lua");
local DesktopMenuPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenuPage");

local AppGeneralGameWorld = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameWorld"), commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameWorld"));


function AppGeneralGameWorld:Init(client)
    AppGeneralGameWorld._super.Init(self, client);

    -- GameLogic.GetEvents():AddEventListener("DesktopMenuShow", AppGeneralGameWorld.OnDesktopMenuShow, self, "AppGeneralGameWorld");

    -- replaced by big: 2022.7.20
    -- 移除多人联网
    -- DesktopMenu.LoadMenuItems()
    -- self.menus = DesktopMenu.GetAllModeMenu();
    -- self.menus_backup = {};
    -- for i = 1, #(self.menus) do 
    --     local menu = self.menus[i];
    --     for i = 1, #menu do
    --         if (menu[i].text == L"多人联网") then
    --             self.menus_backup[menu] = {index = i, item = menu[i]};
    --             table.remove(menu, i);
    --             break;
    --         end 
    --     end
    -- end
    -- DesktopMenuPage.Refresh();

    -- 非安静模式 发送ggs loadworld通知
    if (not self:GetClient():GetOptions().silent) then
        GameLogic.GetFilters():apply_filters("ggs", {action = "LoadWorld"});
    end
    
    return self;
end

function AppGeneralGameWorld:OnExit()
    AppGeneralGameWorld._super.OnExit(self);

    -- replaced by big: 2022.7.20
    -- 恢复多人联网
    -- for i = 1, #(self.menus) do 
    --     local menu = self.menus[i];
    --     local backup = self.menus_backup[menu];
    --     if (backup) then
    --         table.insert(menu, backup.index, backup.item);
    --     end
    -- end
    -- DesktopMenuPage.Refresh();
    -- self.menus = {};
    
    -- if (not self:GetClient():GetOptions().silent) then
        GameLogic.GetFilters():apply_filters("ggs", {action = "ExitWorld"});
    -- end 
end

function AppGeneralGameWorld:OnDesktopMenuShow(obj)
end