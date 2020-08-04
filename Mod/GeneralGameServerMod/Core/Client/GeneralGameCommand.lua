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
			if (value == "true" or key == option) then 
				options[key] = true;
			elseif (value == "false") then 
				options[key] = false;
			else
				options[key] = value;
			end
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
	local __this__ = self;
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
			__this__:handleConnectCommand(cmd_text);
		end,
	};

	local ggscmd = {
		mode_deny = "",
		name = "ggscmd",
		quick_ref = "/ggscmd [options] cmdname cmdtext",
		desc = [[
联机命令: 命令将会在联机世界的所有玩家客户端执行.
示例:
ggscmd tip hello world   # 联机执行 /tip hello wrold 命令
ggscmd activate          # 联机执行 /activate 命令

options:
-to=all, other, self     # 命令接收者 all 所有人  other 排除发送者的其它人   self 发送者  默认为 other
-recursive               # 如果命令会引起递归执行, 需加此选项避免递归, 由机关方块触发命令执行的一般会引起递归
		]],
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
			__this__:handleCmdCommand(cmd_text);
		end
	}

	local ggs = {
		mode_deny = "",
		name = "ggs",
		quick_ref = "/ggs subcmd [options] args...",
		desc = [[
subcmd: 
connect 连接服务器
	/ggs connect [options] [worldId] [parallelWorldName]
cmd 执行软件内置命令
	/ggs cmd [options] cmdname cmdtext
	/ggs cmd tip hello world	
debug 调试命令 
	/ggs debug [action]
	/ggs debug client 显示客户端选项信息
	/ggs debug worldinfo 显示客户端连接的世界服务器信息
	/ggs debug serverinfo 显示世界服务列表	
		]],
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
			local cmd, cmd_text = CmdParser.ParseString(cmd_text);
			if (cmd == "debug") then
				__this__:handleDebugCommand(cmd_text);
			elseif (cmd == "cmd") then
				__this__:handleCmdCommand(cmd_text);
			elseif (cmd == "connect") then
				__this__:handleConnectCommand(cmd_text);
			end
		end
	}

	Commands["connectGGS"] = connectGGSCmd;
	Commands["ggs"] = ggs;
end

function GeneralGameCommand:handleConnectCommand(cmd_text)
	local options, cmd_text = ParseOptions(cmd_text);	
	local worldId, cmd_text = CmdParser.ParseInt(cmd_text);
	local parallelWorldName, cmd_text = CmdParser.ParseString(cmd_text);

	if (options.dev) then 
		Config:SetEnv("dev"); 
	elseif (options.test) then
		Config:SetEnv("test");
	elseif (options.prod) then
		Config:SetEnv("prod");
	else
		if (Config.IsDevEnv) then
			Config:SetEnv("dev");
		else
			Config:SetEnv("prod");
		end
	end
	
	options.worldId = (worldId and worldId ~= 0) and worldId or nil;
	options.parallelWorldName = parallelWorldName;
	options.ip = (options.host and options.host ~= "") and options.host or nil;
	options.port = (options.port and options.port ~= "") and options.port or nil;
	options.username = (options.username and options.username ~= "") and options.u or nil;
	options.password = (options.password and options.password ~= "") and options.p or nil;
	-- 移除选项值
	options.u, options.p = nil, nil

	self.generalGameClient = GeneralGameServerMod:GetClientClass(options.app) or AppGeneralGameClient;
	self.generalGameClient:LoadWorld(options);
end

function GeneralGameCommand:handleDebugCommand(cmd_text)
	local action, cmd_text = CmdParser.ParseString(cmd_text);
	if (self.generalGameClient) then
		self.generalGameClient:Debug(action);
	end
end

function GeneralGameCommand:handleCmdCommand(cmd_text)
	local options, cmd_text = ParseOptions(cmd_text);	
	if (not cmd_text) then return end;
	local to = options.to or "other";
	-- 本机执行 
	if (to == "all" or to == "self") then
		CommandManager:RunCommand(cmd_text);
	end

	-- 网络执行
	if (self.generalGameClient) then
		self.generalGameClient:RunNetCommand(cmd_text);
	end
end
