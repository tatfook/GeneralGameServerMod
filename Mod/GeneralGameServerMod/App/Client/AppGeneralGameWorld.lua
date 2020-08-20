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

local AppGeneralGameWorld = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameWorld"), commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameWorld"));


function AppGeneralGameWorld:Init(client)
    AppGeneralGameWorld._super.Init(self, client);
    
    GameLogic.GetEvents():AddEventListener("DesktopMenuShow", AppGeneralGameWorld.OnDesktopMenuShow, self, "AppGeneralGameWorld");

    return self;
end

function AppGeneralGameWorld:OnExit()
    AppGeneralGameWorld._super.OnExit(self);

    GameLogic.GetEvents():RemoveEventListener("DesktopMenuShow", AppGeneralGameWorld.OnDesktopMenuShow, self);
end

function AppGeneralGameWorld:OnDesktopMenuShow(obj)
    echo(obj);
end