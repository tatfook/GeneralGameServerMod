--[[
Title: page
Author(s): wxa
Date: 2020/6/30
Desc: UI 入口文件, 实现组件化开发
use the lib:
-------------------------------------------------------
local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
-- 显示用户信息页
page.ShowUserInfoPage({G={username="用户名", mainasset="人物模型文件名"}});
-------------------------------------------------------
]]

local ui = NPL.load("./ui.lua");
local page = NPL.export();

-- 显示用户信息
function page.ShowUserInfoPage(G, params)
    params = params or {};
    params.G = G;
    params.url = "%ui%/Page/UserInfoPage.html";
    ui:ShowWindow(params);
end
