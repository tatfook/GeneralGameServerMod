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

NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameClient.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/GeneralGameClient.lua");
local GeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local GeneralGameServerMod = commonlib.gettable("Mod.GeneralGameServerMod");
local GeneralGameCommand = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameCommand"));

GeneralGameCommand:Property("GeneralGameClient");

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
	-- 监听世界加载完成事件
	GameLogic:Connect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");

	self:InstallCommand();
end

function GeneralGameCommand:InstallCommand()
	local __this__ = self;
	local ggs = {
		mode_deny = "",
		name = "ggs",
		quick_ref = "/ggs subcmd [options] args...",
		desc = [[
subcmd: 
connect                                连接联机世界
	/ggs connect [options] [worldId] [worldName]
disconnect                             退出联机世界
	/ggs disconnect
user                                   用户命令
	/ggs user visible                  显示所有用户 不包含主玩家
	/ggs user hidden                   隐藏所有用户 不包含主玩家
	/ggs user enableclick              玩家可点击
	/ggs user disableclick             玩家不可点击
offlineuser                            离线用户命令
	/ggs offlineuser visible           显示离线用户
	/ggs offlineuser hidden            隐藏离线用户
spawnuser                              创建用户
	/ggs spawnuser username1;username2;username3...  
	示例: /ggs spawnuser xiaoyao;wxatest
setNewLiveModelAutoSync                新增活动模型是否同步(默认为 on)
	/ggs setNewLiveModelAutoSync on    允许新增活动模型同步
	/ggs setNewLiveModelAutoSync off   禁止新增活动模型同步
setLiveModelAutoSync                   所有活动模型是否同步(默认为 on)
	/ggs setLiveModelAutoSync on       允许活动模型同步
	/ggs setLiveModelAutoSync off      禁止活动模型同步
showuserinfo                           显示用户信息
	/ggs showuserinfo [username]
	示例: /ggs showuserinfo xiaoyao
cmd                                    执行软件内置命令
	/ggs cmd [options] cmdname cmdtext
	示例: /ggs cmd tip hello world	

相关文档: https://github.com/tatfook/GeneralGameServerMod/blob/master/README.md
	]],

--[[
debug 调试命令 
	/ggs debug [action]
	/ggs debug debug module            开启或关闭指定客户端模块日志
	/ggs debug serverdebug module      开启或关闭指定服务端模块日志
	/ggs debug options                 显示客户端选项信息
	/ggs debug playerinfo              显示客户端所在世界的玩家信息
	/ggs debug worldinfo               显示客户端所在世界的信息
	/ggs debug serverinfo              显示客户端所在服务器信息	
	/ggs debug serverlist              显示全网服务器列表
	/ggs debug statistics              显示全网统计信息
	/ggs debug ping                    验证是否是有效联机玩家
	/ggs debug syncForceBlockList      显示强制同步块列表

setSyncForceBlock 强制同步指定位置方块(机关类方块状态等信息默认是不同步, 可使用该指令强制去同步):
	/ggs setSyncForceBlock x y z on|off
	/ggs setSyncForceBlock 19200 5 19200 on   强制同步位置19200 5 19200的方块信息
	/ggs setSyncForceBlock 19200 5 19200 off  取消强制同步位置19200 5 19200的方块信息

	/ggs connect -isSyncBlock -isSyncCmd -areaSize=64 -silent -editable 12706

sync 世界同步
	/ggs sync -[block|cmd]
	/ggs sync -block=true  或 /ggs sync -block 开启同步方块  /ggs sync -block=false 禁用方块同步
	/ggs sync -forceBlock=false        禁用强制同步块的同步, 默认开启
filesync
	/ggs filesync                      同步所有文件
	/ggs filesync filepath             同步指定文件
blockly                                图块编程	
developer                              GGS 开发者模式
]]

		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
			GGS.INFO.Format(cmd_name .. " " .. cmd_text);
			local cmd, cmd_text = CmdParser.ParseString(cmd_text);
			if (cmd == "connect") then
				__this__:handleConnectCommand(cmd_text);
			elseif (cmd == "disconnect") then
				__this__:handleDisconnectCommand(cmd_text);
			elseif (cmd == "setSyncForceBlock") then
				__this__:handleSetSyncForceBlockCommand(cmd_text);
			elseif (cmd == "setNewLiveModelAutoSync") then
				__this__:handleSetNewLiveModelAutoSync(cmd_text);
			elseif (cmd == "setLiveModelAutoSync") then
				__this__:handleSetLiveModelAutoSync(cmd_text);
			elseif (cmd == "sync") then
				-- __this__:handleSyncCommand(cmd_text);
			elseif (cmd == "filesync") then
				__this__:handleFileSyncCommond(cmd_text);
			elseif (cmd == "blockly") then
				__this__:handleBlocklyCommond(cmd_text)
			elseif (cmd == "uieditor") then
				__this__:handleUIEditorCommond(cmd_text)
			elseif (cmd == "developer") then
				GGS.IsDeveloper = not GGS.IsDeveloper;
			elseif (cmd == "showuserinfo") then
				__this__:handleShowUserInfoCommand(cmd_text);
			end
			
			-- 确保进入联机世界
			if (not __this__:GetGeneralGameClient() or not __this__:GetGeneralGameClient():GetWorld()) then return end

			-- 联机世界命令
			if (cmd == "debug") then
				__this__:handleDebugCommand(cmd_text);
			elseif (cmd == "cmd") then
				__this__:handleCmdCommand(cmd_text);
			elseif (cmd == "offlineuser") then
				__this__:handleOfflineUserCommand(cmd_text);
			elseif (cmd == "user") then
				__this__:handleUserCommand(cmd_text);
			elseif (cmd == "spawnuser") then
				__this__:handleSpawnUser(cmd_text);
			end
		end
	}

	Commands["ggs"] = ggs;
