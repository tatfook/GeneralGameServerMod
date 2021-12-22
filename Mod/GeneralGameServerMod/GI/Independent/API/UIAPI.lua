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
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local Vue = NPL.load("Mod/GeneralGameServerMod/UI/Vue/Vue.lua", IsDevEnv);

local UIAPI = NPL.export();
local RootUI = ParaUI.GetUIObject("root");
setmetatable(UIAPI, {__call = function(_, CodeEnv)
    local windows = CodeEnv.__windows__;
    local Scope = Vue.Scope;

    CodeEnv.NewScope = function(val) return Scope:__new__(val) end 

    CodeEnv.ShowWindow = function(G, params)
        -- 预处理参数
        G = G or {};
        params = params or {};
        local key = CommonLib.MD5(params.__key__ or params.html or params.template or params.url or "");
        
        setmetatable(G, {__index = CodeEnv});
        
        -- 在沙盒中运行所有回调
        G.__call__ = CodeEnv.__call__;

        -- 获取窗口
        if (windows[key] and windows[key]:GetNativeWindow()) then windows[key]:CloseWindow() end
        local window = (not IsDevEnv and windows[key]) and windows[key] or Vue:new();
        windows[key] = window;
        
        -- 协程标记
        local __data__ = CodeEnv.__get_coroutine_data__();
        __data__.__windows__[key] = window;
        
        local OnClose = rawget(G, "OnClose");
        G.OnClose = function()
            if (type(OnClose) == "function") then OnClose(G) end
            
            windows[key] = nil;
            __data__.__windows__[key] = nil;

            -- 聚焦至主窗口
            CodeEnv.FocusRootUIObject();
        end

        -- 指定默认参数
        params.G = G;
        params.draggable = if_else(params.draggable == nil, false, params.draggable);  -- 默认不支持拖拽
        params.width = params.width or (IsDevEnv and "80%" or "100%");
        params.height = params.height or (IsDevEnv and "80%" or "100%");
        params.parent = params.parent or SceneViewport.GetUIObject();
        -- params.url = params.url and CodeEnv.GetFullPath(params.url);

        -- 显示窗口
        window:Show(params);

        return window;
	end

    CodeEnv.FocusRootUIObject = function() ParaUI.GetUIObject("root"):Focus() end 
    CodeEnv.GetRootUIObject = function() return ParaUI.GetUIObject("root") end 
    CodeEnv.GetScreenSize = function() return Screen:GetWidth(), Screen:GetHeight() end 
    CodeEnv.GetScreenWidth = function() return Screen:GetWidth() end
    CodeEnv.GetScreenHeight = function() return Screen:GetHeight() end

    CodeEnv.RegisterSceneViewportSizeChange = function(...)
        CodeEnv.RegisterEventCallBack("__scece_viewport_size_change__", ...);
    end

    CodeEnv.RemoveSceneViewportSizeChange = function(...)
        CodeEnv.RemoveEventCallBack("__scece_viewport_size_change__", ...);
    end

    CodeEnv.RegisterScreenSizeChange = function(...)
        CodeEnv.RegisterEventCallBack("__screen_size_change__", ...);
    end

    CodeEnv.RemoveScreenSizeChange = function(...)
        CodeEnv.RemoveEventCallBack("__screen_size_change__", ...);
    end

    local scene_viewport = ViewportManager:GetSceneViewport();

    local function OnSceneViewportSizeChange()
        CodeEnv.TriggerEventCallBack("__scece_viewport_size_change__");
        for _, wnd in pairs(windows) do
            wnd:OnScreenSizeChanged();
        end
    end

    local function OnScreenSizeChanged()
        CodeEnv.TriggerEventCallBack("__screen_size_change__");
    end
    
    CodeEnv.SetSceneMargin = function(left, top, right, bottom)
        scene_viewport:SetLeft(left);
        scene_viewport:SetTop(top);
        scene_viewport:SetMarginRight(right);
        scene_viewport:SetMarginBottom(bottom);
        OnSceneViewportSizeChange();
    end

    CodeEnv.GetSceneMargin = function()
        local left = scene_viewport:GetLeft();
        local top = scene_viewport:GetTop();
        local right = scene_viewport:GetMarginRight();
        local bottom = scene_viewport:GetMarginBottom();
        return left, top, right, bottom;
    end

    CodeEnv.GetSceneMarginLeft = function() return scene_viewport:GetLeft() end
    CodeEnv.GetSceneMarginTop = function() return scene_viewport:GetTop() end
    CodeEnv.GetSceneMarginRight = function() return scene_viewport:GetMarginRight() end
    CodeEnv.GetSceneMarginBottom = function() return scene_viewport:GetMarginBottom() end

    CodeEnv.SetSceneWidthHeight = function(width, height)
        scene_viewport:SetWidth(width);
        scene_viewport:SetHeight(height);
        OnSceneViewportSizeChange();
    end

    CodeEnv.GetSceneWidthHeight = function()
        local width = scene_viewport:GetWidth();
        local height = scene_viewport:GetHeight();
        return width, height;
    end

    CodeEnv.SetSceneMarginLeft = function(size)
        scene_viewport:SetLeft(size);
        OnSceneViewportSizeChange();
    end

    CodeEnv.SetSceneMarginTop = function(size)
        scene_viewport:SetTop(size);
        OnSceneViewportSizeChange();
    end

    CodeEnv.SetSceneMarginRight = function(size) 
        scene_viewport:SetMarginRight(size);
        OnSceneViewportSizeChange();
    end
    
    CodeEnv.SetSceneMarginBottom = function(size) 
        scene_viewport:SetMarginBottom(size) 
        OnSceneViewportSizeChange();
    end
    
    scene_viewport:Connect("sizeChanged", nil, OnSceneViewportSizeChange, "UniqueConnection");
    Screen:Connect("sizeChanged", nil, OnScreenSizeChanged, "UniqueConnection");

    CodeEnv.RegisterEventCallBack(CodeEnv.EventType.CLEAR, function()
        scene_viewport:Disconnect("sizeChanged", nil, OnSceneViewportSizeChange, "UniqueConnection");
        Screen:Disconnect("sizeChanged", nil, OnScreenSizeChanged, "UniqueConnection");
    end);
end});
