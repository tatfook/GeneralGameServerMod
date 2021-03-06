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

NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");

local Vue = NPL.load("./Vue/Vue.lua", IsDevEnv);
local Page = NPL.export();
local pages = {};
local _3d_pages = {};
local inited = false;

-- 世界加载
local function OnWorldLoaded()
end

-- 世界退出
local function OnWorldUnloaded()
    for _, page in pairs(_3d_pages) do 
        page:CloseWindow();
    end
end

-- 初始化
function Page.StaticInit()
    if (inited) then return end
    inited = true;

    GameLogic:Connect("WorldLoaded", nil, OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", nil, OnWorldUnloaded, "UniqueConnection");
end

-- 绑定页面到告示牌
function Page.BindPageToBlockSign(blockX, blockY, blockZ, page)
    if (not blockX or not blockY or not blockZ or not page) then return end
    local entity = BlockEngine:GetBlockEntity(blockX, blockY, blockZ); 
    if (not entity) then return print("3D 实体不存在") end
    entity.cmd = "<div></div>";
    entity:Refresh();
    local obj = entity:GetInnerObject();
    obj:ShowHeadOnDisplay(true, 0);
    obj:SetHeadOnUITemplateName(page:GetWindowName(), 0);
    obj:SetHeadOnOffset(0, 0.42, 0.37, 0);
    obj:SetField("HeadOn3DFacing", -1.57);
end

-- 显示页面
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

-- 显示3DUI
function Page.Show3D(G, params)
    Page.StaticInit();

    params = params or {};
    if (not params.url) then return end
    local page = _3d_pages[params.url] or Vue:new();
    _3d_pages[params.url] = page;
    
    if (page:GetNativeWindow()) then 
        page:CloseWindow();
    end

    params.G = G;
    params.is3DUI = true;

    page:Show(params);

    Page.BindPageToBlockSign(params.blockX, params.blockY, params.blockZ, page);

    return page;
end

function Page.ShowVue3DTestPage(G, params)
    if (IsDevEnv) then
        if (_G.Vue3DTestPage) then
            _G.VueTestPage:CloseWindow();
        end        
        _G.VueTestPage = Vue:new();
    end

    params = params or {};
    params.url = params.url or "%vue%/Example/3D.html";
    params.is3DUI = true;
    params.G = G;

    _G.VueTestPage:Show(params);

    Page.BindPageToBlockSign(params.blockX, params.blockY, params.blockZ, _G.VueTestPage);
    
    return _G.VueTestPage;
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
    params.draggable = true;
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

local SubTitlePage = Vue:new();
function Page.ShowSubTitlePage(G, params)
    params = params or {};
    G = G or {};

    if (not G.text or G.text == "") then return end 
    
    G.isPlayVoice = if_else(G.isPlayVoice == nil, true, G.isPlayVoice);  -- 是否播放语音
    G.isAutoClose = if_else(G.isAutoClose == nil, true, G.isAutoClose);  -- 是否自动关闭

    params.url = "%ui%/Page/Common/SubTitle.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or 200;
    params.alignment = "_lb";

    if (IsDevEnv) then
        if (_G.VueTestPage) then
            _G.VueTestPage:CloseWindow();
        end        
        _G.VueTestPage = SubTitlePage;
    end

    SubTitlePage:Show(params);
    return SubTitlePage; 
end
