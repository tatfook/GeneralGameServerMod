--[[
Title: ServerConnection
Author(s): wxa
Date: 2020/6/10
Desc: 线程辅助类
use the lib: 
-------------------------------------------------------
local AppServerDataHandler = NPL.load("Mod/GeneralGameServerMod/App/Server/AppServerDataHandler.lua");
-------------------------------------------------------
]]

-- 数据处理基类
local ServerDataHandler = NPL.load("Mod/GeneralGameServerMod/Core/Server/ServerDataHandler.lua");

-- 数据处理导出类
local AppServerDataHandler = commonlib.inherit(ServerDataHandler, NPL.export());

-- 收到数据处理函数
function AppServerDataHandler:RecvData(data)
	-- GGS.DEBUG("AppServerConnection", data);

	self:SendDataToAllPlayer(data);

	-- -- 发送数据给当前用户
	-- if (data == "player") then 
	-- 	self:SendData("hello player");
	-- end

	-- -- 发送数据给所有在线用户  第二个参数 true: 接收者包含当前用户  false: 接收者不包含当前用户 
	-- if (data == "all player") then
	-- 	self:SendDataToAllPlayer("hello all player", false);
	-- end
end
