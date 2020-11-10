--[[
Title: ConnectionBase
Author(s): wxa
Date: 2020/6/12
Desc: base connection
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/Connection.lua");
local Connection = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Connection");
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Core/Common/Connection.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/NetServerHandler.lua");
local NetServerHandler = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.NetServerHandler");
local Connection = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Connection"), NPL.export());

-- 派生类重载次函数
function Connection.OnConnection(msg)
	return NetServerHandler:new():Init(msg.nid or msg.tid):GetPlayerConnection();
end

local function activate()
	Connection.OnActivate(msg);
end

NPL.this(activate);