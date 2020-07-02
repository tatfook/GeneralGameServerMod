--[[
Title: View
Author(s): wxa
Date: 2020/6/30
Desc: 视图基类
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/View/View.lua");
local View = commonlib.gettable("Mod.GeneralGameServerMod.View.View");
-------------------------------------------------------
]]

local View = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.View.View"));

-- 单列模式
local g_instance_map = {};
function View:GetSingleton()
    if(not g_instance_map[self]) then
		g_instance_map[self] = self:new():Init();
    end

    return g_instance_map[self];
end
-- 构造函数
function View:ctor()
end

-- 初始化函数
function View:Init()
    return self;
end

-- 获取页面
function View:GetPage() 
    if (not self.page) then
        self.page = document:GetPageCtrl();
    end
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

    self:SetPage(params._page);

end

-- 关闭页面
function View:Close()
    self:GetPage():CloseWindow();
end
