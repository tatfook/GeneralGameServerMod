--[[
Title: GGSCommand
Author(s):  wxa
Date: 2020-06-12
Desc: 多人世界相关命令实现
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Client/GeneralGameCommand.lua");
local GeneralGameCommand = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameCommand");
GeneralGameCommand:init();
------------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameClient.lua");
local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Config");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local GeneralGameServerMod = commonlib.gettable("Mod.GeneralGameServerMod");
local GeneralGameCommand = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameCommand"));

function ParseOption(cmd_text)
	local value, cmd_text_remain = cmd_text:match("^%s*%-([%w_]+%S+)%s*(.*)$");
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
			key, value = option:match("([%w_]+)=?(%S*)");
			options[key] = key == option and true or value;
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

function GeneralGameCommand:GetGeneralGameClient()
	return self.generalGameClient;
end

function GeneralGameCommand:InstallCommand()
	Log:Info("InstallCommand");
	local connectGGSCmd = {
		mode_deny = "",  -- 暂时支持任意模式联机
		name="connectGGS",  -- /connectGGS -test 
		quick_ref="/connectGGS [options] [worldId] [parallelWorldName]", 
		desc=[[进入联机世界 
worldId 为世界ID(未指定或为0则联机当前世界或默认世界)
parallelWorldName 平行世界名, 可选. 指定世界的副本世界
示例:
connectGGS                        # 联机进入当前世界或默认世界
connectGGS 145                    # 联机进入世界ID为145的世界
connectGGS 145 parallel           # 联机进入世界ID为145的平行世界 parallel

options:
-isSyncBlock 同步方块信息
-isSyncCmd   同步命令
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
			
			options.worldId = (worldId and worldId ~= 0) and worldId or nil;
			options.parallelWorldName = parallelWorldName;
			options.ip = (options.host and options.host ~= "") and options.host or nil;
			options.port = (options.port and options.port ~= "") and options.port or nil;
			options.username = (options.u and options.u ~= "") and options.u or nil;
			options.password = (options.p and options.p ~= "") and options.p or nil;

			self.generalGameClient = GeneralGameServerMod:GetClientClass(options.app) or AppGeneralGameClient;
			self.generalGameClient:LoadWorld(options);
		end,
	};

	local ggscmd = {
		mode_deny = "",
		name = "ggscmd",
		quick_ref = "/ggscmd cmdname cmdtext",
		desc = [[
联机命令: 命令将会在联机世界的所有玩家客户端执行.
示例:
ggscmd tip hello world   # 联机执行 /tip hello wrold 命令
ggscmd activate          # 联机执行 /activate 命令
		]],
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
			if (not cmd_text) then return end;
			-- 本机执行 
			CommandManager:RunCommand(cmd_text);
			-- 网络执行
			if (self.generalGameClient) then
				self.generalGameClient:RunNetCommand(cmd_text);
			end
		end
	}

	-- 开发环境手动加入 方便调试
	if (Config.IsDevEnv) then
		SlashCommand.GetSingleton():RegisterSlashCommand(connectGGSCmd);
		SlashCommand.GetSingleton():RegisterSlashCommand(ggscmd);
	end

	Commands["connectGGS"] = connectGGSCmd;
	Commands["ggscmd"] = ggscmd;
	-- GameLogic.GetFilters():add_filters("register_command", function() 
	-- 	Commands["connectGGS"] = connectGGSCmd;
	-- end);
end
