--[[
Title: page
Author(s): wxa
Date: 2020/6/30
Desc: UI 入口文件, 实现组件化开发
use the lib:
-------------------------------------------------------
local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
page.ShowUserInfoPage({username="用户名", mainasset="人物模型文件名"}); -- 显示用户信息页
-------------------------------------------------------
]]

local ui = NPL.load("./ui.lua");
local vue = NPL.load(_G.__GGS_UI__ .. "Vue/Vue.lua", IsDevEnv);
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua", IsDevEnv);

local page = NPL.export();

-- 通用信息框
function page.Show(G, params)
    params = params or {};

    -- params.width = params.width or 500;
    -- params.height = params.height or 242;
    -- params.url = "%ui%/Page/MessageBox.html";

    params.G = G;
    params.OnClose = function() end

    ui:ShowWindow(params);
end

-- 显示用户信息
local UserInfoPageUI = ui:new();
function page.ShowUserInfoPage(G, params)
    return Page.ShowUserInfoPage(G, params);
    -- params = params or {};

    -- params.url = "%ui%/Page/UserInfoPage.html";
    -- params.G = G;
    -- params.allowDrag = false;
    -- params.OnClose = function() end

    -- UserInfoPageUI:ShowWindow(params);
    -- return UserInfoPageUI;
end

local UserRegionUpdatePage = vue:new();
function page.ShowUserRegionUpdatePage(G, params)
    params = params or {};

    params.url = "%vue%/Page/User/AreaSelect.html";
    params.draggable = false;
    params.G = G;
    UserRegionUpdatePage:Show(params);

    return UserRegionUpdatePage;
end

local MessageBoxPage = vue:new();
function page.ShowMessageBoxPage(G, params)
    params = params or {};

    params.url = "%vue%/Page/User/MessageBox.html";
    params.draggable = false;
    params.G = G;
    MessageBoxPage:Show(params);

    return MessageBoxPage;
end


local DebugInfoPage = vue:new()
function page.ShowDebugInfoPage(G, params)
    params = params or {};

    params.url = "%vue%/Page/Debug/DebugInfo.html";
    params.draggable = false;
    params.G = G;
    DebugInfoPage:Show(params);

    return DebugInfoPage;
end


local VueTestPage = vue:new();
function page.ShowVueTestPage(G, params)
    if (IsDevEnv) then
        if (_G.VueTestPage) then
            _G.VueTestPage:CloseWindow();
        end        
        _G.VueTestPage = VueTestPage;
    end

    params = params or {};
    params.draggable = false;
    params.url = params.url or "%vue%/Example/Test.html";
    params.G = G;
    VueTestPage:Show(params);
    return VueTestPage;
end