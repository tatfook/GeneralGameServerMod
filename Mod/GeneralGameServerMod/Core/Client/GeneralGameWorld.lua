--[[
Title: GeneralGameWorld
Author(s):  wxa
Date: 2020-06-12
Desc: 多人世界客
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Client/GeneralGameWorld.lua");
local GeneralGameWorld = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameWorld");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/World.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/NetClientHandler.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Config.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/BlockManager.lua");
local BlockManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.BlockManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local Config = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Config");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local NetClientHandler = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.NetClientHandler");
local GeneralGameWorld = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.World"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameWorld"));

local SceneContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext");
local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

function GeneralGameWorld:ctor() 
end

function GeneralGameWorld:Init(client)  
	GeneralGameWorld._super.Init(self);
	
	self.blockManager = BlockManager:new():Init(self);

	self.client = client;
	
	self.entityList = commonlib.UnorderedArraySet:new();
	-- 默认为true 由 IsSyncBlock 控制
	self.enableBlockMark = true;                                          
	-- 定时器
	local tickDuration = 1000 * 60 * 2;  -- 2 min
	-- local tickDuration = 1000 * 20;   -- debug
	self.timer = commonlib.Timer:new({callbackFunc = function(timer)
		self:Tick();
	end});
	self.timer:Change(tickDuration, tickDuration); -- 两分钟触发一次

	return self;
end

function GeneralGameWorld:GetClient()
	return self.client;
end

function GeneralGameWorld:ReplaceWorld(oldWorld)
	if(oldWorld) then
		self:GetChunkProvider():GetGenerator():AddPendingChunksFrom(oldWorld:GetChunkProvider():GetGenerator());
		oldWorld:OnWeaklyDestroyWorld();
	end
end

function GeneralGameWorld:SetName(name)
	self.name = name;
end

function GeneralGameWorld:GetName(name)
	return self.name;
end

function GeneralGameWorld:SetEnableBlockMark(enable)
	self.enableBlockMark = enable;
end

function GeneralGameWorld:GetEnableBlockMark()
	return self.enableBlockMark;
end

function GeneralGameWorld:GetBlockManager()
	return self.blockManager;
end

-- 标记更新方块
function GeneralGameWorld:MarkBlockForUpdate(x, y, z)
	if (not self:GetEnableBlockMark() or not self:GetClient():IsSyncBlock()) then return end

	self:GetBlockManager():MarkBlockForUpdate(x, y, z);
end

-- 定时发送
function GeneralGameWorld:OnFrameMove() 
	-- 30 fps  0.3s 同步一次
	self.tickBlockInfoUpdateCount = (self.tickBlockInfoUpdateCount or 0) + 1;
	if (self.tickBlockInfoUpdateCount < 10) then return end

	self:GetBlockManager():SyncBlock();
	
	self.tickBlockInfoUpdateCount = 0;
end

-- 处理鼠标事件
function GeneralGameWorld:handleMouseEvent(event)
	-- local scene = GameLogic.GetSceneContext();
	-- local result = scene:CheckMousePick();
	-- Log:Info(commonlib.serialize(result, true));
	-- -- Log:Info(commonlib.serialize(event, true));
end

-- 维持用户在线
function GeneralGameWorld:Tick() 
	if (self.netHandler) then
		self.netHandler:SendTick();
	end
end

function GeneralGameWorld:Login(params) 
	local ip = params.ip or "127.0.0.1";
	local port = params.port or "9000";
	local worldId = params.worldId;
	local parallelWorldName = params.parallelWorldName;
	local username = params.username;  -- 若不存在使用 keepwork 的用户名
	local password = params.password;
	local thread = params.thread or "gl";

	self.username = username;
	self.password = password;

	-- 清理旧连接
	if (self.netHandler) then
		 self.netHandler:Cleanup();
	end

	-- 连接服务器
	local NetClientHandlerClass = self:GetClient():GetNetClientHandlerClass() or NetClientHandler;
	self.netHandler = NetClientHandlerClass:new():Init({
		ip = ip, 
		port = port, 
		worldId = worldId, 
		username = username, 
		password = password,
		parallelWorldName = parallelWorldName,
	}, self);
	
	GameLogic:Connect("frameMoved", self, self.OnFrameMove, "UniqueConnection");

	self.isLogin = true;
end

function GeneralGameWorld:Logout() 
	Log:Info("logout world");

	if(self.netHandler) then
		self.netHandler:Cleanup();
	end

	self:GetBlockManager():CleanUp();

	-- 清空并删除实体
	for i = 1, #self.entityList do
		-- Log:Debug("destroy entity:", self.entityList[i].entityId);
		self.entityList[i]:Destroy();
	end
	self.entityList:clear();

	-- 解除链接关系
	GameLogic:Disconnect("frameMoved", self, self.OnFrameMove, "DisconnectOne");
	
	-- 清除定时任务
	self.timer:Change();

	self.isLogin = false;
end

function GeneralGameWorld:OnExit()
	GeneralGameWorld._super.OnExit(self);

	self:Logout();
end

function GeneralGameWorld:GetNetHandler()
	return self.netHandler;
end

function GeneralGameWorld:IsLogin()
	return self.isLogin;
end

function GeneralGameWorld:AddEntity(entity)
	self.entityList:add(entity);
end

function GeneralGameWorld:RemoveEntity(entity)
	self.entityList:removeByValue(entity);
end

function GeneralGameWorld:GetEntityList()
	return self.entityList;
end
