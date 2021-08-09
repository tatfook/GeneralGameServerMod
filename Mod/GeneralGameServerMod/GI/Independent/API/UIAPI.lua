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
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
local Screen = commonlib.gettable("System.Windows.Screen");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local SceneViewport = commonlib.gettable("MyCompany.Aries.Game.Common.SceneViewport")

local Vue = NPL.load("Mod/GeneralGameServerMod/UI/Vue/Vue.lua", IsDevEnv);

local UIAPI = NPL.export();

setmetatable(UIAPI, {__call = function(_, CodeEnv)
    local windows = CodeEnv.__windows__;
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

        -- 协程数据标记
        local __data__ = CodeEnv.__get_coroutine_data__();
        __data__.__windows__[key] = window;

        -- 指定默认参数
        params.G = G;
        params.draggable = if_else(params.draggable == nil, false, params.draggable);  -- 默认不支持拖拽
        params.width = params.width or (IsDevEnv and "80%" or "100%");
        params.height = params.height or (IsDevEnv and "80%" or "100%");
        params.parent = params.parent or SceneViewport.GetUIObject();

        -- 显示窗口
        window:Show(params);

        return window;
	end

    CodeEnv.GetRootUIObject = function() return ParaUI.GetUIObject("root") end 
    CodeEnv.GetScreenSize = function() return Screen:GetWidth(), Screen:GetHeight() end 
    CodeEnv.GetScreenWidth = function() return Screen:GetWidth() end
    CodeEnv.GetScreenHeight = function() return Screen:GetHeight() end

    CodeEnv.RegisterSceneViewportSizeChange = function(...)
        CodeEnv.RegisterEventCallBack("__scece_viewport_size_change__", ...);
    end

    local scene_viewport = ViewportManager:GetSceneViewport();
    CodeEnv.SetSceneMarginRight = function(size) scene_viewport:SetMarginRight(size) end
    CodeEnv.GetSceneMarginRight = function() return scene_viewport:GetMarginRight() end
    CodeEnv.SetSceneMarginBottom = function(size) scene_viewport:SetMarginBottom(size) end
    CodeEnv.GetSceneMarginBottom = function() return scene_viewport:GetMarginBottom() end

    local function OnSceneViewportSizeChange()
        CodeEnv.TriggerEventCallBack("__scece_viewport_size_change__");
    end
    scene_viewport:Connect("sizeChanged", nil, OnSceneViewportSizeChange, "UniqueConnection");

    CodeEnv.RegisterEventCallBack(CodeEnv.EventType.CLEAR, function()
        scene_viewport:Disconnect("sizeChanged", nil, OnSceneViewportSizeChange, "UniqueConnection");
    end);
end});
