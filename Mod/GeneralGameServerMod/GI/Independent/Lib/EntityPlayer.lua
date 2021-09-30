--[[
Title: EntityPlayer
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local EntityPlayer = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/EntityPlayer.lua");
------------------------------------------------------------
]]

local KeyBoard = require("KeyBoard");

local EntityPlayer = inherit(require("Entity"), module("EntityPlayer"));

EntityPlayer:Property("MainPlayer", false, "IsMainPlayer");   -- 是否是主玩家
EntityPlayer:Property("Fly", false, "IsFly");                  -- 是否在飞行
EntityPlayer:Property("Jump", false, "IsJump");                -- 是否在跳跃
EntityPlayer:Property("CanFly", false, "IsCanFly");            -- 是否在飞行
EntityPlayer:Property("CanJump", false, "IsCanJump");          -- 是否在跳跃
EntityPlayer:Property("JumpTickCount", 0);                     -- 跳跃tick数

function EntityPlayer:ctor()
	local __data_watcher__ = self:GetDataWatcher(true);
	self.dataFieldWKeyPressed = __data_watcher__:AddField(nil, nil);
	self.dataFieldAKeyPressed = __data_watcher__:AddField(nil, nil);
	self.dataFieldSKeyPressed = __data_watcher__:AddField(nil, nil);
	self.dataFieldDKeyPressed = __data_watcher__:AddField(nil, nil);
	self.dataFieldFKeyPressed = __data_watcher__:AddField(nil, nil);
	self.dataFieldSpaceKeyPressed = __data_watcher__:AddField(nil, nil);
	self.dataFieldAssetFile = __data_watcher__:AddField(nil, nil);
	self.__data_watcher__ = __data_watcher__;
	self.__event_emitter__ = EventEmitter:new();
end

-- @param entityId: this is usually from the server. 
function EntityPlayer:Init(opts)
    opts = opts or {};
	opts.step = opts.step or 0.15;
    EntityPlayer._super.Init(self, opts);

    if (opts.entityId) then self:SetEntityId(opts.entityId) end 
	self:SetMainPlayer(opts.isMainPlayer); 

	if (self:IsMainPlayer()) then
		SetFocusPlayer(self);
		self:UpdatePosition();
	end

	-- 起一个运动协程
	__run__(function()
		while (not self:IsDestory()) do
			self:Tick();
			sleep();
		end
	end)

    return self;
end

function EntityPlayer:IsOnGround()
	local x, y, z = self:GetPosition();
	local bx, by, bz = self:GetBlockPos();
	local block = GetBlock(bx, by - 1, bz);

	if (block and block.obstruction) then
		local rx, ry, rz = ConvertToRealPosition(bx, by, bz);
		local value = math.abs(y - ry + __HalfBlockSize__);
		return value < 0.1, value; 
	end

	return false;
end

function EntityPlayer:CheckMotion()
	local obj = self:GetInnerObject();
	if (not obj) then return end 

	local is_move_key_pressed = self:IsMoveKeyPressed();
	local is_on_ground, offset_y = self:IsOnGround();
	if (not is_move_key_pressed) then 
		obj:SetField("AnimID", 0);
		if (is_on_ground) then return end ;
	end 

	local dist = self:GetStep() * self:GetSpeed();
    local x, y, z = self:GetPosition();
    local xx, yy, zz = x, y, z;
	local facing = GetCameraFacing() / 180 * math.pi;

	if (self:IsWKeyPressed()) then
        xx = xx + dist * math.cos(facing);
        zz = zz - dist * math.sin(facing);
    end

    if (self:IsAKeyPressed()) then
		xx = xx + dist * math.cos(facing - math.pi / 2);
        zz = zz - dist * math.sin(facing - math.pi / 2);
    end

    if (self:IsSKeyPressed()) then
		xx = xx + dist * math.cos(facing - math.pi);
        zz = zz - dist * math.sin(facing - math.pi);
    end

    if (self:IsDKeyPressed()) then
        xx = xx + dist * math.cos(facing - math.pi * 3 / 2);
        zz = zz - dist * math.sin(facing - math.pi * 3 / 2);
    end

	if (self:IsFly() and self:IsFKeyPressed()) then
		yy = yy + 0.3;
	end

	if (self:IsSpaceKeyPressed()) then
		if (self:IsJump()) then
			self:SetJumpTickCount(self:GetJumpTickCount() + 1);
		else 
			self:SetJumpTickCount(self:GetJumpTickCount() + 10);
			__run__(function()
				self:SetJump(true);
				while(self:GetJumpTickCount() > 0) do
					local x, y, z = self:GetPosition();
					self:SetPosition(x, y + 0.2, z);
					self:SetJumpTickCount(self:GetJumpTickCount() - 1);
					sleep();
				end
				self:SetJump(false);
			end);
		end
	end

	if (not self:IsJump() and not self:IsFly() and not is_on_ground) then
		yy = yy - math.min(offset_y or 0.2);
	end

	self:SetPosition(xx, yy, zz);
	if (math.abs(xx - x) > 0.001 or math.abs(zz - z) > 0.001) then self:SetFacing(GetFacingFromOffset(xx - x, yy - y, zz - z)) end 
	self:GetInnerObject():SetField("AnimID", (self:IsFly() or self:IsJump()) and 38 or 5); 

	local bx,by,bz = self:GetBlockPos();
	local block = GetBlock(bx, by, bz);
	if(block and block.obstruction) then
		local block1 = GetBlock(bx, by + 1, bz);
		local block2 = GetBlock(bx, by + 2, bz);
		if ((not block1 or not block1.obstruction) and (not block2 or not block2.obstruction)) then
			local rx, ry, rz = ConvertToRealPosition(bx, by + 1, bz);
			self:SetPosition(xx, ry - __HalfBlockSize__, zz);
		else 
			self:SetPosition(x, y, z);
		end
	end
