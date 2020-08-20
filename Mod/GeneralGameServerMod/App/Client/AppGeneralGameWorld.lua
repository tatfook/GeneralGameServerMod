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

    -- 移除多人联网
    DesktopMenu.LoadMenuItems()
    self.menus = DesktopMenu.GetAllModeMenu();
    self.menus_backup = {};
    for i = 1, #(self.menus) do 
        local menu = self.menus[i];
        for i = 1, #menu do
            if (menu[i].text == L"多人联网") then
                self.menus_backup[menu] = {index = i, item = menu[i]};
                table.remove(menu, i);
                break;
            end 
        end
    end
    DesktopMenuPage.Refresh();

    return self;
end

function AppGeneralGameWorld:OnExit()
    AppGeneralGameWorld._super.OnExit(self);

    -- 恢复多人联网
    for i = 1, #(self.menus) do 
        local menu = self.menus[i];
        local backup = self.menus_backup[menu];
        if (backup) then
            table.insert(menu, backup.index, backup.item);
        end
    end
    DesktopMenuPage.Refresh();
    self.menus = {};
    
    -- GameLogic.GetEvents():RemoveEventListener("DesktopMenuShow", AppGeneralGameWorld.OnDesktopMenuShow, self);
end

function AppGeneralGameWorld:OnDesktopMenuShow(obj)
end