--[[
Title: KeepworkApi
Author(s): wxa
Date: 2020/7/2
Desc: keepwork api
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/View/Api.lua");
local Api = commonlib.gettable("Mod.GeneralGameServerMod.View.Api");
Api:GetSingleton():Show();
-------------------------------------------------------
]]
NPL.load("Mod/GeneralGameServerMod/Api/KeepworkApi.lua");
NPL.load("Mod/GeneralGameServerMod/View/View.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");

local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local Api = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.View.View"), commonlib.gettable("Mod.GeneralGameServerMod.View.Api"));

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
        width = 870,
        height = 650,
        title = "API 测试",
    });
end


function Api:Test() 
    Log:Info("API 测试");
end
