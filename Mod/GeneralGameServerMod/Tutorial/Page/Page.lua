--[[
Author: wxa
Date: 2020-10-26
Desc: 
-----------------------------------------------
local Page = NPL.load("Mod/GeneralGameServerMod/Tutorial/Page/Page.lua");
-----------------------------------------------
]]

local Vue = NPL.load("../UI/Vue/Vue.lua", IsDevEnv);

local Page = NPL.export();

Vue.SetPathAlias("tutorial", "Mod/GeneralGameServerMod/Tutorial");

function Page:ShowDialogPage(G, params)
    if (not self.DialogPage) then self.DialogPage = Vue:new() end

    self.DialogPage:CloseWindow();

    params = params or {};
    params.url = "%tutorial%/Page/Dialog.html";
    params.G = G;
    params.alignment = "_ctb";
    params.height = 240;
    params.width = 1000;
    params.draggable = false;
    self.DialogPage:Show(params);

    return self.DialogPage;
end
