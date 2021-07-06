
--[[
Title: SandBox
Author(s):  wxa
Date: 2021-06-30
Desc: MySql
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Server/SandBox/SandBox.lua");
------------------------------------------------------------
]]
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");

local API = NPL.load("./API/API.lua");

local SandBox = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

-- 开放接口
CommonLib.AddPublicFile("Mod/GeneralGameServerMod/CommonLib/Connection.lua");
CommonLib.AddPublicFile("Mod/GeneralGameServerMod/CommonLib/VirtualConnection.lua");
CommonLib.AddPublicFile("Mod/GeneralGameServerMod/Server/Net/Net.lua");

function SandBox:ctor()
    self.__md5__ = {};                      -- md5 集
	self.__cmd_handler_map__ = {};          -- 命令处理程序
	self.__env__ = {                        -- 执行环境
        ___modules___ = {},                 -- 文件模块
		__modules__ = {},                   -- 自定义模块

		__loadfile__ = function(filepath) return self:LoadFile(filepath) end,
		__loadstring__ = function(text) return self:LoadString(text) end,
		__cmd__ = function(cmd, callback) return self:RegisterCmdHandler(cmd, callback) end,
    };

	self.__env__._G = self.__env__;  -- 设置全局G

	API(self.__env__);

    -- self:LoadFile("Mod/GeneralGameServerMod/Server/SandBox/API/Test.lua")
end

function SandBox:InstallAPI(name, func)
	self.__env__[name] = func;
end

function SandBox:RegisterCmdHandler(cmd, handler)
	self.__cmd_handler_map__[cmd] = handler;
end

function SandBox:LoadString(text, filename)
	-- 防止重复执行
	local md5 = ParaMisc.md5(text);
	if (self.__md5__[md5]) then return end
	self.__md5__[md5] = true;

	-- 生成函数
	local code_func, errormsg = loadstring(text, "loadstring:" .. filename);
	if errormsg then return print("Independent:LoadFile LoadString Failed", filename, errormsg) end

	-- 设置代码环境
	setfenv(code_func, self.__env__);
	
	-- 执行代码
	self:Run(code_func);
end

function SandBox:LoadFile(filepath)
    local file = ParaIO.open(filepath, "rb");
    if(not file:IsValid()) then return file:close() end

	local text = file:GetText(0, -1);
	file:close();
	
	-- 生成防止重复执行代码, 未知原因会重复执行
	local inner_text = string.format([[
		local __filename__ = "%s";
		if (___modules___[__filename__]) then return end
		___modules___[__filename__] = {__filename__ = __filename__, __loaded__ = false};
	]], filepath);
	
	text = inner_text .. "\n" .. text .. "\n___modules___[__filename__].__loaded__ = true";

	self:LoadString(text, filepath);

	return;
end

function SandBox:Run(func, ...)
    if (type(func) ~= "function") then return end
	return func(...);
    -- coroutine.resume(coroutine.create(func), ...);
end

function SandBox:Handle(__cmd__, ...)
	local handler = self.__cmd_method_map__[__cmd__] or __cmd__;
	if (type(handler) == "function") then return self:Run(handler, msg) end
    self:Run(self.__env__[handler], ...); 
end

SandBox:InitSingleton();