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
        params.parent = params.parent or SceneViewport.GetUIObject();

        -- 显示窗口
        window:Show(params);

        return window;
	end

    CodeEnv.GetRootUIObject = function() return ParaUI.GetUIObject("root") end 

    CodeEnv.GetScreenSize = function() 
        local width = Screen:GetWidth();
        local height = Screen:GetHeight();
        return width, height;
    end

    local scene_viewport = ViewportManager:GetSceneViewport();
    local blockly_code_editor = nil;
    local function OnViewportChange()
        
        local MAX_3DCANVAS_WIDTH = 600;
        local MIN_CODEWINDOW_WIDTH = 200+350;
        local screenWidth = Screen:GetWidth();
        local width = math.max(math.floor(screenWidth * 1/3), MIN_CODEWINDOW_WIDTH);
        local halfScreenWidth = math.floor(screenWidth * 11 / 20);  -- 50% 55%  
        if(halfScreenWidth > MAX_3DCANVAS_WIDTH) then
            width = halfScreenWidth;
        elseif((screenWidth - width) > MAX_3DCANVAS_WIDTH) then
            width = screenWidth - MAX_3DCANVAS_WIDTH;
        end

        if (not blockly_code_editor) then return width end

        blockly_code_editor:GetParams().width = width;
        blockly_code_editor:OnScreenSizeChanged();
    end

    scene_viewport:Connect("sizeChanged", nil, OnViewportChange, "UniqueConnection");

    CodeEnv.ShowBlocklyCodeEditor = function(G, params)
        params = params or {};
        params.url = params.url or "%gi%/Independent/UI/BlocklyCodeEditor.html";
        params.parent = ParaUI.GetUIObject("root");
    
        params.width = OnViewportChange();
        params.height = "100%";
        params.alignment = "_rt";
        
        scene_viewport:SetMarginRight(params.width);
        blockly_code_editor = CodeEnv.ShowWindow(G, params);
        return blockly_code_editor;
    end

    CodeEnv.SetSceneMarginRight = function(size) 
        scene_viewport:SetMarginRight(size);
        for _, wnd in pairs(windows) do
            wnd:OnScreenSizeChanged();
        end
    end

    -- CodeEnv.ShowBlocklyFactory = function()
    --     return CodeEnv.ShowWindow(nil, {
    --         draggable = false,
    --         width = 1200,
    --         height = 1000,
    --         url = "%ui%/Blockly/Pages/BlocklyFactory.html",
    --     });
    -- end

    CodeEnv.RegisterEventCallBack(CodeEnv.EventType.CLEAR, function()
        scene_viewport:SetMarginRight(0);
        scene_viewport:Disconnect("sizeChanged", nil, OnViewportChange, "UniqueConnection");
    end);

end});
