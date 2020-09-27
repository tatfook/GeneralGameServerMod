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
    params = params or {};

    params.url = "%ui%/Page/UserInfoPage.html";
    params.G = G;
    params.OnClose = function() end

    UserInfoPageUI:ShowWindow(params);
    return UserInfoPageUI;
end