end

function EntityPlayer:Tick()
	-- 检测运动
	self:CheckMotion();
	
	-- 检测数据更新
	self:CheckWatcherDataChange();

	-- 是主角且在运动
	if (self:HasFocus() and self:IsWASDKeyPressed()) then self:PlayStepSound() end 
end

function EntityPlayer:FaceTarget(x,y,z, isAngle)
	-- if (not self:IsWASDKeyPressed()) then
	-- 	EntityPlayer._super.FaceTarget(self, x, y, z, isAngle);
	-- end
end

function EntityPlayer:SetAssetFile(assetfile)
	if (self:GetAssetFile() == assetfile) then return end 
	EntityPlayer._super.SetAssetFile(self, assetfile);
	self.__data_watcher__:SetField(self.dataFieldAssetFile, self:GetAssetFile());
end

function EntityPlayer:IsMoveKeyPressed()
	return self:IsWASDKeyPressed() or self:IsFKeyPressed() or self:IsSpaceKeyPressed();
end

function EntityPlayer:IsWASDKeyPressed()
	return self:IsWKeyPressed() or self:IsAKeyPressed() or self:IsSKeyPressed() or self:IsDKeyPressed();
end

function EntityPlayer:SetWKeyPressed(is_w_pressed)
	self.__data_watcher__:SetField(self.dataFieldWKeyPressed, is_w_pressed);
end

function EntityPlayer:IsWKeyPressed()
	return self.__data_watcher__:GetField(self.dataFieldWKeyPressed);
end

function EntityPlayer:SetAKeyPressed(is_a_pressed)
	self.__data_watcher__:SetField(self.dataFieldAKeyPressed, is_a_pressed);
end

function EntityPlayer:IsAKeyPressed()
	return self.__data_watcher__:GetField(self.dataFieldAKeyPressed);
end

function EntityPlayer:SetSKeyPressed(is_s_pressed)
	self.__data_watcher__:SetField(self.dataFieldSKeyPressed, is_s_pressed);
end

function EntityPlayer:IsSKeyPressed()
	return self.__data_watcher__:GetField(self.dataFieldSKeyPressed);
end

function EntityPlayer:SetDKeyPressed(is_d_pressed)
	self.__data_watcher__:SetField(self.dataFieldDKeyPressed, is_d_pressed);
end

function EntityPlayer:IsDKeyPressed()
	return self.__data_watcher__:GetField(self.dataFieldDKeyPressed);
end

function EntityPlayer:SetFKeyPressed(is_f_pressed)
	if (not self:IsCanFly()) then return end 
	self.__data_watcher__:SetField(self.dataFieldFKeyPressed, is_f_pressed);
	if (is_f_pressed) then self:SetFly(not self:IsFly()) end 
end

function EntityPlayer:IsFKeyPressed()
	return self.__data_watcher__:GetField(self.dataFieldFKeyPressed);
end

function EntityPlayer:SetSpaceKeyPressed(is_space_pressed)
	if (not self:IsCanJump()) then return end 
	self.__data_watcher__:SetField(self.dataFieldSpaceKeyPressed, is_space_pressed);
	-- if (is_space_pressed) then self:SetJump(not self:IsJump()) end 
end

function EntityPlayer:IsSpaceKeyPressed()
	return self.__data_watcher__:GetField(self.dataFieldSpaceKeyPressed);
end

function EntityPlayer:CheckWatcherDataChange()
    if (self.__data_watcher__:HasChanges()) then
		self.__event_emitter__:TriggerEventCallBack("__entity_player_watcher_data_change__", self:GetWatcherData());
	end

	-- 清楚缓存
	self.__watcher_data__ = nil;
