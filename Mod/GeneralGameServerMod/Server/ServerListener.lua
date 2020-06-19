--[[
Title: ServerListener
Author(s): wxa
Date: 2020/6/12
Desc: accept incoming connections. this is a singleton class
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerListener.lua");
local ServerListener = commonlib.gettable("MyCompany.Aries.Game.Network.ServerListener");
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Network/ServerListener.lua");
NPL.load("Mod/GeneralGameServerMod/Server/NetServerHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local NetServerHandler = commonlib.gettable("Mod.GeneralGameServerMod.Server.NetServerHandler");
local ServerListener = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Network.ServerListener"), commonlib.gettable("Mod.GeneralGameServerMod.Server.ServerListener"));

-- whenever an unknown pending message is received. 
function ServerListener:OnAcceptIncomingConnection(msg)
	local tid;
	if(msg and msg.tid) then
		tid = msg.tid;
	end
	if(tid) then
		if(self.pendingConnectionCount > self.max_pending_connection) then
			Log:Info("max pending connection reached ignored connection %s", tid);
		end
		self.connectionCounter = self.connectionCounter + 1;
		local net_handler = NetServerHandler:new():Init(tid);
		self:AddPendingConnection(tid, net_handler);
	end
end
