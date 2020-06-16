--[[
Title: GGSCommand
Author(s):  wxa
Date: 2020-06-12
Desc: 多人世界相关命令实现
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/GGSCommand.lua");
local GGSCommand = commonlib.gettable("Mod.GeneralGameServerMod.GGSCommand");
------------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Client/GeneralGameClient.lua");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local GeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameClient");
local GGSCommand = commonlib.inherit(nil,commonlib.gettable("Mod.GeneralGameServerMod.GGSCommand"));

function GGSCommand:ctor()
end

function GGSCommand:init()
	LOG.std(nil, "info", "GGSCommand", "init");
	self:InstallCommand();
end

function GGSCommand:InstallCommand()
	Commands["connectGGS"] = {
		name="connectGGS", 
		quick_ref="/connectGGS ip port ", 
		desc="多人世界", 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
			LOG.debug("-----------connectGGS------------");
			LOG.debug(cmd_name);
			LOG.debug(cmd_text);
			LOG.debug(cmd_params);
			local ip, port;
			ip, cmd_text = CmdParser.ParseString(cmd_text);
			port, cmd_text = CmdParser.ParseInt(cmd_text);

			local client = GeneralGameClient:new():Init();
			client:LoadWorld(ip or "127.0.0.1",  port or 9000, 12348);
		end,
	};
end
