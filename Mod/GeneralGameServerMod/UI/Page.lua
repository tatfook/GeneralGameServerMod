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

local MacrosExtend = NPL.load("Mod/GeneralGameServerMod/UI/Page/Macro/MacrosExtend.lua", IsDevEnv);

local Vue = NPL.load("./Vue/Vue.lua", IsDevEnv);
local Page = NPL.export();
local pages = {};
local __auto_close_pages__ = {};
local _3d_pages = {};
local inited = false;
local windows = {};

if (IsDevEnv) then
    _G.pages = _G.pages or {};
    pages = _G.pages;
end

-- 世界加载
local function OnWorldLoaded()
end

-- 世界退出
local function OnWorldUnloaded()
    for _, page in pairs(_3d_pages) do 
        page:CloseWindow();
    end

    for _, page in ipairs(__auto_close_pages__) do
        page:CloseWindow();
    end
end

-- 注册组件
function Page.RegisterComponent(tagname, tagclass)
    Vue.Register(tagname, tagclass);
end

-- 注册窗口
function Page.RegisterWindow(params)
    local window = {params = params, G = params.G};
    windows[params.windowName] = window;
end

-- 打开窗口
function Page.ShowWindow(windowName, codeblock)
    local window = windows[windowName];
    if (not window) then return end
    if (window.page) then window.page:CloseWindow() end 
    window.page = Page.Show(window.G, window.params);

    if (codeblock and not window.isRegisterCodeBlockStopEvent) then
        window.isRegisterCodeBlockStopEvent = true;
        codeblock:Connect("codeUnloaded", function()
            Page.CloseWindow(windowName);
        end);
    end
end

-- 关闭窗口
function Page.CloseWindow(windowName)
    local window = windows[windowName];
    if (not window or not window.page) then return end
    window.page:CloseWindow();
end

-- 获取窗口
function Page.GetWindow(windowName)
    local window = windows[windowName];
    return window and window.page;
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
    obj:SetHeadOnUITemplateName(page:GetWindowId(), 0);
    obj:SetHeadOnOffset(0, 0.42, 0.37, 0);
    obj:SetField("HeadOn3DFacing", -1.57);
end

-- 显示页面
function Page.Show(G, params, isNew)
    params = params or {};
    local key = params.html or params.template or params.url;
    if (not key) then return end
    
    if (not isNew and pages[key] and pages[key]:GetNativeWindow()) then pages[key]:CloseWindow() end
    local page = (not IsDevEnv and pages[key]) and pages[key] or Vue:new();
    if (isNew) then 
        page = Vue:new();
    else
        pages[key] = page;
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
    params.draggable = true;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    BlocklyPage:Show(params);

    return BlocklyPage;
end

local BlocklyFactoryPage = Vue:new(G, params);
function Page.ShowBlocklyFactoryPage()
    params = params or {};

    params.url = "%ui%/Blockly/Pages/BlocklyFactory.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or 1200;
    params.height = params.height or 800;
    params.windowName = "__BlocklyFactory__";
    BlocklyFactoryPage:Show(params);
    return BlocklyFactoryPage;
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
    params.url = "%ui%/Page/Common/MessageBox.html";
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
    params.url = "%ui%/Blockly/Pages/UIEditor.html";
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

local ShenTongBeiPage = Vue:new();
function Page.ShowShenTongBeiPage(G, params)
    __auto_close_pages__[ShenTongBeiPage] = ShenTongBeiPage;

    params = params or {};
    params.url = "%ui%/App/RedSummerCamp/ShenTongBei.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    params.fixedRootScreenWidth = params.fixedRootScreenWidth or 1280;
    params.fixedRootScreenHeight = params.fixedRootScreenHeight or 720;
    ShenTongBeiPage:Show(params);
    return ShenTongBeiPage;
end

