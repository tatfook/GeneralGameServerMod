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

function ParseOption(cmd_text)
	local value, cmd_text_remain = cmd_text:match("^%s*%-([%w_=]+)%s*(.*)$");
	if(value) then
		return value, cmd_text_remain;
	end
	return nil, cmd_text;
end

function ParseOptions(cmd_text)
	local options = {};
	local option, cmd_text_remain = nil, cmd_text;
	while(cmd_text_remain) do
		option, cmd_text_remain = ParseOption(cmd_text_remain);
		if(option) then
			key, value = option:match("([%w_]+)=?([%w_]*)");
			options[key] = value;
		else
			break;
		end
	end
	return options, cmd_text_remain;
end


function GeneralGameCommand:ctor()
end

function GeneralGameCommand:init()
	LOG.std(nil, "info", "GeneralGameCommand", "init");
	self:InstallCommand();
end

function GeneralGameCommand:InstallCommand()
	Log:Info("InstallCommand");
	local connectGGSCmd = {
		mode_deny = "",  -- 暂时支持任意模式联机
		name="connectGGS",  -- /connectGGS -test 
		quick_ref="/connectGGS [worldId] [parallelWorldName]", 
		desc=[[进入联机世界 
worldId 为世界ID(未指定或为0则联机当前世界或默认世界)
parallelWorldName 平行世界名, 可选. 指定世界的副本世界
示例:
connectGGS                        # 联机进入当前世界或默认世界
connectGGS 145                    # 联机进入世界ID为145的世界
connectGGS 145 parallel           # 联机进入世界ID为145的平行世界 parallel
]], 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)		
			Log:Info("run cmd: %s %s", cmd_name, cmd_text);
			local options = {};
			options, cmd_text = ParseOptions(cmd_text);	
			worldId, cmd_text = CmdParser.ParseInt(cmd_text);
			parallelWorldName, cmd_text = CmdParser.ParseString(cmd_text);
		
			if (options.dev) then 
				Config:SetEnv("dev"); 
			elseif (options.test) then
				Config:SetEnv("test");
			else
				Config:SetEnv("prod");
			end
			Log:Info(options);
			GeneralGameClient.GetSingleton():LoadWorld({
				worldId = (worldId and worldId ~= 0) and worldId or nil,
				parallelWorldName = parallelWorldName,
				ip = (options.host and options.host ~= "") and options.host or nil,
				port = (options.port and options.port ~= "") and options.port or nil,
				username = (options.u and options.u ~= "") and options.u or nil,
				password = (options.p and options.p ~= "") and options.p or nil,
			});
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