end

function GeneralGameCommand:handleBlocklyCommond(cmd_text)
	local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
	Page.ShowBlocklyPage();
end

function GeneralGameCommand:handleUIEditorCommond(cmd_text)
	local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
	Page.ShowUIEditorPage();
end

function GeneralGameCommand:handleFileSyncCommond(cmd_text)
	local FileSync = NPL.load("Mod/GeneralGameServerMod/FileSync/FileSync.lua");
	local options, cmd_text = ParseOptions(cmd_text);	
	local filepath, cmd_text = CmdParser.ParseString(cmd_text);
	local ip = options.ip or (IsDevEnv and "127.0.0.1" or "ggs.keepwork.com");
	local port = options.port or 9000;
	FileSync:SetIpPort(ip, port);
	if (not filepath or filepath == "") then
		FileSync:GetSyncFileList();
	elseif (filepath == "refresh") then
		FileSync:Refresh();
	else
		FileSync:GetSyncFile(filepath);
	end
end

-- 用户命令
function GeneralGameCommand:handleUserCommand(cmd_text)
	local action, cmd_text = CmdParser.ParseString(cmd_text);
	local playerManager = self:GetGeneralGameClient():GetWorld():GetPlayerManager();
	if (action == "visible") then
		playerManager:ShowAllPlayers();
	elseif (action == "hidden") then
		playerManager:HideAllPlayers();
	elseif (action == "enableclick") then
		playerManager:EnableClickPlayer();
	elseif (action == "disableclick") then
		playerManager:DisableClickPlayer();
	end
end 

function GeneralGameCommand:handleOfflineUserCommand(cmd_text)
	local action, cmd_text = CmdParser.ParseString(cmd_text);
	local playerManager = self:GetGeneralGameClient():GetWorld():GetPlayerManager();
	if (action == "visible") then
		playerManager:ShowOfflinePlayers();
	elseif (action == "hidden") then
		playerManager:HideOfflinePlayers();
	end
end

-- 断开链接
function GeneralGameCommand:handleDisconnectCommand(cmd_text)
	if (not self:GetGeneralGameClient()) then return end
	self:GetGeneralGameClient():OnWorldUnloaded();
end

function GeneralGameCommand:handleConnectCommand(cmd_text)
	-- if (System.User.isAnonymousWorld) then return end 
	-- NPL.load("(gl)script/ide/System/os/os.lua");
	-- if (System.os.IsEmscripten()) then return end 
	
	local options, cmd_text = ParseOptions(cmd_text);	
	local worldId, cmd_text = CmdParser.ParseInt(cmd_text);
	local worldName, cmd_text = CmdParser.ParseString(cmd_text);

	options.worldId = (worldId and worldId ~= 0) and worldId or nil;
	options.worldName = worldName;
	options.worldKey = (options.worldKey and options.worldKey ~= "") and options.worldKey or nil;
	options.ip = (options.ip and options.ip ~= "") and options.ip or nil;
	options.port = (options.port and options.port ~= "") and options.port or nil;
	options.serverIp = (options.serverIp and options.serverIp ~= "") and options.serverIp or nil;
	options.serverPort = (options.serverPort and options.serverPort ~= "") and options.serverPort or nil;
	options.username = (options.username and options.username ~= "") and options.username or nil;
	options.password = (options.password and options.password ~= "") and options.password or nil;
	options.silent = if_else(options.silent == nil, true, options.silent and true or false);
	options.editable = options.editable == true and true or false;
	options.areaSize = tonumber(options.areaSize) or 0;
	
	-- 设置客户端
	self:SetGeneralGameClient(GeneralGameServerMod:GetClientClass(options.app) or AppGeneralGameClient);

	self:GetGeneralGameClient():LoadWorld(options);
