--[[
Title: UserInfo
Author(s): wxa
Date: 2020/6/30
Desc: 用户信息详情页
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/View/UserInfo.lua");
local UserInfo = commonlib.gettable("Mod.GeneralGameServerMod.View.UserInfo");
UserInfo:GetSingleton():Show();
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/View/View.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local UserInfo = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.View.View"), commonlib.gettable("Mod.GeneralGameServerMod.View.UserInfo"));

function UserInfo:ctor() 
end

function UserInfo:Init()
    self._super:Init();
    return self;
end

-- 显示页面
function UserInfo:Show()
    self._super:Show({
        url = "Mod/GeneralGameServerMod/View/UserInfo.html",
        name = "Mod.GeneralGameServerMod.View.UserInfo",
        width = 870,
        height = 650,
        title = "用户信息",
    });
end


function UserInfo:Test() 
    Log:Info("hello world1");
end
