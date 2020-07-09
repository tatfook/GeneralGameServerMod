--[[
Title: KeepworkApi
Author(s): wxa
Date: 2020/7/2
Desc: keepwork api
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/App/View/Api.lua");
local Api = commonlib.gettable("Mod.GeneralGameServerMod.App.View.Api");
Api:GetSingleton():Show();
-------------------------------------------------------
]]
NPL.load("Mod/GeneralGameServerMod/App/Api/KeepworkApi.lua");
NPL.load("Mod/GeneralGameServerMod/App/View/View.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");

local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local Api = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.App.View.View"), commonlib.gettable("Mod.GeneralGameServerMod.App.View.Api"));

function Api:ctor() 
end

function Api:Init()
    self._super:Init();
    return self;
end

-- 显示页面
function Api:Show()
    self._super:Show({
        url = "Mod/GeneralGameServerMod/View/Api.html",
        name = "Mod.GeneralGameServerMod.View.Api",
        width = 300,
        height = 300,
        title = "API 测试",
    });
end


function Api:Test() 
    Log:Info("API 测试");
end


-- 初始化成单列模式
Api:InitSingleton();