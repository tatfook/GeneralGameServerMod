--[[
	NPL.load("(gl)script/Truck/Independent/Interfaces.lua");
	local Interfaces = commonlib.gettable("Mod.Truck.Independent.Interfaces");
]]

local Interfaces = commonlib.gettable("Mod.Truck.Independent.Interfaces");

local ParaTerrain_SetBlockTemplateByIdx = ParaTerrain.SetBlockTemplateByIdx;


function Interfaces.load(environment)
	local env = environment;

	local register = function(name, func)
		env[name] = func;
	end

	NPL.load("(gl)script/Truck/Utility/UTF8String.lua");


	local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
	local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
	local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
	local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
	local Independent = commonlib.gettable("Mod.Truck.Independent");
	local NeuronAPISandbox = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronAPISandbox");
	local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
	local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
	local YcProfile = commonlib.gettable("Mod.Truck.Network.YcProfile");
	local ItemReader = commonlib.gettable("Mod.Truck.Config.ItemReader");
	local CommonUtility = commonlib.gettable("Mod.Truck.Utility.CommonUtility");
	local InputProcessor = commonlib.gettable("Mod.Truck.Game.Input.InputProcessor");
	local ResourceManager = NPL.load("script/Truck/Game/Resource/ResourceManager.lua")
	local UIManager= commonlib.gettable("Mod.Truck.Game.UI.UIManager");
	local UTF8Char = commonlib.gettable("Mod.Truck.Utility.UTF8Char");
	local UTF8String = commonlib.gettable("Mod.Truck.Utility.UTF8String");
	local GamingRoomInfo = commonlib.gettable("Mod.Truck.Game.MultiPlayer.GamingRoomInfo");
	local BulletBroadcastHelper = commonlib.gettable("Mod.Truck.Game.UI.BulletBroadcastHelper");
    local EntityController = NPL.load("script/Truck/Game/Input/EntityController.lua")
	local RaySceneQuery = NPL.load("script/Truck/Utility/RaySceneQuery.lua")
	local AStar = NPL.load("script/Truck/Utility/AStar.lua")
	local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
	local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
	local vector3d = commonlib.gettable("mathlib.vector3d");
	NPL.load("(gl)script/Truck/Game/ParticleSystem/ParticleSystem.lua");
	local ParticleSystem=commonlib.gettable("Truck.Game.ParticleSystem");
	local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
	local SavedData = NPL.load("script/Truck/Game/Resource/SavedData.lua")
	NPL.load("(gl)script/Truck/Game/MiniGameUI/MiniGameUIHeaders.lua");
	local UISystem=commonlib.gettable("Mod.Truck.Game.MiniGameUI.System");
	NPL.load("(gl)script/Truck/Utility/FZip.lua");
	local FZip = commonlib.gettable("Mod.Truck.Utility.FZip");
	NPL.load("(gl)scriptscript/truckparts/utilities/QiniuHash.lua");
	local QiniuHash = commonlib.gettable("Mod.Truck.Utility.QiniuHash");
  	NPL.load("(gl)script/Truck/Game/BillboardSystem/BillboardSet.lua");
  	local BillboardSet=commonlib.gettable("Truck.Game.BillboardSystem.BillboardSet");
	local GUI = NPL.load("script/truckparts/utilities/GUI.lua");
	NPL.load("(gl)script/Truck/Utility/MiniSceneWrapper.lua");
	local MiniSceneWrapper = commonlib.gettable("Mod.Truck.Utility.MiniSceneWrapper");
	local HeadonUtility = NPL.load("script/Truck/Game/HeadonObject/HeadonUtility.lua");
	local HeadonObject = NPL.load("script/Truck/Game/HeadonObject/HeadonObject.lua")
	local modules = {};
	local internal = {__modules = modules};
	setmetatable(environment, {__index = internal});

	-- internal container
	environment.__entities = {}
	environment.__timer = {}
	environment.__uis = {};

	-- command
	register("cmd", function(cmd_name, cmd_text, ...)
		return CommandManager:RunCommand(cmd_name, cmd_text, ...)
	end)

	-- lua api
	environment._G = environment;

	environment.os.date = os.date;
	environment.format = format;
	environment.echotable = echotable;
	environment.print = print;
	environment.error = error;
	environment.math.mod = math.mod;
	environment.math.randomseed = math.randomseed;
	environment.vector3d = vector3d;
	environment.setmetatable = setmetatable;
	environment.rawset = rawset;
	environment.rawget = rawget;
	environment.pcall = pcall;
	environment.xpcall = xpcall;
	environment.dcall = Independent.call
	environment.coroutine.yield = coroutine.yield
	
	environment.utf8string = UTF8String;
	environment.utf8char = UTF8Char;
	
	environment.serialize = commonlib.serialize
	environment.unserialize = commonlib.LoadTableFromString;
    
    --lua debug
	environment.debug = {
		stack = function (start, no_log)
			local stack = Independent.stack(start or 2)
			if not no_log then 
				for k,v in ipairs(stack) do 
					commonlib.log(string.format("    %s\n", v));
				end
			end
			return stack
		end,
		catch = function (callback)

		end
	};
	

	-- sandbox
	register("sandbox", NeuronAPISandbox.CreateGetSandbox())
	register("module", function (name)
		local m = {} or modules[name];
		-- local env = {};
		-- setmetatable(env, {__index = environment});

		-- setfenv(2, env);
		modules[name] = m;
		internal[name] = m;
		return m;
	end)
	register("require", function (name)
		if not modules[name] then 
			modules[name] = {};
			if not Independent.load(string.format("script/Truck/Independent/libs/%s.lua", name), true) then 
				error("require module " .. name);
			end
		end
		return modules[name];
	end)

	-- block
	register("GetBlockId", ParaTerrain.GetBlockTemplateByIdx);
	register("GetBlockEntity", EntityManager.GetBlockEntity);
	register("CreateBlockPieces", 
		function (blockid, ...) 
			local block_template = block_types.get(blockid)
			return GameLogic.GetWorld():CreateBlockPieces(block_template, ...) 
		end)
	register("SetBlock", function(...) BlockEngine:SetBlock(...) end)
	register("GetBlockFull", function (...) return BlockEngine:GetBlockFull(...) end);

	register("LoadTemplate",
		function (path, x,y,z)
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
			local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");

			local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
			local filename = path;
			if(filename=="") then
				templatename = "default";
			end
			if(not filename:match("%.blocks%.xml$")) then
				filename = filename..".blocks.xml";
			end
			local fullpath = Files.GetWorldFilePath(filename) or (not filename:match("[/\\]") and Files.GetWorldFilePath("blocktemplates/"..filename));
			if(fullpath) then
				local task = BlockTemplate:new({operation = BlockTemplate.Operations.Load, filename = fullpath,
					blockX = x,blockY = y, blockZ = z, bSelect=nil, load_anim_duration=0,
					UseAbsolutePos = true,TeleportPlayer=false,
					})
				task:Run();
			else
				LOG.std(nil, "info", "loadtemplate", "file %s not found", filename);
			end
		end)

	-- entity
	register("GetPlayerId", function ()
		return EntityManager.GetPlayer().entityId;
	end)
	register("GetAllEntities", EntityManager.GetAllEntities);
	register("GetEntityById", EntityManager.GetEntityById);
	register("GetEntitiesInBlock", EntityManager.GetEntitiesInBlock);
	register("GetPlayer", EntityManager.GetPlayer);
	register("CreateNPC", 
		function (...)
			--if GameLogic.IsServerWorld() then 
				NPL.load("script/Truck/Game/Entity/EntityNPCOnline.lua")
				local EntityNPCOnline = commonlib.gettable("Mod.Truck.Game.EntityNPCOnline")
				local npc = EntityNPCOnline:Create(...);
				npc:Attach();
				table.insert(environment.__entities, npc);
				return npc;
			--[[else
				error("can not create npc from client.")
			end]]
		end)
	register("CreateEntity", function (bx,by,bz, path, canBeCollied)
		NPL.load("scrtip/Truck/Game/Entity/EntityCustom.lua")
		local EntityCustom = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCustom");
		local entity = EntityCustom:Create({bx = bx, by = by, bz = bz, mModel = path or "" , mEnablePhysics = canBeCollied});
		table.insert(environment.__entities, entity);
		return entity;
	end)
	register("IsInWater", function () return GameLogic.GetPlayerController():IsInWater() end);
	register("IsInAir", function () return GameLogic.GetPlayerController():IsInAir() end);
	register("GetAssetID", function () return YcProfile.GetMyCharacterAssetID() end);
	register("GetName", function () return YcProfile.GetMyNickname() end);
	register("GetModelPath", 
		function() 
			local info = ItemReader.GetAssetInfoByID(YcProfile.GetMyCharacterAssetID());
			if info then
				return info.model;
			else
				LOG.std(nil, "error", "develop", "invalid character asset id: "..YcProfile.GetMyCharacterAssetID());
				return "";
			end
		end);
	register("GetTexturePath", 
		function() 
			local info = ItemReader.GetAssetInfoByID(YcProfile.GetMyCharacterAssetID());
			if info then
				return info.texture;
			else
				LOG.std(nil, "error", "develop", "invalid character asset id: "..YcProfile.GetMyCharacterAssetID());
				return "";
			end
		end)
	
	register("SetPlayerVisible", 
		function (value )
			EntityManager.GetPlayer():SetVisible(value);
		end)

	register("GetLastTriggerEntity", EntityManager.GetLastTriggerEntity);
	register("EnableWalkUpBlock", function (enable)
		ParaScene.GetPlayer():SetField("AutoWalkupBlock", enable);
	end)
	
	-- world
	register("GetHomePosition", GameLogic.GetHomePosition);

	-- tools
	register("ConvertToRealPosition", function (...) return BlockEngine:ConvertToRealPosition_float(...) end);
	register("ConvertToBlockIndex", function (...) return BlockEngine:ConvertToBlockIndex(...) end);
	register("GetFacingFromCamera", Direction.GetFacingFromCamera)
	register("GetDirection2DFromCamera", Direction.GetDirection2DFromCamera)

	register("ShowSelectBox", ParaTerrain.SelectBlock);
	register("SearchPath", function (x1,y1,z1, x2, y2,z2, pathids)
		if type(pathids) == "function" then 
			return AStar:new(nil, pathids):search(x1,y1,z1, x2,y2,z2);
		end
		pathids = pathids or {0};
		local map = {}
		for k,v in ipairs(pathids) do 
			map[v] = true;
		end
		local astar = AStar:new(nil, function (x,y,z)
			return map[BlockEngine:GetBlockId(x, y,z)] == true;
		end);
		return astar:search(x1,y1, z1, x2,y2, z2);
	end)

	-- internal 
	-- register("attach", Independent.attach)
	-- register("registerFunction", Independent.registerFunction)
	-- register("load", function (name)
	-- 	local path = Independent.getCurrentDirectory()
	-- 	return Independent.load(path .. name)
	-- end)

	-- guide mission
	register("StartGuideMission", 
		function (id)
			local ModuleManager = commonlib.gettable("Mod.Truck.Game.ModuleManager");
			local config = commonlib.gettable("Mod.Truck.Config").GuideMission;
			local mission = config.mission:find(id);
			ModuleManager.startModule({"GameWorld", "Input", "GuideMission", "StandAlone" , "FurnitureModule"}, {planetPath=mission.path,input="GuideMission",scriptEntry=mission.scriptEntry})
		end);
	register("SetGuideMissionProgress", 
		function (id)
			local UserDatabase = commonlib.gettable("Mod.Truck.Utility.UserDatabase");
			UserDatabase.setAttribute("GuideMission.progress", id);
		end);
	register("GetGuideMissionProgress", 
		function()
			local UserDatabase = commonlib.gettable("Mod.Truck.Utility.UserDatabase");
			return UserDatabase.getAttribute("GuideMission.progress")
		end);

	-- ui
	register("ShowBigWorldUI", 
		function ()
			local main = UIManager.getUI("UIMain")
			if not main then 
				return
			end
			-- main:showFunctionCorner()
			main:showCommonBar()
			main:showQuickMotionBar()

			NPL.load("(gl)script/Truck/Utility/CommonUtility.lua");
			local CommonUtility = commonlib.gettable("Mod.Truck.Utility.CommonUtility");
			if CommonUtility:IsMobilePlatform() then
				main:showQuickToolsBtn({mode="bigworld"});
			end
			main:showQuickSetBtn({functionList={"info","friend","skin","mail","shop","billboard"}});
		end)
	register("HideBigWorldUI", 
		function ()
			UIManager.destroyUI("InviteReminderBtn")
			UIManager.destroyUI("QuickMotionBar")
			UIManager.destroyUI("QuickToolsBtn")
			UIManager.destroyUI("QuickSetBtn")
		end)

	register("ShowQuickSelectBar", 
		function()
			local main = UIManager.getUI("UIMain")
			if not main then 
				return
			end
		    
			main:showQuickSelectBar();
	end)
	register("HideQuickSelectBar", function()
			UIManager.destroyUI("QuickSelectBar")
	end)
	register("HideRoomMemBar", function ()
		UIManager.destroyUI("RoomMemBar")
	end)
	register("HideQuickSetBtn", function ()
		UIManager.destroyUI("QuickSetBtn")
	end)

	local function getEntity(id)
		if type(id) == "table" then 
			return id;
		else
			return EntityManager.GetEntityById(id)
		end 
	end

    register("SetEntityHeadOnText", function (id, str, color, font)
		local e = getEntity(id)
		if not e or not str then return end;
		local name = e:GetHeadonObject("name");
		if not name then  
			HeadonUtility.initHeadonObjects(e,{"name"})
			name = e:GetHeadonObject("name");
		end
		name:setText(str);
		if color then 
			name:setColor(color);
		end

		if font then 
			name:setFont(font);		
		end
		
	end)
	register("GetEntityHeadOnObject", function (id, name)
		local e = getEntity(id);
		if not e or not name then return end;
		local o = e:GetHeadonObject(name);
		if not o then 
			o = HeadonObject:new():init(e:GetInnerObject());
			e:AddHeadonObject(name, o);
		end
		return o;
	end)
	register("EnableEntityPicked", function (id, enable)
		local e = getEntity(id)

		if e then 
			local o = e:GetInnerObject()
			if o then 
				o:SetAttribute(0x8000, not enable);
			end
		end     
    end)
    register("GetEntityBlockPos", function (id)
        local e = getEntity(id)
        if e then 
            return e:GetBlockPos();
        end
	end)
	register("SetEntityBlockPos",function (id, x,y,z)
		local e = getEntity(id)
        if e then 
            return e:TeleportToBlockPos(x,y,z);
        end
	end)

	register("GetEntityDirection", function (id)
		local e = getEntity(id)
		local facing = e:GetFacing()
		local sin = math.sin(facing);
		local cos = math.cos(facing);
		return {cos , 0, - sin };
	end)


	-- room
	register("GetRoomInfo", function ()
		return GamingRoomInfo.getRoomInfo();
	end)
	register("SetPermission", 
		function (permission, enable)
			local player = GamingRoomInfo.getPlayer();
			if player then 
				if enable then
					player.states:add(permission)
				else
					player.states:remove(permission)
				end
			end
	end)

	-- custom input
	register("SetInput", 
		function (input)
			InputProcessor.setInput(input);
		end)

	-- item
	register("GetHandToolIndex", function ()
		local p = EntityManager.GetPlayer();
        if p and p.inventory then 
            return p.inventory:GetHandToolIndex();
        end
	end)

	register("SetHandToolIndex", function (...)
		local p = EntityManager.GetPlayer();
        if p  then 
             p:SetHandToolIndex(...);
        end
	end)
	register("CreateItemStack", 
		function (id, count, serverdata, callback)
			local itemstack  = ItemStack:new():Init(id, count or 1, serverdata);
			local item = itemstack:GetItem();
			itemstack.onClick = callback;
			return itemstack; 
		end)

	register("SetItemStackInHand", function (item)
		local p = EntityManager.GetPlayer();
		if p and p.inventory  then 
			p:SetBlockInRightHand(item);
		end
    end)

    register("GetItemStackInHand", function ()
        local p = EntityManager.GetPlayer();
        if p and p.inventory then 
            return p.inventory:GetBlockInRightHand();
        end
    end)
    
	register("SetItemStackToScene", function (itemStack, bx,by,bz)
		if(GameLogic.isRemote) then
			-- host supported only;
		else
			if(itemStack) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityItem.lua");
                local EntityItem = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityItem")
                local x,y,z = BlockEngine:ConvertToRealPosition_float(bx,by,bz);
				local entity = EntityItem:new():Init(x,y,z,itemStack, throwed_item_lifetime);
				entity:Attach();
				-- TESTING
				entity:AddVelocity(0,5,0);
			end
		end
    end)
    
    register("GetItemStackFromInventory", function (index)
		local p = EntityManager.GetPlayer();
		if not p or not p.inventory then 
			return ;
		end		
		return p.inventory:GetItem(index);
    end)

	register("SetItemStackToInventory", function (index, itemstack)
		local p = EntityManager.GetPlayer();
		if not p or not p.inventory then 
			return ;
		end		
		p.inventory:SetItemByBagPos(index, itemstack.id, itemstack.count, itemstack);
	end)

	register("RemoveItemFromInventory", function (index, count)
		local p = EntityManager.GetPlayer();
		if not p or not p.inventory then 
			return ;
		end		
		p.inventory:RemoveItem(index, count);
    end)
    
    register("GetWeaponFromId", function (id)
        local Config = commonlib.gettable("Mod.Truck.Config");
        local weaponConfig = Config.Weapons;
        return weaponConfig.weapon:find(id);
    end)

	-- coin 
	if CommonUtility.IsCoinSupported() then
		NPL.load("(gl)script/PCoin/PCoin.lua");
		local PCoin = commonlib.gettable("Mod.PCoin");

		register("Pay", 
			function (target, count, code)
				if not PCoin.isInited() or count > PCoin.getCount() then
					return false;
				end
				CommandManager:RunCommand(format("/runat @%s /coin getkey %s %s %s", target, "@" .. EntityManager.GetPlayer().name, count, code or ""));
				return true;
			end)
	end

	local selfsendqueue = {};
	register("SendTo" , function (target, params)
		local player = GameLogic.GetPlayer();
		if not player then return end;

		if type(params) ~= "table" then 
			params = {params};
		else 
			params = commonlib.clone(params);
		end
		params._from = player.entityId;

		if player.name == "default" then 
			LOG.std(nil, "error", "SendTo(interface)", "SendTo must be called in multiplayer.");
			if target == "host" or target =="admin" then 
				return Independent.handleEvent(params.module, "receiveMsg",params)
			else
				return ;
			end
		end

		local PacketScriptEvent = commonlib.gettable("Mod.Truck.Network.PacketsExt.PacketScriptEvent");

		if target == "host" or target == "admin" then 
			if player.name == "__MP__admin" then
				table.insert(selfsendqueue, params)
				environment.Delay(1, function ()
					for k,v in ipairs(selfsendqueue) do 
						Independent.handleEvent(v.module, "receiveMsg",v);
					end
					selfsendqueue = {};
				end)
			else
				player:AddToSendQueue(PacketScriptEvent:new():Init(params));
			end
		elseif target then
			local tp = EntityManager.GetEntityById(target);
			if not tp then 
				return;
			end
			if tp == player then
				table.insert(selfsendqueue, params)
				environment.Delay(1, function ()
					for k,v in ipairs(selfsendqueue) do 
						Independent.handleEvent(v.module, "receiveMsg",v);
					end
					selfsendqueue = {};
				end)
				return true;
			elseif tp and tp.SendPacketToPlayer then
				tp:SendPacketToPlayer(PacketScriptEvent:new():Init(params))
				return true;
			else
				return false;
			end
		else
			local servermanager = GameLogic.GetWorld():GetServerManager();
			if(servermanager) then
				servermanager:SendPacketToAllPlayers(PacketScriptEvent:new():Init(params));
				return true
			end
		end
	end)

	register("MessageBox", _guihelper.MessageBox);
	register("Pick", InputProcessor.mousePick);
	register("RaySceneQuery", function (origin, direction)
		local rsq = RaySceneQuery:new()
		rsq:init(origin[1],origin[2],origin[3], direction[1], direction[2], direction[3])
		return rsq:query();
	end)

	register("AABBSceneQuery", function (min, max, include_me)
		local ret = {blocks = {},entities = {}};
		local blocks = ret.blocks;
		local entities = ret.entities;
		local bmin = {BlockEngine:ConvertToBlockIndex(min[1],min[2],min[3])}
		local bmax = {BlockEngine:ConvertToBlockIndex(max[1],max[2],max[3])}
		for x = bmin[1], bmax[1] do 
			for y = bmin[2], bmax[2] do 
				for z = bmin[3], bmax[3] do 
					local id = BlockEngine:GetBlockId(x,y,z);
					if id ~= 0 then 
						blocks[#blocks + 1] = {x,y,z,id};
					end
				end
			end
		end

		local aabb = ShapeAABB:new();
		aabb:SetMinMax(	min, max) 
		local except = EntityManager.GetPlayer();
		if include_me then 
			except = nil
		end
		ret.entities = EntityManager.GetEntitiesByAABBExcept(aabb, except) or {};
		return ret;
	end)

	register("Delay", function (time, callback)
		local timer;
		timer = commonlib.Timer:new({callbackFunc = function ()
			environment.__timer[tostring(timer)] = nil;
			Independent.call(callback);
		end})
		environment.__timer[tostring(timer)] = timer; 
		timer:Change(time);
	end)

	register("Timer", function (interval,callback)
		local wrapper;
		local timer;
		timer = commonlib.Timer:new({callbackFunc = function ()
			wrapper();
		end})
		environment.__timer[tostring(timer)] = timer; 
		timer:Change(interval,interval);
		local t = {stop = function ()
			timer:Change();
		end}
		wrapper = function () Independent.call(callback, t) end;
		return t;
	end)

	register("GetTime", ParaGlobal.timeGetTime)
	register("GetDate", YcProfile.GetServerDate)

	register("createOrGetStatusBar", function ()
		local ui = UIManager.getUI("StatusBar") or UIManager.createUI("StatusBar");
		return ui;
	end)

	register("AddHeadonStatusBar", function (entityId)
		local HeadonStatusBar = NPL.load("script/Truck/Game/HeadonObject/HeadonStatusBar.lua");
		local s = HeadonStatusBar:new();
		local e = getEntity(entityId);
		if not e then return end;
		s:init(e);
		s:setPosition(-40,-50);
		return s;
	end)

	register("InitMiniGameUISystem",function()
		return UISystem;
	end)

	register("CreateUI", function (params)
		local ui;
		if params.ext and GUI[params.ext] then 
			ui = GUI[params.ext](params);	
		else
			ui = GUI.UI(params);
		end
		table.insert(environment.__uis, ui);
		return ui;
	end)

	-- camera
	register("SetCameraMode", function (mode)
		CameraController.ToggleCamera(mode);
	end)

	register("GetCameraMode", function ()
		return CameraController.GetMode();
	end)

	register("EnableAutoCamera", function (enable)
		NPL.load("(gl)script/Truck/Game/Input/InputListener.lua");
		local InputListener = commonlib.gettable("Mod.Truck.Game.Input.InputListener");
		InputListener.enablePlayerController(enable)
		EntityController.enableKeyboard(enable)
	end)

    register("GetCameraRotation", function ()
		local attr = ParaCamera.GetAttributeObject();		
		return attr:GetField("CameraLiftupAngle"), attr:GetField("CameraRotY"), attr:GetField("CameraRotZ");
    end)

	register("SetCameraRotation", function (x,y,z)
		local attr = ParaCamera.GetAttributeObject();		
		if x then 
			attr:SetField("CameraLiftupAngle", x);
		end

		if y then 
			attr:SetField("CameraRotY", y);
		end

		if z then 
			attr:SetField("CameraRotZ", z);
		end
	end)
	

	register("SwitchOrthoView", ParaCamera.SwitchOrthoView);
	register("SwitchPerspectiveView", ParaCamera.SwitchPerspectiveView);
	register("CameraZoomInOut", function (cam_dist)
		local attr = ParaCamera.GetAttributeObject();
		attr:SetField("CameraObjectDistance", cam_dist);
	end)	

	register("SetFOV", function (fov, speed)
		CameraController.AnimateFieldOfView(fov or GameLogic.options.normal_fov, speed);
	end)

	register("GetFOV", function ()
		return CameraController.GetFov();
	end)

	register("GetScreenSize", function ()
		local root_ = ParaUI.GetUIObject("root");
		local _, _, width_screen, height_screen = root_:GetAbsPosition();
		return width_screen, height_screen;
	end)

	-- control
	register("Fly",function ()
		EntityController.go("flyidle");
	end)
	register("Idle", function ()
		EntityController.go("fall");
		EntityController.go("idle");
	end)
	register("Die", function ()
		EntityController.go("die")
	end)

	register("Revive", function ()
		EntityController.go("revive")
	end)
    register("Jump", GameLogic.DoJump);
    register("Move", function (enable, facing)
        if enable then
            EntityController.go("autorun", facing);
        else
            EntityController.go("idle")
        end
	end)
	register("Animate", function (id,...)
		EntityController.go("animate",id ,...)
	end)
	
	register("GetParticleSystem", ParticleSystem.singleton)
	local idx = 0;
	register("CreateParticle", function (x,y,z, params)
		idx = idx + 1;
		local name = string.format("particle_%s", idx);
		if params then
			return ParticleSystem.singleton().createScene(name,x, y, z )
		else
			return ParticleSystem.singleton().createScene(name , x, y, z)
		end
	end)
  register("CreateBillboardSet",function(x,y,z)
      return BillboardSet:new({mX=x,mY=y,mZ=z})
    end)
	

	register("Tip", function (str, dur, color, id)
		BroadcastHelper.PushLabel({id=id, label = str,max_duration = dur or 3000, color =  color or "255 255 255", scaling=1, bold=true, shadow=true,});
	end)


	-- resource
	register("GetResourceImage", function (params, callback) 
		if params.pid then 
			ResourceManager.downloadFileByPhysicalId(params.pid, callback, params.hash );
		end
	end)
	register("GetResourceAudio", function (params, callback)
		if not params.pid then return end; 
		local name = params.hash
		local ext = params.ext or "mp3";
		ResourceManager.downloadFileByPhysicalId(params.pid, function (path, err)
			if err then 
				return 
			end
			local newpath = "";
			local hash = QiniuHash.hashFile(path);
			name = name or hash  or tostring(params.pid)
			newpath = string.format("temp/model/%s.%s",name, ext);
			ParaIO.CopyFile(path, newpath,false);
			callback(newpath);
		end, params.hash );
	end)
	register("GetResourceModel", function (params, callback) 
		if params.pid then 
			local name = params.hash
			local ext = params.ext or "fbx";
			ResourceManager.downloadFileByPhysicalId(params.pid, function (path, err)
				if err then 
					return 
				end
				local newpath = "";
				local hash = QiniuHash.hashFile(path);
				name = name or hash  or tostring(params.pid)
				if ext == "zip"  then 
					ParaIO.CreateDirectory(string.format("temp/model/%s", name));
					newpath = string.format("temp/model/%s/model.zip", name);
					ParaIO.CopyFile(path, newpath, true)
					FZip.UnZipFile(newpath);
			
					local ret = {};
					commonlib.Files.SearchFiles(ret,string.format("temp/model/%s", name),"*.fbx",0,1,true);
					if not ret[1] then return end
			
					newpath = string.format("temp/model/%s", name) .. ret[1];
			
				else
					newpath = string.format("temp/model/%s.%s",name, ext);
					ParaIO.CopyFile(path, newpath,false);
				end
				callback(newpath);
			end, params.hash );
		end
	end)

	register("GetSavedData", function ()
		return SavedData.getData();
	end)

	register("CreateMiniScene",function(name,renderTargetWidth,renderTargetHeight)
		return MiniSceneWrapper.create(name,{renderTargetWidth,renderTargetHeight});
		end);
	register("DestroyMiniScene",function(name)
		return MiniSceneWrapper.destroy(name);
		end);
	register("LoadTemplate",function(filename)
		NPL.load("(gl)script/Truck/Game/World/TruckBuildingTemplateManager.lua");
		local TruckBuildingTemplateManager=commonlib.gettable("Mod.Truck.Game.World.TruckBuildingTemplateManager");
		return TruckBuildingTemplateManager.parse(filename)
		end);
	register("CloseAvatar", function (entity)
		entity=entity or EntityManager.GetPlayer()
		NPL.load("(gl)script/Truck/Game/Avatar/AvatarAPI.lua");
		local AvatarAPI=commonlib.gettable("Truck.Game.Avatar.API");
		AvatarAPI.setAvatarValidate(false,tonumber(entity.username))
		end)
	register("OpenAvatar", function (entity)
		entity=entity or EntityManager.GetPlayer()
		NPL.load("(gl)script/Truck/Game/Avatar/AvatarAPI.lua");
		local AvatarAPI=commonlib.gettable("Truck.Game.Avatar.API");
		AvatarAPI.setAvatarValidate(true,tonumber(entity.username))
		end)
	register("AddCustomAvatarComponent", function (path,entity,replaceableTexturePath,replaceableTextureID)
		local model=ParaScene.CreateObject("CGeosetObject",path, 0,0,0);
		model:SetField("assetfile", path);
		model:SetAttribute(0x80,true);
		model:SetField("RenderDistance",100);
		if replaceableTexturePath then
			replaceableTextureID=replaceableTextureID or 2
			model:SetReplaceableTexture(replaceableTextureID,ParaAsset.LoadTexture("",replaceableTexturePath,1))
		end
		entity = entity or EntityManager.GetPlayer()
		entity:GetInnerObject():AddChild(model)
		return model
		end)
	register("RemoveCustomAvatarComponent", function (model)
		ParaScene.Attach(model)
		ParaScene.Detach(model)
		end)
	register("AddAttachment", function (path,attachment,entity,scaling,replaceableTexturePath,replaceableTextureID)
		entity = entity or EntityManager.GetPlayer()
		if replaceableTexturePath then
			entity:GetInnerObject():ToCharacter():AddAttachment(ParaAsset.LoadParaX("",path),attachment,-1,scaling or 1,ParaAsset.LoadTexture("",replaceableTexturePath,1),replaceableTextureID or 2);
		else
			entity:GetInnerObject():ToCharacter():AddAttachment(ParaAsset.LoadParaX("",path),attachment,-1,scaling or 1);
		end
		end)
	register("RemoveAttachment", function (attachment,entity)
		entity = entity or EntityManager.GetPlayer()
		entity:GetInnerObject():ToCharacter():RemoveAttachment(attachment);
		end)
	register("GetPlayerAvatar", function (uid,callback, force)
			NPL.load("(gl)script/Truck/Game/Avatar/AvatarAPI.lua");
			local AvatarAPI=commonlib.gettable("Truck.Game.Avatar.API");
			AvatarAPI.__caches = AvatarAPI.__caches or {};
			if AvatarAPI.__caches[uid] and not force then 
				callback(AvatarAPI.__caches[uid])
			else
				AvatarAPI.retrieveAvatar(uid,function (avatar)
					AvatarAPI.__caches[uid] = avatar
					callback(avatar);
				end)
			end
		end)
	register("SetEntityAvatar", function (entity,componentHandles,skinColour,avatarComponentsColours)
		NPL.load("(gl)script/Truck/Game/Avatar/AvatarAPI.lua");
		local AvatarAPI=commonlib.gettable("Truck.Game.Avatar.API");
		if not componentHandles then
		if entity.mAvatarHandle then
			AvatarAPI.destroyAvatar(entity.mAvatarHandle);
			entity.mAvatarHandle=nil;
		end
		else
		entity.mAvatarHandle=AvatarAPI.createAvatar(function()
			return entity:GetInnerObject()
			end,nil,componentHandles);
		AvatarAPI.setAvatarSkinColour(entity.mAvatarHandle,skinColour);
		for i,component_handle in pairs(componentHandles) do
			AvatarAPI.setAvatarComponentColour(entity.mAvatarHandle,component_handle,avatarComponentsColours[component_handle]);
		end
		end
		end)
	register("SetReplaceableTexture",function(entity,texPath,materialIndex)
		materialIndex = materialIndex or 2
		entity:GetInnerObject():SetReplaceableTexture(materialIndex,ParaAsset.LoadTexture("",texPath,1))
	end)
	register("OnPreGenerateChunk",function(func)
			if type(func) == "function" then
				NPL.load("(gl)script/Truck/Utility/MiniGameEventManager.lua");
				local MiniGameEventManager=commonlib.gettable("Mod.Truck.Utility.MiniGameEventManager");
				MiniGameEventManager.setListener("OnPreGenerateChunk",func)
			end
		end
	)
	register("OnPostGenerateChunk",function(func)
			if not func or type(func) == "function" then
				NPL.load("(gl)script/Truck/Utility/MiniGameEventManager.lua");
				local MiniGameEventManager=commonlib.gettable("Mod.Truck.Utility.MiniGameEventManager");
				MiniGameEventManager.setListener("OnPostGenerateChunk",func)
			end
		end
	)
	register("SetBlockDirect",function(x,y,z,blockID)
			ParaTerrain_SetBlockTemplateByIdx(x,y,z,blockID or 0)
		end
	)
	register("Async",function(file,callback,...)
			local Async = commonlib.gettable("Mod.Truck.Utility.Async");
			local future = Async.call(file, ...);
			future:get(function(...)
					if callback then
						callback(...)
					end
			end)
		end
	)
	register("CreatePerlinNoise",function(constructionParameter)
			NPL.load("(gl)script/Truck/Utility/Noise.lua")
			return Devil.Common.new(Devil.Utility.PerlinNoise,constructionParameter)
		end)
	register("DestroyPerlinNoise",function(inst)
			NPL.load("(gl)script/Truck/Utility/Noise.lua")
			return Devil.Common.delete(inst)
		end)
end

function Interfaces.unload(environment)
	local Independent = commonlib.gettable("Mod.Truck.Independent");

	for k,v in pairs(environment.__modules or {}) do 
		if v.clear then 
			Independent.call(v.clear, v);
		end
	end

	local UISystem=commonlib.gettable("Mod.Truck.Game.MiniGameUI.System");
	UISystem.shutdown();

	for k,v in pairs(environment.__timer or {}) do 
		v:Change();
	end

	for k,v in pairs(environment.__entities or {}) do 
		v:SetDead()
	end

	for k,v in pairs(environment.__uis or {}) do 
		v:destroy();
	end

	NPL.load("(gl)script/Truck/Game/Input/InputListener.lua");
	local InputListener = commonlib.gettable("Mod.Truck.Game.Input.InputListener");
	InputListener.enablePlayerController(true)
    local EntityController = NPL.load("script/Truck/Game/Input/EntityController.lua")
	EntityController.enableKeyboard(true)
	ParaScene.GetPlayer():SetField("AutoWalkupBlock", true);
	NPL.load("(gl)script/Truck/Game/ParticleSystem/ParticleSystem.lua");
	local ParticleSystem=commonlib.gettable("Truck.Game.ParticleSystem");
	ParticleSystem.shutdown();
	NPL.load("(gl)script/Truck/Game/Input/InputListener.lua");
	local InputListener = commonlib.gettable("Mod.Truck.Game.Input.InputListener");
	InputListener.enablePlayerController(true)
	ParaCamera.SwitchPerspectiveView()
end

