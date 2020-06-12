
--NPL.load("/root/workspace/npl/script/trunk/");
NPL.load("(gl)script/ide/System/System.lua");
-- NPL.load("Mod/GeneralGameServerMod/Common/ConnectionBase.lua");
-- NPL.load("Mod/GeneralGameServerMod/Common/Connections.lua");
-- NPL.load("Mod/GeneralGameServerMod/Common/ConnectionTCP.lua");
NPL.load("Mod/GeneralGameServerMod/Server/GeneralGameServer.lua");

local GeneralGameServer = commonlib.gettable("Mod.GeneralGameServerMod.Server.GeneralGameServer");

local function activate() 
   GeneralGameServer:Start();
end

NPL.this(activate);
