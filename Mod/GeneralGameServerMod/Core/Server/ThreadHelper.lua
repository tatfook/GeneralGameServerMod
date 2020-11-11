--[[
Title: ThreadHelper
Author(s): wxa
Date: 2020/6/10
Desc: 线程辅助类
use the lib: 
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/ThreadHelper.lua");
local ThreadHelper = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.ThreadHelper");
-------------------------------------------------------
]]

local GGS = NPL.load("../Common/GGS.lua");

NPL.load("(gl)script/ide/System/System.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Server/Config.lua");

local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.Config");

local ThreadHelper = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

function ThreadHelper:Init()
    -- 配置初始化
    Config:StaticInit();
end


-- 初始化成单列模式
ThreadHelper:InitSingleton():Init();

-- 激活函数
local function activate()
	local action = msg and msg.action;
end

print(string.format("========================Thread(%s) Load======================", __rts__:GetName()));

NPL.this(activate);