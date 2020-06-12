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
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

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
		quick_ref="/connectGGS", 
		desc="进入多人世界", 
		handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
			_guihelper.MessageBox("this is from demo command 1");
		end,
	};
end
