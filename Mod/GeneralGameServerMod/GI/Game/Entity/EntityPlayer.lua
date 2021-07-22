--[[
Title: entity player
Author(s): wxa
Date: 20121/7/14
Desc: other player entities on the client side. 
use the lib:
------------------------------------------------------------
local EntityPlayer = NPL.load("Mod/GeneralGameServerMod/GI/Game/Entity/EntityPlayer.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local EntityPlayer = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayer"), NPL.export());

local EventEmitter = NPL.load("Mod/GeneralGameServerMod/CommonLib/EventEmitter.lua");

EntityPlayer.framemove_interval = 0.02;

function EntityPlayer:ctor()
	local dataWatcher = self:GetDataWatcher(true);
	self.dataFieldWKeyPressed = dataWatcher:AddField(nil, nil);
	self.dataFieldAKeyPressed = dataWatcher:AddField(nil, nil);
	self.dataFieldSKeyPressed = dataWatcher:AddField(nil, nil);
	self.dataFieldDKeyPressed = dataWatcher:AddField(nil, nil);

	self.__event_emitter__ = EventEmitter:new();
end

-- @param entityId: this is usually from the server. 
function EntityPlayer:Init(username, entityId)
    local world = GameLogic.GetWorld();
    EntityPlayer._super.init(self, world);

    self:SetUserName(username);
	self:SetEntityId(entityId);
	self:SetDisplayName(self.username);
	local x, y, z = world:GetSpawnPoint();
	self:SetLocationAndAngles(x, y, z, 0, 0);

	local skin = CustomCharItems:GetSkinByAsset(self:GetMainAssetPath());
	if (skin) then
		self.mainAssetPath = CustomCharItems.defaultModelFile;
		self.skin = skin;
		self:GetDataWatcher():SetField(self.dataMainAsset, self:GetMainAssetPath());
	end

	self:CreateInnerObject();
	self:RefreshClientModel();
	return self;
end

function EntityPlayer:Attach()
    EntityPlayer._super.Attach(self);
    return self;
end

function EntityPlayer:IsShowHeadOnDisplay()
	return true;
end

function EntityPlayer:doesEntityTriggerPressurePlate()
	return false;
end

function EntityPlayer:CreateInnerObject()
	local obj = EntityPlayer._super.CreateInnerObject(self, self:GetMainAssetPath(), true, 0, 1, self:GetSkin());

	if(self:IsShowHeadOnDisplay() and System.ShowHeadOnDisplay) then
		System.ShowHeadOnDisplay(true, obj, self:GetDisplayName(), GameLogic.options.NPCHeadOnTextColor);	
	end

	return obj;
end

function EntityPlayer:CheckCollision(deltaTime)
	deltaTime = math.min(0.3, deltaTime);
	EntityPlayer._super.CheckCollision(self, deltaTime);
end
function EntityPlayer:CheckMotion()
	local obj = self:GetInnerObject();
	if (not obj) then return end 

	if (not self:IsWASDKeyPressed()) then
    	return obj:SetField("AnimID", 0);
	end 

	local dist = 0.15;
    local x, y, z = self:GetPosition();
    local xx, yy, zz = x, y, z;
	local facing = ParaCamera.GetAttributeObject():GetField("CameraRotY");

	if (self:IsWKeyPressed()) then
        xx = xx + dist * math.cos(facing);
        yy = yy;
        zz = zz - dist * math.sin(facing);
    end

    if (self:IsAKeyPressed()) then
		xx = xx + dist * math.cos(facing - math.pi / 2);
        yy = yy;
        zz = zz - dist * math.sin(facing - math.pi / 2);
    end

    if (self:IsSKeyPressed()) then
		xx = xx + dist * math.cos(facing - math.pi);
        yy = yy;
        zz = zz - dist * math.sin(facing - math.pi);
    end

    if (self:IsDKeyPressed()) then
        xx = xx + dist * math.cos(facing - math.pi * 3 / 2);
        yy = yy;
        zz = zz - dist * math.sin(facing - math.pi * 3 / 2);
    end

	self:SetPosition(xx, yy, zz);
	self:SetFacing(Direction.GetFacingFromOffset(xx - x, yy - y, zz - z));
	self:GetInnerObject():SetField("AnimID", 5);

	local bx,by,bz = self:GetBlockPos();

	local block = BlockEngine:GetBlock(bx,by,bz);
	if(block and block.obstruction) then
		local block1 = BlockEngine:GetBlock(bx, by + 1, bz);
		local block2 = BlockEngine:GetBlock(bx, by + 2, bz);
		if ((not block1 or not block1.obstruction) and (not block2 or not block2.obstruction)) then
			self:SetBlockPos(bx, by + 1, bz);
		else 
			self:SetPosition(x, y, z);
		end
	end
end

function EntityPlayer:FrameMove(deltaTime)
	-- 检测运动
	self:CheckMotion();
	
	-- 检测碰撞
	self:CheckCollision(deltaTime);

	-- 检测数据更新
	self:CheckWatcherDataChange();

	-- 是主角且在运动
	if (self:HasFocus() and self:IsWASDKeyPressed()) then self:PlayStepSound() end 
end

function EntityPlayer:FaceTarget(x,y,z, isAngle)
	if (not self:IsWASDKeyPressed()) then
		EntityPlayer._super.FaceTarget(self, x, y, z, isAngle);
	end
end

function EntityPlayer:IsWASDKeyPressed()
	return self:IsWKeyPressed() or self:IsAKeyPressed() or self:IsSKeyPressed() or self:IsDKeyPressed();
end

function EntityPlayer:SetWKeyPressed(is_w_pressed)
	self.dataWatcher:SetField(self.dataFieldWKeyPressed, is_w_pressed);
end

function EntityPlayer:IsWKeyPressed()
	return self.dataWatcher:GetField(self.dataFieldWKeyPressed);
end

function EntityPlayer:SetAKeyPressed(is_a_pressed)
	self.dataWatcher:SetField(self.dataFieldAKeyPressed, is_a_pressed);
end

function EntityPlayer:IsAKeyPressed()
	return self.dataWatcher:GetField(self.dataFieldAKeyPressed);
end

function EntityPlayer:SetSKeyPressed(is_s_pressed)
	self.dataWatcher:SetField(self.dataFieldSKeyPressed, is_s_pressed);
end

function EntityPlayer:IsSKeyPressed()
	return self.dataWatcher:GetField(self.dataFieldSKeyPressed);
end

function EntityPlayer:SetDKeyPressed(is_d_pressed)
	self.dataWatcher:SetField(self.dataFieldDKeyPressed, is_d_pressed);
end

function EntityPlayer:IsDKeyPressed()
	return self.dataWatcher:GetField(self.dataFieldDKeyPressed);
end

function EntityPlayer:CheckWatcherDataChange()
    if (self.dataWatcher:HasChanges()) then
		self.__event_emitter__:TriggerEventCallBack("__entity_player_watcher_data_change__", self:GetWatcherData());
	end
end

function EntityPlayer:GetWatcherData()
	local listobj = self.dataWatcher:UnwatchAndReturnAllWatched();
	return DataWatcher.WriteObjectsInListToData(listobj, nil);
end

function EntityPlayer:LoadWatcherData(data)
	if (not data) then return end 
	local listobj = DataWatcher.ReadWatchebleObjects(data);
	self.dataWatcher:UpdateWatchedObjectsFromList(listobj);
end

function EntityPlayer:OnWatcherDataChange(callback)
	self.__event_emitter__:RegisterEventCallBack("__entity_player_watcher_data_change__", callback);
end
