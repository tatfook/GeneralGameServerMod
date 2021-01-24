--[[
Title: page
Author(s): wxa
Date: 2020/6/30
Desc: 显示UI入口文件
use the lib:
-------------------------------------------------------
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
Page.ShowUserInfoPage({username="xiaoyao"});
-------------------------------------------------------
]]

local Vue = NPL.load("./Vue/Vue.lua", IsDevEnv);
local Page = NPL.export();
local pages = {};

function Page.Show(G, params, isNew)
    params = params or {};
    if (not params.url) then return end
   
    local page = pages[params.url] or Vue:new();
    if (isNew) then 
        page = Vue:new();
    else
        pages[params.url] = page;
        if (page:GetNativeWindow()) then 
            page:CloseWindow();
        end
    end

    params.G = G;
    page:Show(params);

    return page;
end

-- 显示用户信息
local UserInfoPage = Vue:new();
function Page.ShowUserInfoPage(G, params)
    params = params or {};

    params.url = "%vue%/Page/User/User.html";
    params.G = G;
    params.draggable = false;
    params.width = params.width or 1025;
    params.height = params.height or 625;
    UserInfoPage:Show(params);

    return UserInfoPage;
end

local DebugInfoPage = Vue:new();
function Page.ShowDebugInfoPage(G, params)
    params = params or {};

    params.url = "%vue%/Page/Debug/DebugInfo.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or 600;
    params.height = params.height or 500;
    DebugInfoPage:Show(params);

    return DebugInfoPage;
end

local BlocklyPage = Vue:new();
function Page.ShowBlocklyPage(G, params)
    if (IsDevEnv) then
        if (_G.BlocklyPage) then
            _G.BlocklyPage:CloseWindow();
        end        
        _G.BlocklyPage = BlocklyPage;
    end

    params = params or {};

    params.url = "%ui%/Blockly/Pages/Blockly.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    BlocklyPage:Show(params);

    return BlocklyPage;
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
    params.width = params.width or 600;
    params.height = params.height or 500;
    VueTestPage:Show(params);

    return VueTestPage;
end

local MessageBoxPage = Vue:new();
function Page.ShowMessageBoxPage(G)
    local params = {};
    
    params.G = G;
    params.url = "%ui%/Common/MessageBox.html";
    params.draggable=false;
    params.width = "80%";
    params.height = "80%";
    params.zorder = 2;
    
    MessageBoxPage:Show(params);

    return MessageBoxPage;
end

local UIEditorPage = Vue:new();
function Page.ShowUIEditorPage(G, params)
    params = params or {};
    params.url = "%ui%/Editor/UI.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    UIEditorPage:Show(params);
    return UIEditorPage;
end
