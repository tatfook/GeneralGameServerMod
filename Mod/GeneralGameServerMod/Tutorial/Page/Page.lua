--[[
Author: wxa
Date: 2020-10-26
Desc: 
-----------------------------------------------
local Page = NPL.load("Mod/GeneralGameServerMod/Tutorial/Page/Page.lua");
-----------------------------------------------
]]

local Vue = NPL.load("../../App/ui/Core/Vue/Vue.lua", IsDevEnv);

local Page = NPL.export();

Vue.SetPathAlias("tutorial", "Mod/GeneralGameServerMod/Tutorial");

local DialogPage = Vue:new();
function Page.ShowDialogPage(G, params)
    if (IsDevEnv) then
        if (_G.VuePage) then
            _G.VuePage:CloseWindow();
        end        
        _G.VuePage = DialogPage;
    end

    params = params or {};
    params.url = "%tutorial%/Page/Dialog.html";
    params.G = G;
    params.alignment = "_ctb";
    params.height = 240;
    params.width = 1000;
    params.draggable = false;
    DialogPage:Show(params);

    return DialogPage;
end
