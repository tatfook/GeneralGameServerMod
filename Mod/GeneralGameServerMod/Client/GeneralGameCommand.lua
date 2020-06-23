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
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Config.lua");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Common.Config");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local GeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameClient");
local GeneralGameCommand = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameCommand"));


function GeneralGameCommand:ctor()
end

function GeneralGameCommand:init()
	LOG.std(nil, "info", "GeneralGameCommand", "init");
	self:InstallCommand();
end

function GeneralGameCommand:InstallCommand()
	Log:Info("InstallCommand");
	local connectGGSCmd = {
		name="connectGGS", 
		quick_ref="/connectGGS [worldId] [username]", 
		desc=[[进入联机世界 
worldId 为世界ID(未指定或为0则联机当前世界或默认世界)
username 联机世界里显示的用户名称, 未指定由系统随机生成用户名
示例:
connectGGS                        # 联机进入当前世界或默认世界
connectGGS 145                    # 联机进入世界ID为145的世界
connectGGS 145 xiaoyao            # 联机进入世界ID为145的世界, 并取名为 xiaoyao
]], 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)		
			Log:Info("run cmd: %s %s", cmd_name, cmd_text);
			local options = {};
			options, cmd_text = CmdParser.ParseOptions(cmd_text);	
			worldId, cmd_text = CmdParser.ParseInt(cmd_text);
			username, cmd_text = CmdParser.ParseString(cmd_text);
			password, cmd_text = CmdParser.ParseString(cmd_text);
			-- 隐藏参数
			ip, cmd_text = CmdParser.ParseString(cmd_text);
			port, cmd_text = CmdParser.ParseString(cmd_text);

			if (options.dev) then 
				Config:SetEnv("dev"); 
			elseif (options.test) then
				Config:SetEnv("test");
			else
				Config:SetEnv("prod");
			end
			GeneralGameClient.GetSingleton():LoadWorld(ip, port, worldId, username, password);
		end,
	};

	-- 开发环境手动加入 方便调试
	if (Config.IsDevEnv) then
		SlashCommand.GetSingleton():RegisterSlashCommand(connectGGSCmd);
	end
	Commands["connectGGS"] = connectGGSCmd;
	-- GameLogic.GetFilters():add_filters("register_command", function() 
	-- 	Commands["connectGGS"] = connectGGSCmd;
	-- end);
end
