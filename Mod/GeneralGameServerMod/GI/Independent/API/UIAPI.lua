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
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/SceneViewport.lua");
local SceneViewport = commonlib.gettable("MyCompany.Aries.Game.Common.SceneViewport")

local UIAPI = NPL.export();

setmetatable(UIAPI, {__call = function(_, CodeEnv)
    local windows = CodeEnv.__windows__;
    local Vue = CodeEnv.Vue;
    local Scope = Vue.Scope;

    CodeEnv.NewScope = function(val) return Scope:__new__(val) end 

    CodeEnv.ShowWindow = function(G, params)
        -- 预处理参数
        G = G or {};
        params = params or {};
        local key = params.html or params.template or params.url;
        if (not key) then return end
        
        setmetatable(G, {__index = CodeEnv});
        
        -- 在沙盒中运行所有回调
        G.__call__ = CodeEnv.__call__;

        -- 获取窗口
        if (windows[key] and windows[key]:GetNativeWindow()) then windows[key]:CloseWindow() end
        local window = (not IsDevEnv and windows[key]) and windows[key] or Vue:new();
        windows[key] = window;

        -- 指定默认参数
        params.G = G;
        params.draggable = if_else(params.draggable == nil, false, params.draggable);  -- 默认不支持拖拽
        params.width = params.width or (IsDevEnv and "80%" or "100%");
        params.height = params.height or (IsDevEnv and "80%" or "100%");
        params.parent = SceneViewport.GetUIObject();

        -- 显示窗口
        window:Show(params);

        return window;
	end
end});
