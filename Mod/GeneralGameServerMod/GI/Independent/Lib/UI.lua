--[[
Title: UI
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local UI = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/UI.lua");
------------------------------------------------------------
]]

local UI = inherit(nil, module("UI"));

-- function UI.ShowEditWindow(text, callback)
--     ShowWindow({
--         text = text or "",
--         OnClose = function(G)
--             __call__(callback, G.value);
--         end
--     }, {
--         url = "%gi%/Independent/UI/EditWindow.html",
--     });
-- end

-- 场景内显示GI图块编辑
function ShowGIBlocklyEditorPage()
    ShowWindow({
        run = function(text) 
            __run__(text);
        end,
    }, {
        draggable = true,
        url = "%gi%/Independent/UI/GIBlocklyEditor.html",
        width = "100%",
        height = "100%",
    });
end

local function GetCodeBlockEditorWidth()
    local MAX_3DCANVAS_WIDTH = 600;
    local MIN_CODEWINDOW_WIDTH = 200+350;
    local screenWidth, screenHeight = GetScreenSize();
    local width = math.max(math.floor(screenWidth * 1/3), MIN_CODEWINDOW_WIDTH);
    local halfScreenWidth = math.floor(screenWidth * 11 / 20);  -- 50% 55%  
    if(halfScreenWidth > MAX_3DCANVAS_WIDTH) then
        width = halfScreenWidth;
    elseif((screenWidth - width) > MAX_3DCANVAS_WIDTH) then
        width = screenWidth - MAX_3DCANVAS_WIDTH;
    end
    return width;
end

-- 场景外显示GI图块编辑
local CodeBlockBlocklyEditorPage = nil;
function ShowCodeBlockBlocklyEditorPage(G, params)
    params = params or {};
    params.url = params.url or "%gi%/Independent/UI/CodeBlockBlocklyEditor.html";
    params.parent = GetRootUIObject();
    params.width = GetCodeBlockEditorWidth();
    params.height = "100%";
    params.alignment = "_rt";
    
    local margin_right = GetSceneMarginRight();
    SetSceneMarginRight(params.width);

    G = G or {};
    local OnClose = G.OnClose;
    local function OnScreenSizeChanged()
        if (not CodeBlockBlocklyEditorPage) then return end
        local width = GetCodeBlockEditorWidth();
        CodeBlockBlocklyEditorPage:GetParams().width = width;
        CodeBlockBlocklyEditorPage:OnScreenSizeChanged();
        SetSceneMarginRight(width);
    end
    G.OnClose = function()
        if (type(OnClose) == "function") then OnClose() end 
        SetSceneMarginRight(margin_right);
        RemoveScreenSizeChange(OnScreenSizeChanged);
        CodeBlockBlocklyEditorPage = nil;
    end

    RegisterScreenSizeChange(OnScreenSizeChanged);
    CodeBlockBlocklyEditorPage = ShowWindow(G, params);
    return CodeBlockBlocklyEditorPage;
end

-- 场景外显示关卡图块编辑
local LevelBlocklyEditorPage = nil;
function ShowLevelBlocklyEditorPage(G, params)
    if (LevelBlocklyEditorPage) then return end

    params = params or {};
    params.url = params.url or "%gi%/Independent/UI/LevelBlocklyEditor.html";
    params.parent = GetRootUIObject();
    params.width = GetCodeBlockEditorWidth();
    params.height = "100%";
    params.alignment = "_rt";
    
    local margin_right = GetSceneMarginRight();
    SetSceneMarginRight(params.width);

    G = G or {};
    local OnClose = G.OnClose;
    local function OnScreenSizeChanged()
        if (not LevelBlocklyEditorPage) then return end
        local width = GetCodeBlockEditorWidth();
        LevelBlocklyEditorPage:GetParams().width = width;
        LevelBlocklyEditorPage:OnScreenSizeChanged();
        SetSceneMarginRight(width);
    end
    G.OnClose = function()
        if (type(OnClose) == "function") then OnClose() end 
        SetSceneMarginRight(margin_right);
        RemoveScreenSizeChange(OnScreenSizeChanged);
        LevelBlocklyEditorPage = nil;
    end

    RegisterScreenSizeChange(OnScreenSizeChanged);
    LevelBlocklyEditorPage = ShowWindow(G, params);
    return LevelBlocklyEditorPage;
end

function CloseLevelBlocklyEditorPage()
    if (not LevelBlocklyEditorPage) then return end 
    LevelBlocklyEditorPage:CloseWindow();
    LevelBlocklyEditorPage = nil;
end

function ShowBlocklyFactory()
    return CodeEnv.ShowWindow(nil, {
        draggable = false,
        width = 1200,
        height = 1000,
        url = "%ui%/Blockly/Pages/BlocklyFactory.html",
    });
end

