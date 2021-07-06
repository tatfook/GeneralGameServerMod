--[[
Title: Net
Author(s):  wxa
Date: 2021-06-30
Desc: 网络API
use the lib:
------------------------------------------------------------
local Net = NPL.load("Mod/GeneralGameServerMod/Server/Net/Net.lua");
------------------------------------------------------------
]]

local VirtualConnection = NPL.load("Mod/GeneralGameServerMod/CommonLib/VirtualConnection.lua");

local SandBox = NPL.load("../SandBox/SandBox.lua");

local Net = commonlib.inherit(VirtualConnection, NPL.export());

function Net:HandleMsg(msg)
	if (type(msg) ~= "table" or not msg.__cmd__) then return end
	-- SandBox:Handle("__net__", msg);
end

NPL.this(function()
	echo(msg);
    Net:OnActivate(msg);
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
