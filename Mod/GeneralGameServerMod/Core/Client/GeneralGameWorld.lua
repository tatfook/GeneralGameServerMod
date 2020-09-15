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
NPL.load("Mod/GeneralGameServerMod/Core/Client/BlockManager.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Client/PlayerManager.lua");
local PlayerManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.PlayerManager");
local BlockManager = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.BlockManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local NetClientHandler = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.NetClientHandler");
local GeneralGameWorld = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.World.World"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.GeneralGameWorld"));

local SceneContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext");
local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

GeneralGameWorld:Property("WorldId", 0);      -- 世界ID
GeneralGameWorld:Property("Client");          -- 所属客户端
GeneralGameWorld:Property("PlayerManager");   -- 玩家管理器
GeneralGameWorld:Property("BlockManager");    -- 方块管理器
GeneralGameWorld:Property("EnableBlockMark");    -- 是否使能方块标记  默认为true 由 IsSyncBlock 控制

function GeneralGameWorld:ctor() 
end

function GeneralGameWorld:Init(client)  
	GeneralGameWorld._super.Init(self);
	
	self:SetBlockManager(BlockManager:new():Init(self));
	self:SetPlayerManager(PlayerManager:new():Init(self));
	self:SetClient(client);
	self:SetEnableBlockMark(self:GetClient():IsSyncBlock());
	
	-- 定时器
	local tickDuration = 1000 * 60 * 2;  -- 2 min
	-- local tickDuration = 1000 * 20;   -- debug
	self.timer = commonlib.Timer:new({callbackFunc = function(timer)
		self:Tick();
	end});
	self.timer:Change(tickDuration, tickDuration); -- 两分钟触发一次

	return self;
end

function GeneralGameWorld:ReplaceWorld(oldWorld)
	if(oldWorld) then
		self:GetChunkProvider():GetGenerator():AddPendingChunksFrom(oldWorld:GetChunkProvider():GetGenerator());
		oldWorld:OnWeaklyDestroyWorld();
	end
end

-- 标记更新方块
function GeneralGameWorld:MarkBlockForUpdate(x, y, z)
	-- if (not self:GetEnableBlockMark() or not self:GetClient():IsSyncBlock()) then return end
	-- 未开启同步也进行标记但不发送, 性能稍差, 可使用上述条件.  此条件好处是尽可能标记多的修改过的方块, 而不是开启同步了才开始标记 
	if (not self:GetEnableBlockMark()) then return end

	self:GetBlockManager():MarkBlockForUpdate(x, y, z);
end

-- 定时发送
function GeneralGameWorld:OnFrameMove() 
	-- 未开启同步则直接退出
	if (not self:GetClient():IsSyncBlock()) then return end

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
	-- GGS.INFO(commonlib.serialize(result, true));
	-- -- GGS.INFO(commonlib.serialize(event, true));
end

-- 维持用户在线
function GeneralGameWorld:Tick() 
	if (self.netHandler) then
		self.netHandler:SendTick();
	end
end

function GeneralGameWorld:Login() 
	-- 清理旧连接
	if (self.netHandler) then
		 self.netHandler:Cleanup();
	end

	-- 连接服务器
	local NetClientHandlerClass = self:GetClient():GetNetClientHandlerClass() or NetClientHandler;
	self.netHandler = NetClientHandlerClass:new():Init(self);
	
	GameLogic:Connect("frameMoved", self, self.OnFrameMove, "UniqueConnection");

	self.isLogin = true;
	self:SetWorldId(self:GetClient():GetOptions().worldId);
end

function GeneralGameWorld:Logout() 
	GGS.INFO("logout world");

	if(self.netHandler) then
		self.netHandler:Cleanup();
	end

	self:GetBlockManager():CleanUp();

	self:GetPlayerManager():ClearPlayers();

	-- 解除链接关系
	GameLogic:Disconnect("frameMoved", self, self.OnFrameMove, "DisconnectOne");
	
	-- 清除定时任务
	self.timer:Change();

	self.isLogin = false;
	self:SetWorldId(0);
end

function GeneralGameWorld:IsLogin()
	return self.isLogin;
end

function GeneralGameWorld:OnExit()
	GeneralGameWorld._super.OnExit(self);

	self:Logout();
end

function GeneralGameWorld:GetNetHandler()
	return self.netHandler;
end

