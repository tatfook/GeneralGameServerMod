--[[
Title: View
Author(s): wxa
Date: 2020/6/30
Desc: 视图基类
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/App/View/View.lua");
local View = commonlib.gettable("Mod.GeneralGameServerMod.App.View.View");
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/App/Api/KeepworkApi.lua");
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
local KeepworkApi = commonlib.gettable("Mod.GeneralGameServerMod.App.Api.KeepworkApi");
local View = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.App.View.View"));

-- 构造函数
function View:ctor()
    self.isShow = false;
end

-- 初始化函数
function View:Init()
    return self;
end

-- 获取API
function View:GetApi()
    return KeepworkApi;
end

-- 获取页面
function View:GetPage() 
    return self.page;
end

-- 设置页面
function View:SetPage(page)
    self.page = page;
end

-- 显示页面
function View:Show(params)
    if (params.isShowTitleBar == nil) then params.isShowTitleBar = false end
    if (params.isShow == nil) then params.isShow = true end;
    if (params.style == nil) then params.style = CommonCtrl.WindowFrame.ContainerStyle end
    if (params.DestroyOnClose == nil) then params.DestroyOnClose = true end
    if (params.zorder == nil) then params.zorder = 0 end
    if (params.allowDrag == nil) then params.allowDrag = true end
    if (params.directPosition == nil) then params.directPosition = true end
    if (params.align == nil) then params.align = "_ct" end
    if (params.cancelShowAnimation == nil) then params.cancelShowAnimation = true end
    if (params.bToggleShowHide == nil) then params.bToggleShowHide = true end
    if (params.x == nil) then params.x = -params.width / 2 end
    if (params.y == nil) then params.y = -params.height / 2 end

    System.App.Commands.Call("File.MCMLWindowFrame", params);

    -- 标记页面打开
    self.isShow = true;

    -- 监听关闭事件
    params._page.OnClose = function() 
        self.isShow = false;
        self:SetPage(nil);
    end

    -- 设置页面
    self:SetPage(params._page);

end

-- 是否显示
function View:IsShow() 
    return self.isShow;
end

-- 关闭页面
function View:Close()
    self:GetPage():CloseWindow();
end

-- 刷新页面
function View:Refresh(delta)
    if(not self:GetPage()) then return end
    self:GetPage():Refresh(delta or 0.01);
end

-- 是否认证
function View:IsSignedIn() 
    return KeepworkServiceSession:IsSignedIn();
end