end

function GeneralGameCommand:handleDebugCommand(cmd_text)
	local action, cmd_text = CmdParser.ParseString(cmd_text);
	if (action == "debug") then
		local module = CmdParser.ParseString(cmd_text);
		return GGS.Debug.ToggleModule(module);
	end

	self:GetGeneralGameClient():Debug(action, cmd_text);
end

function GeneralGameCommand:handleCmdCommand(cmd_text)
	local options, cmd_text = ParseOptions(cmd_text);	
	local cmd_name, cmd_text_remain = CmdParser.ParseString(cmd_text);

	-- 禁用activae setblock 命令, 防止递归
	if (not cmd_name or cmd_name == "" or cmd_name =="activate" or cmd_name == "setblock") then return end
	if (cmd_name == "ggs") then
		local subcmd_name = CmdParser.ParseString(cmd_text_remain);
		if (subcmd_name == "cmd") then
			return;
		end
	end
	
	local to = options.to or "all";
	-- 本机执行 
	if (to == "all" or to == "self") then
		CommandManager:RunCommand(cmd_text);
	end

	-- 网络执行
	self:GetGeneralGameClient():RunNetCommand(cmd_text, options);
end

-- 处理同步命令
function GeneralGameCommand:handleSyncCommand(cmd_text)
	local options, cmd_text = ParseOptions(cmd_text);
	local oldOpts = (self:GetGeneralGameClient() or GeneralGameClient):GetOptions();
	if (options.block ~= nil) then 
		oldOpts.isSyncBlock = options.block; 
	end
	if (options.cmd ~= nil) then
		oldOpts.isSyncCmd = options.cmd;
	end
	if (options.forceBlock ~= nil) then
		oldOpts.isSyncForceBlock = options.forceBlock;
	end
end

-- 设置强制同步块
function GeneralGameCommand:handleSetSyncForceBlockCommand(cmd_text)
	local x, y, z, cmd_text = CmdParser.ParsePos(cmd_text);
	if (not x or not y or not z) then return end

	local blockIndex = BlockEngine:GetSparseIndex(x, y, z);
	local onOrOff, cmd_text = CmdParser.ParseString(cmd_text);
	local data = if_else(onOrOff == "on", true, false);

	if (data) then
		GeneralGameClient:GetSyncForceBlockList():add(blockIndex);
	else
		GeneralGameClient:GetSyncForceBlockList():removeByValue(blockIndex);
	end
end

-- 新增活动模型是否同步
function GeneralGameCommand:handleSetNewLiveModelAutoSync(cmd_text)
	local onOrOff, cmd_text = CmdParser.ParseString(cmd_text);
	GeneralGameClient.options.isEnableNewLiveModelAutoSync = onOrOff == "on";
end

-- 新增活动模型是否同步
function GeneralGameCommand:handleSetLiveModelAutoSync(cmd_text)
	local onOrOff, cmd_text = CmdParser.ParseString(cmd_text);
	GeneralGameClient.options.isEnableLiveModelAutoSync = onOrOff == "on";
end

-- 打开用户面板
function GeneralGameCommand:handleShowUserInfoCommand(cmd_text)
	local username, cmd_text_remain = CmdParser.ParseString(cmd_text);
	local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua", IsDevEnv);
	Page.ShowUserInfoPage({username=(username and username ~= "") and username or nil});
end

-- 创建离线用户
function GeneralGameCommand:handleSpawnUser(cmd_text)
	local usernames = commonlib.split(cmd_text, ";");
	local playerManager = self:GetGeneralGameClient():GetWorld():GetPlayerManager();
	playerManager:SpawnPlayers(usernames);
end

-- 世界加载
function GeneralGameCommand:OnWorldLoaded()
    local isReadOnly = GameLogic.IsReadOnly();
	GeneralGameClient:GetSyncForceBlockList():clear();
	GeneralGameClient.options.isEnableNewLiveModelAutoSync = isReadOnly;  -- 默认为true
	GeneralGameClient.options.isEnableLiveModelAutoSync = isReadOnly;     -- 默认为true

	if (System.options.isCodepku) then return end 
	-- 社区自动启动GGS
	if (not AppGeneralGameClient:IsEnableGGS() and GameLogic.options:IsCommunityWorld()) then
		GameLogic.RunCommand("/ggs connect"); 
	end
end

-- 初始化成单列模式
GeneralGameCommand:InitSingleton();