local ShenTongBeiCourePage = Vue:new();
function Page.ShowShenTongBeiCourePage()
    __auto_close_pages__[ShenTongBeiCourePage] = ShenTongBeiCourePage;
    params = params or {};
    params.url = "%ui%/App/RedSummerCamp/Course.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    params.fixedRootScreenWidth = params.fixedRootScreenWidth or 1280;
    params.fixedRootScreenHeight = params.fixedRootScreenHeight or 720;
    ShenTongBeiCourePage:Show(params);
end

local ShenTongBeiConstituionPage = Vue:new();
function Page.ShowShenTongBeiConstituionPage()
    print("ShowShenTongBeiConstituionPage")
    __auto_close_pages__[ShenTongBeiConstituionPage] = ShenTongBeiConstituionPage;
    params = params or {};
    params.url = "%ui%/App/RedSummerCamp/Constitution.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    params.fixedRootScreenWidth = params.fixedRootScreenWidth or 1280;
    params.fixedRootScreenHeight = params.fixedRootScreenHeight or 720;
    ShenTongBeiConstituionPage:Show(params);
end

local ShenTongBeiCompetitionPage = Vue:new();
function Page.ShowShenTongBeiCompetitionPage()
    print("ShenTongBeiCompetitionPage")
    __auto_close_pages__[ShenTongBeiCompetitionPage] = ShenTongBeiCompetitionPage;
    params = params or {};
    params.url = "%ui%/App/RedSummerCamp/Competition.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    params.fixedRootScreenWidth = params.fixedRootScreenWidth or 1280;
    params.fixedRootScreenHeight = params.fixedRootScreenHeight or 720;
    ShenTongBeiCompetitionPage:Show(params);
end

local ShenTongBeiZiZhiPage = Vue:new();
function Page.ShowShenTongBeiZiZhiPage()
    __auto_close_pages__[ShenTongBeiZiZhiPage] = ShenTongBeiZiZhiPage;
    params = params or {};
    params.url = "%ui%/App/RedSummerCamp/Qualification.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    params.fixedRootScreenWidth = params.fixedRootScreenWidth or 1280;
    params.fixedRootScreenHeight = params.fixedRootScreenHeight or 720;
    ShenTongBeiPage:Show(params);
end

local BigImagePage = Vue:new();
function Page.ShowBigImagePage(G, params)
    __auto_close_pages__[BigImagePage] = BigImagePage;
    params = params or {};
    params.url = "%ui%/Page/Common/BigImage.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    BigImagePage:Show(params);
    return BigImagePage;
end

local MatataLabPage = Vue:new();
function Page.ShowMatataLabPage()
    __auto_close_pages__[MatataLabPage] = MatataLabPage;
    MatataLabPage:CloseWindow();
    NPL.load("Mod/GeneralGameServerMod/UI/MatataLab/MatataLab.lua", IsDevEnv);
    params = params or {};
    params.url = "%ui%/MatataLab/MatataLab.html";
    params.draggable = false;
    params.G = G;
    params.width = 1280;
    params.height = 720;
    -- params.fixedRootScreenWidth = params.fixedRootScreenWidth or 1280;
    -- params.fixedRootScreenHeight = params.fixedRootScreenHeight or 720;
    MatataLabPage:Show(params);
    return MatataLabPage;
end

--[[
打开冬令营主面板
defaultTabIndex:
    "quweibiancheng" 趣味编程
    "kuailejianzao"  快乐建造
    "jingcaidonghua" 精彩动画
    "lajifenlei"     垃圾分类
    "tiyujinsai"     体育竞赛
]]  
function Page.ShowWinterCampMainWindow(defaultTabIndex)
    local Independent = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Independent.lua");
    local independent = Independent:GetSingletonInstance();
    independent:Start("Mod/GeneralGameServerMod/UI/App/WinterCamp/WinterCamp.lua");
    independent:GetCodeEnv().ShowWinterCampMainWindow(defaultTabIndex);
    -- Independent:LoadString([[
    --     ShowWinterCampMainWindow();
    -- ]]);
end

