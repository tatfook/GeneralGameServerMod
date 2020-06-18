--[[
Title: GGSCommand
Author(s):  wxa
Date: 2020-06-12
Desc: 多人世界相关命令实现
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Client/GeneralGameCommand.lua");
local GeneralGameCommand = commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameCommand");
GeneralGameCommand:init();
------------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Client/GeneralGameClient.lua");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local GeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameClient");
local GeneralGameCommand = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameCommand"));

local IsDevEnv = ParaEngine.GetAppCommandLineByParam("IsDevEnv","false") == "true";

function GeneralGameCommand:ctor()
end

function GeneralGameCommand:init()
	LOG.std(nil, "info", "GeneralGameCommand", "init");
	self:InstallCommand();
end

function GeneralGameCommand:InstallCommand()
	local connectGGSCmd = {
		name="connectGGS", 
		quick_ref="/connectGGS worldId username", 
		desc="进入联机世界, worldId 为世界ID (默认: 0)", 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
			LOG.debug("-----------connectGGS------------");
			local ip = IsDevEnv and "127.0.0.1" or "120.132.120.175";
			local port = 9000;
			
			worldId, cmd_text = CmdParser.ParseInt(cmd_text);
			username, cmd_text = CmdParser.ParseString(cmd_text);
			password, cmd_text = CmdParser.ParseString(cmd_text);
			
			local client = GeneralGameClient:new():Init();
			client:LoadWorld(ip,  port, worldId, username, password);
		end,
	};

	-- 开发环境手动加入 方便调试
	if (IsDevEnv) then
		SlashCommand.GetSingleton():RegisterSlashCommand(connectGGSCmd);
	end
	Commands["connectGGS"] = connectGGSCmd;
	-- GameLogic.GetFilters():add_filters("register_command", function() 
	-- 	Commands["connectGGS"] = connectGGSCmd;
	-- end);
end