end

function EntityPlayer:GetWatcherData()
	if (not self.__data_watcher__:HasChanges()) then return self.__watcher_data__ end 

	local listobj = self.__data_watcher__:UnwatchAndReturnAllWatched();
	self.__watcher_data__ = self.__data_watcher__.WriteObjectsInListToData(listobj, nil);
	
	return self.__watcher_data__;
end

function EntityPlayer:GetAllWatcherData()
	local listobj = self.__data_watcher__:GetAllObjectList();
	return self.__data_watcher__.WriteObjectsInListToData(listobj, nil);
end

function EntityPlayer:LoadWatcherData(data)
	if (not data) then return end 
	local listobj = self.__data_watcher__.ReadWatchebleObjects(data);
	self.__data_watcher__:UpdateWatchedObjectsFromList(listobj);

end

function EntityPlayer:OnWatcherDataChange(callback)
	self.__event_emitter__:RegisterEventCallBack("__entity_player_watcher_data_change__", callback);
end

function EntityPlayer:GetSyncData(bAllData)
	local x, y, z = self:GetPosition();
    return {
        __key__ = self:GetKey(),
		__username__ = self:GetUserName(),
        x = x, y = y, z = z, 
        metadata = bAllData and self:GetAllWatcherData() or self:GetWatcherData(),
    };
end

function EntityPlayer:SetSyncData(data)
	if (data.__key__) then self:SetKey(data.__key__) end
	if (data.__username__) then self:SetUserName(data.__username__) end
	if (data.x and data.y and data.z) then self:SetPosition(data.x, data.y, data.z) end
	if (data.metadata) then 
		local old_assetfile = self:GetAssetFile();
		self:LoadWatcherData(data.metadata);
		local new_assetfile = self.__data_watcher__:GetField(self.dataFieldAssetFile);
		if (old_assetfile ~= new_assetfile) then self:SetAssetFile(new_assetfile) end 
	end 
end

local function MoveKeyCallBack(event)
    if (event.keyname == "DIK_SPACE" or event.keyname == "DIK_F") then return event:accept() end
end

local function DisableDefaultMoveKey()
    DisableDefaultWASDKey();
    RegisterEventCallBack(EventType.KEY, MoveKeyCallBack);
end

local function EnableDefaultMoveKey()
    EnableDefaultWASDKey();
    RemoveEventCallBack(EventType.KEY, MoveKeyCallBack);
end

function SetFocusPlayer(player)
	if (player and not player:IsDestory()) then
		DisableDefaultMoveKey();
		SetFocusEntity(player);
	else
		EnableDefaultMoveKey();
		SetFocusPlayer(nil);
	end
end

function GetFocusPlayer()
	return GetFocusEntity();
end

-- 玩家移动控制
KeyBoard:OnKeyDown("w", function()
    if (not GetFocusPlayer()) then return end 
    GetFocusPlayer():SetWKeyPressed(true);
end);

KeyBoard:OnKeyUp("w", function()
    if (not GetFocusPlayer()) then return end 
    GetFocusPlayer():SetWKeyPressed(false);
end);

KeyBoard:OnKeyDown("a", function()
    if (not GetFocusPlayer()) then return end 
    GetFocusPlayer():SetAKeyPressed(true);
end);

KeyBoard:OnKeyUp("a", function()
    if (not GetFocusPlayer()) then return end 
    GetFocusPlayer():SetAKeyPressed(false);
end);

KeyBoard:OnKeyDown("s", function()
    if (not GetFocusPlayer()) then return end 
    GetFocusPlayer():SetSKeyPressed(true);
end);

KeyBoard:OnKeyUp("s", function()
    if (not GetFocusPlayer()) then return end 
    GetFocusPlayer():SetSKeyPressed(false);
end);

KeyBoard:OnKeyDown("d", function()
    if (not GetFocusPlayer()) then return end 
    GetFocusPlayer():SetDKeyPressed(true);
end);

KeyBoard:OnKeyUp("d", function()
    if (not GetFocusPlayer()) then return end 
    GetFocusPlayer():SetDKeyPressed(false);
end);

KeyBoard:OnKeyDown("f", function()
    if (not GetFocusPlayer()) then return end 
    GetFocusPlayer():SetFKeyPressed(true);
end);

KeyBoard:OnKeyUp("f", function()
    if (not GetFocusPlayer()) then return end 
    GetFocusPlayer():SetFKeyPressed(false);
end);

KeyBoard:OnKeyDown("space", function()
    if (not GetFocusPlayer()) then return end 
    GetFocusPlayer():SetSpaceKeyPressed(true);
end);

KeyBoard:OnKeyUp("space", function()
    if (not GetFocusPlayer()) then return end 
    GetFocusPlayer():SetSpaceKeyPressed(false);
end);