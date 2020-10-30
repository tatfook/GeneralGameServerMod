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

local ChatPage = Vue:new();
function Page.ShowChatPage(G, params)
    if (IsDevEnv) then
        if (_G.VuePage) then
            _G.VuePage:CloseWindow();
        end        
        _G.VuePage = ChatPage;
    end

    params = params or {};
    params.url = "%tutorial%/Page/Chat.html";
    params.G = G;
    params.alignment = "_ctb";
    params.height = 200;
    params.width = 1000;
    params.draggable = false;
    ChatPage:Show(params);

    return ChatPage;
end
