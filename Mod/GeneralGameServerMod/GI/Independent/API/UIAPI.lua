--[[
Title: UIAPI
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local UIAPI = NPL.load("Mod/GeneralGameServerMod/GI/Independent/API/UIAPI.lua");
------------------------------------------------------------
]]

local Vue = NPL.load("Mod/GeneralGameServerMod/UI/Vue/Vue.lua");
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");

local UIAPI = NPL.export();

setmetatable(UIAPI, {__call = function(_, CodeEnv)
    local windows = CodeEnv.__windows__;

    CodeEnv.ShowWindow = function(G, params)
        -- 预处理参数
        params = params or {};
        params.G = G;
        local key = params.html or params.template or params.url;
        if (not key) then return end
        
        -- 获取窗口
        if (windows[key] and windows[key]:GetNativeWindow()) then windows[key]:CloseWindow() end
        local window = (not IsDevEnv and windows[key]) and windows[key] or Vue:new();
        windows[key] = window;

        -- 显示窗口
        window:Show(params);

        return window;
	end
end});
