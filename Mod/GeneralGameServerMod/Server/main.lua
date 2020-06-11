
--NPL.load("/root/workspace/npl/script/trunk/");
NPL.load("(gl)script/ide/System/System.lua");
NPL.load("Mod/GeneralGameServerMod/Server/GeneralGameServer.lua");

local GeneralGameServer = commonlib.gettable("GeneralGameServerMod.Server.GeneralGameServer");

local function activate() 
   GeneralGameServer:Start();
end

NPL.this(activate);
