--[[
Title: Handler
Author(s):  wxa
Date: 2021-06-30
Desc: 网络API
use the lib:
------------------------------------------------------------
local Handler = NPL.load("Mod/GeneralGameServerMod/Server/Net/Handler.lua");
------------------------------------------------------------
]]

local VirtualConnection = NPL.load("Mod/GeneralGameServerMod/CommonLib/VirtualConnection.lua");

local Handler = commonlib.inherit(VirtualConnection, NPL.export());

function Handler:HandleMsg(msg)
	if (type(msg) ~= "table" or not msg.__cmd__) then return end
	local __cmd__, __data__ = msg.__cmd__, msg.__data__;

	if (__cmd__ == "__request_login__") then
	end
	
	print("---------------------------")
	echo(msg);
end

NPL.this(function()
    Handler:OnActivate(msg);
end);

-- local function GetConnectionByNid(nid)
-- 	return Net:GetConnectionByNid(nid);
-- end

-- local function SendTo(nid, msg)
-- 	local connection = GetConnection(nid);
-- 	if (not connection) then return end
-- 	connection:Send(msg);
-- end

-- SandBox:InstallAPI("GetConnectionByNid", GetConnectionByNid);
-- SandBox:InstallAPI("SendTo", SendTo);
