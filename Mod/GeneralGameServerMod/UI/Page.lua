--[[
Title: page
Author(s): wxa
Date: 2020/6/30
Desc: 显示UI入口文件
use the lib:
-------------------------------------------------------
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
-------------------------------------------------------
]]

local Vue = NPL.load("./Vue/Vue.lua", IsDevEnv);
local Page = NPL.export();

function Page.Show(G, params)
    local page = Vue:new();

    params = params or {};
    if (not params.url) then return end
    
    params.draggable = false;
    params.G = G;
    
    page:Show(params);

    return page;
end

local MessageBoxPage = Vue:new();
function Page.ShowMessageBoxPage(G, params)
    params = params or {};

    params.url = "%vue%/Page/MessageBox.html";
    params.draggable = false;
    params.G = G;
    MessageBoxPage:Show(params);

    return MessageBoxPage;
end


local DebugInfoPage = Vue:new();
function Page.ShowDebugInfoPage(G, params)
    params = params or {};

    params.url = "%vue%/Page/DebugInfo.html";
    params.draggable = false;
    params.G = G;
    DebugInfoPage:Show(params);

    return DebugInfoPage;
end

local VueTestPage = Vue:new();
function Page.ShowVueTestPage(G, params)
    if (IsDevEnv) then
        if (_G.VueTestPage) then
            _G.VueTestPage:CloseWindow();
        end        
        _G.VueTestPage = VueTestPage;
    end

    params = params or {};
    -- params.draggable = false;
    params.url = params.url or "%vue%/Example/Test.html";
    params.G = G;
    VueTestPage:Show(params);

    return VueTestPage;
end