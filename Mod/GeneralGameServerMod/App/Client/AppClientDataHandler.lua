--[[
Title: AppClientDataHandler
Author(s): wxa
Date: 2020/7/9
Desc: 网络数据处理类
use the lib:
------------------------------------------------------------
local AppClientDataHandler = NPL.load("Mod/GeneralGameServerMod/App/Client/AppClientDataHandler.lua");
-------------------------------------------------------
]]
NPL.load("Mod/GeneralGameServerMod/App/Client/EntitySync.lua");
local EntitySync = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.EntitySync");

NPL.load("Mod/GeneralGameServerMod/Core/Client/ClientDataHandler.lua");
local AppClientDataHandler = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.ClientDataHandler"), NPL.export());

function AppClientDataHandler:RecvData(data)
    AppClientDataHandler._super.RecvData(self, data);
    
	if (EntitySync:OnRecvData(data)) then return end 

    GameLogic.GetFilters():apply_filters("ggs_net_data", nil, data, self);
end

function AppClientDataHandler:OnLogin()
	EntitySync:OnLogin();
end