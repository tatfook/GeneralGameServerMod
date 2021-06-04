--[[
    NPL.load("(gl)script/Truck/Game/Input/InputProcessor.lua");
    local InputProcessor = commonlib.gettable("Mod.Truck.Game.Input.InputProcessor");
]]

local InputProcessor = commonlib.gettable("Mod.Truck.Game.Input.InputProcessor");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/InfoWindow.lua");
local InfoWindow = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.InfoWindow");
NPL.load("(gl)script/ide/System/Scene/Overlays/OverlayPicking.lua");
local OverlayPicking = commonlib.gettable("System.Scene.Overlays.OverlayPicking");
NPL.load("(gl)script/Truck/Game/Editor/Editor.lua");
local Editor = commonlib.gettable("Mod.Truck.Game.Editor");
NPL.load("(gl)script/Truck/Game/Editor/Selector.lua");
local Selector = commonlib.gettable("Mod.Truck.Game.Editor.Selector");
local UIManager= commonlib.gettable("Mod.Truck.Game.UI.UIManager");
local EntityController = NPL.load("script/Truck/Game/Input/EntityController.lua");



local click_data = 
{
	last_select_block = {}	
}

local cache = {};
function InputProcessor.mousePick(bPickOverlay, force, bPickBlocks, bPickPoint, bPickObjects, picking_dist)
	local mx, my = ParaUI.GetMousePosition();
	local result;
	if (not force and cache.last_x == mx and cache.last_y == my) then	
		result = cache
		if (bPickOverlay and not cache.overlay) then
			OverlayPicking:SetResultDirty(true);
			OverlayPicking:Pick(nil, nil, 8, 8)
			result.overlay = OverlayPicking:GetActivePickingName() or 0
		end
	else
		result = SelectionManager:MousePickBlock(bPickBlocks, bPickPoint, bPickObjects, picking_dist);
		if bPickOverlay then
			OverlayPicking:SetResultDirty(true);
			OverlayPicking:Pick(nil, nil, 8, 8)
			result.overlay = OverlayPicking:GetActivePickingName() or 0
		else
			result.overlay = nil;
		end
	end

	--make player looking at the picking point
	CameraController.OnMousePick(result, picking_dist or SelectionManager:GetPickingDist());
	
	if((result.length and result.length < (picking_dist or 100))or bPickOverlay ) then
		cache = result;
		cache.last_x = mx;
		cache.last_y = my;
		return result;
	else 
		return {};
	end

end

function InputProcessor.showWireFrame()
	local result = InputProcessor.mousePick(false, true)
	if not result then 
		return
	end

	InputProcessor.pickBlock(result)
	InputProcessor.pickEntity(result)
end

function InputProcessor.pickBlock(result)
	if (not result.blockX) then
		return 
	end
	if(click_data.last_select_block.blockX ~= result.blockX or click_data.last_select_block.blockY ~= result.blockY or click_data.last_select_block.blockZ ~= result.blockZ) then
		if(click_data.last_select_block.blockX) then
				
			ParaTerrain.SelectBlock(click_data.last_select_block.blockX,click_data.last_select_block.blockY, click_data.last_select_block.blockZ,false,GameLogic.options.wire_frame_group_id);
		end
		if(click_data.last_select_block.group_index) then
			ParaSelection.ClearGroup(click_data.last_select_block.group_index);
			click_data.last_select_block.group_index = nil;
		end

		local selection_effect;
		if(result and result.block_id and result.block_id > 0) then
			local block = block_types.get(result.block_id);
			if(block) then
				selection_effect = block.selection_effect;
				if(selection_effect == "model_highlight") then
					if(block:AddToSelection(result.blockX,result.blockY, result.blockZ, 2)) then
						selection_effect = "none";
						click_data.last_select_block.group_index = 2;
					end
				end
			end
		end
			
		if(not selection_effect) then
			ParaTerrain.SelectBlock(result.blockX,result.blockY, result.blockZ,true, GameLogic.options.wire_frame_group_id);	
		elseif(selection_effect == "none") then
			--  do nothing
		else
			-- TODO: other effect. 
			ParaTerrain.SelectBlock(result.blockX,result.blockY, result.blockZ,true, GameLogic.options.wire_frame_group_id);	
		end
		click_data.last_select_block.blockX, click_data.last_select_block.blockY, click_data.last_select_block.blockZ = result.blockX,result.blockY, result.blockZ;
	end
end


function InputProcessor.pickEntity(result)
	if(not result.block_id and result.entity and result.obj) then
		click_data.last_select_entity = result.entity;
		ParaSelection.AddObject(result.obj, 2);
	elseif(click_data.last_select_entity) then
		click_data.last_select_entity = nil;
		ParaSelection.ClearGroup(2);
	end
end

function InputProcessor.clearSelection()
	ParaTerrain.DeselectAllBlock(GameLogic.options.wire_frame_group_id);
	click_data.last_select_block.blockX, click_data.last_select_block.blockY, click_data.last_select_block.blockZ = nil, nil,nil;

	if(click_data.last_select_entity) then
		click_data.last_select_entity = nil;
		ParaSelection.ClearGroup(2);
	end

	SelectionManager:ClearPickingResult();
end

function InputProcessor.clickEntity( event, paras)
	local selection = InputProcessor.mousePick();
	local side = event.mouse_button;

	if(selection and selection.obj and selection.entity and (not selection.block_id or selection.block_id == 0)) then
		return selection.entity:OnClick(selection.blockX, selection.blockY, selection.blockZ, side)
	end
end

function InputProcessor.triggerBlock(event)
	local selection = InputProcessor.mousePick();

	if(selection and selection.blockX and selection.block_id and selection.block_id>0) then
		-- if it is a right click, first try the game logics if it is processed. such as an action neuron block.
		return  GameLogic.GetPlayerController():OnClickBlock(selection.block_id, selection.blockX, selection.blockY, selection.blockZ, event.mouse_button, EntityManager.GetPlayer(), selection.side);
	end
end


local function OnCreateSingleBlock(x,y,z, block_id, result)
	local side_region;
	if(result.y) then
		if(result.side == 4) then
			side_region = "upper";
		elseif(result.side == 5) then
			side_region = "lower";
		else
			local _, center_y, _ = BlockEngine:real(0,result.blockY,0);
			if(result.y > center_y) then
				side_region = "upper";
			elseif(result.y < center_y) then
				side_region = "lower";
			end
		end
	end

	if(EntityManager.GetFocus():CanReachBlockAt(result.blockX,result.blockY,result.blockZ)) then
		local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = x,blockY = y, blockZ = z, entityPlayer = EntityManager.GetPlayer(), block_id = block_id, side = result.side, from_block_id = result.block_id, side_region=side_region })
		task:Run();
	end
end

function InputProcessor.createBlock(event,paras)
	local result = InputProcessor.mousePick();
	
	if not result or not result.blockX then
		return 
	end

	local x,y,z = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
	local itemStack = EntityManager.GetPlayer():GetItemInRightHand();
	local block_id = 0;
	local block_data = nil;
	if(itemStack) then
		block_id = itemStack.id;
		local item = itemStack:GetItem();
		if(item) then
			block_data = item:GetBlockData(itemStack);
		else
			LOG.std(nil, "debug", "BaseContext", "no block definition for %d", block_id or 0);
			return;
		end
	end

	local GamingRoomInfo = commonlib.gettable("Mod.Truck.Game.MultiPlayer.GamingRoomInfo");
	local YcProfile = commonlib.gettable("Mod.Truck.Network.YcProfile");
	local meminfo = GamingRoomInfo.getPlayer(YcProfile.uid);
	if meminfo and not meminfo:canUseBlock(block_id) then
		return;
	end

	Statistics.SendKeyValue("Build.BlocksUsage",tostring(block_id))
	
	if(block_id and block_id > 4096) then
		-- for special blocks. 
		local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = x,blockY = y, blockZ = z, block_id = block_id, side = result.side, entityPlayer = EntityManager.GetPlayer()})
		task:Run();
	else
		if(paras and paras.multi == "true") then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FillLineTask.lua");
			local task = MyCompany.Aries.Game.Tasks.FillLine:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, to_data = block_data, side = result.side})
			task:Run();
		else
			OnCreateSingleBlock(x,y,z, block_id, result)
		end
	end
	return true;
end

function InputProcessor.replaceBlock(event,paras)
	local result = InputProcessor.mousePick();
	if not result then
		return false
	end
	local x,y,z = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
	local itemStack = EntityManager.GetPlayer():GetItemInRightHand();
	local block_id = 0;
	local block_data = nil;
	if(itemStack) then
		block_id = itemStack.id;
		local item = itemStack:GetItem();
		if(item) then
			block_data = item:GetBlockData(itemStack);
		else
			LOG.std(nil, "debug", "BaseContext", "no block definition for %d", block_id or 0);
			return;
		end
	end

	local GamingRoomInfo = commonlib.gettable("Mod.Truck.Game.MultiPlayer.GamingRoomInfo");
	local YcProfile = commonlib.gettable("Mod.Truck.Network.YcProfile");
	local meminfo = GamingRoomInfo.getPlayer(YcProfile.uid);
	if meminfo and not meminfo:canUseBlock(block_id) then
		return;
	end

	Statistics.SendKeyValue("Build.BlocksUsage",tostring(block_id))
	
	if(paras and paras.multi == "true") then
		if(block_id or result.block_id == block_types.names.water) then
			-- if ctrl key is pressed, we will replace block at the cursor with the current block in right hand. 
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
			local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, to_id = block_id or 0, to_data = block_data, max_radius = 30})
			task:Run();
		end
	else
		if(block_id) then
			-- if alt key is pressed, we will replace block at the cursor with the current block in right hand. 
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ReplaceBlockTask.lua");
			local task = MyCompany.Aries.Game.Tasks.ReplaceBlock:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, to_id = block_id, max_radius = 0, side = result.side})
			task:Run();
		end
	end
	return true;
end


function InputProcessor.destroyBlock(event, paras)
	if paras.tool then
		local itemStack = EntityManager.GetPlayer():GetItemInRightHand();
		local block_id = 0;
		local block_data = nil;
		if(itemStack) then
			block_id = itemStack.id;
		end
		local canDestroyBlock = block_id == tonumber(paras.tool)
		if (not canDestroyBlock) then
			return false
		end
	end


	local result = InputProcessor.mousePick();
	if (not result or not result.blockX) then
		return false;
	end

	local block_template = BlockEngine:GetBlock(result.blockX,result.blockY,result.blockZ);

	if (paras and paras.multi == "true") then
		-- editor mode hold shift key will destroy several blocks. 
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DestroyNearbyBlocksTask.lua");
		-- just around the player
		local task = MyCompany.Aries.Game.Tasks.DestroyNearbyBlocks:new({blockX=result.blockX, blockY=result.blockY, blockZ=result.blockZ, block_id = result.block_id, explode_time=200, })
		task:Run();
		return true;

	elseif(block_template and block_template:CanDestroyBlockAt(result.blockX,result.blockY,result.blockZ, GameLogic.GetMode())) then
		if(EntityManager.GetFocus():CanReachBlockAt(result.blockX,result.blockY,result.blockZ)) then
			local task = MyCompany.Aries.Game.Tasks.DestroyBlock:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, is_allow_delete_terrain=is_allow_delete_terrain})
			task:Run();
			return true;
		end
	end
end

function InputProcessor.pickToHand(event)
	local result = InputProcessor.mousePick();

	if (result and result.blockX and result.block_id) then
		GameLogic.GetPlayerController():PickBlockAt(result.blockX, result.blockY, result.blockZ);
		return true;
	elseif(result and result.entity ) then
		local item_class = result.entity:GetItemClass();
		if(item_class) then
			local itemStack = item_class:ConvertEntityToItem(result.entity);
			if(itemStack) then
				GameLogic.GetPlayerController():SetBlockInRightHand(itemStack);
				return true;
			end
		end
	end
	return false;
end

function InputProcessor.editBlock(event, paras)
	local ret = InputProcessor.selectBlock(event,paras);
	if ret then
    	local CommonUtility = commonlib.gettable("Mod.Truck.Utility.CommonUtility");
		if CommonUtility:IsMobilePlatform() then
			local leftShapeUI = UIManager.getUI("LeftShapeSetBar")
			if leftShapeUI then
				return true
			end
			local uimain = UIManager.getUI("UIMain")
			UIManager.createUI("LeftShapeSetBar",uimain,nil,{name="select"})
			return true;
		else
			local leftShapeUIPC = UIManager.getUI("LeftShapeSetBar_PC")
			if leftShapeUIPC then
				return true
			end
			local uimain = UIManager.getUI("UIMain")
			UIManager.createUI("LeftShapeSetBar_PC",uimain,nil,{name="select"})
			return true;
		end
	end
	return false;
	-- local result = InputProcessor.mousePick();
	-- if(result and result.block_id) then
	-- 	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
	-- 	local task = MyCompany.Aries.Game.Tasks.SelectBlocks:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ})
	-- 	task:Run();
	-- 	if(paras and paras.multi) then
	-- 		task:RefreshImediately();
	-- 		-- Ctrl + shift + left click to select all connected blocks
	-- 		task.SelectAll(true);
	-- 	end
	-- 	return true
	-- end
	-- return false;
end


function InputProcessor.teleport(event, paras)
	if paras and (paras.upward == "true" or paras.downward == "true") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
		local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({mode="vertical", isUpward = paras.upward == "true", add_to_history=false});
		task:Run();
	else
		local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
		local result = InputProcessor.mousePick();
		if not result then
			return false
		end
		local x, y, z = result.blockX, result.blockY, result.blockZ;
		local block_template = BlockEngine:GetBlock(x, y, z);
		if(block_template and not block_template.obstruction) then
			local block_template = BlockEngine:GetBlock(x, y-1, z);
			if(block_template and block_template.obstruction) then
				y = y - 1;
			end
		end
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeleportPlayerTask.lua");
		local task = MyCompany.Aries.Game.Tasks.TeleportPlayer:new({blockX = x, blockY = y, blockZ = z})
		task:Run();	
	end
	return true;
end

function InputProcessor.undo(event)
	UndoManager.Undo();
	return true;
end

function InputProcessor.redo(event)
	UndoManager.Redo();
	return true;
end

function InputProcessor.copyMousePosition(event, paras)
	if paras and paras.relative then
		InfoWindow.CopyToClipboard("relativemousepos")
	else
		InfoWindow.CopyToClipboard("mousepos")
	end
	return true
end

function InputProcessor.toggleSelection(event)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SelectBlocksTask.lua");
	local SelectBlocks = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
	SelectBlocks.ToggleLastInstance();
	return true
end

function InputProcessor.openMCMLBrowser()
	Map3DSystem.App.Commands.Call("File.MCMLBrowser");
	return true
end

function InputProcessor.toggleCamera()
	GameLogic.ToggleCamera();
	return true
end

function InputProcessor.openConsole()
	local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
	CommandManager:RunCommand("/open npl://console");
	return true
end

function InputProcessor.toggleFov()
	CameraController.ToggleFov(GameLogic.options.inspector_fov);
	return true
end

function InputProcessor.jump()
	EntityController.go("jump")
	return true
end

function InputProcessor.toggleFly()
	if EntityController.check("fly") or EntityController.check("flyidle") then 
		EntityController.go("fall")
	else
		EntityController.go("flyidle");
	end
	
	-- GameLogic.ToggleFly();
	return true
end

function InputProcessor.throwBlock()
	GameLogic.GetPlayerController():ThrowBlockInHand();
	return true
end

function InputProcessor.openDebuger()
	Map3DSystem.App.Commands.Call("Help.Debug");
	return true
end

function InputProcessor.useItem(event)
	local curItem = GameLogic.GetPlayerController():GetItemInRightHand();
	curItem:event(event);
	return event.accepted;
end

NPL.load("(gl)script/apps/Aries/Creator/Game/World/CameraController.lua");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
function InputProcessor.cameraZoomIn()
	CameraController.ZoomInOut(true);
	return true;
end

function InputProcessor.cameraZoomOut()
	CameraController.ZoomInOut(false);
	return true;
end

function InputProcessor.flyUpward()
	local player = EntityManager.GetPlayer();
	if(player)then
		if(not player:IsFlying()) then
			player:ToggleFly(true);
		end
		player:Jump();
	end
	return true;
end
function InputProcessor.closeFly()
	local player = EntityManager.GetPlayer();
	if(player)then
		if(player:IsFlying()) then
			player:ToggleFly(false);
		end
	end
end
function InputProcessor.openFly()
	local player = EntityManager.GetPlayer();
	if(player)then
		if(not player:IsFlying()) then
			player:ToggleFly(true);
		end
	end
end
function InputProcessor.flyDownward()
	local player = EntityManager.GetPlayer();
	local bx, by, bz = player:GetBlockPos();
	local block = BlockEngine:GetBlock(bx, by-1, bz);
	if(block and block.id ~= 0) then
		player:ToggleFly(false);
	else
		local obj = player:GetInnerObject();
		if(obj) then
			obj:ToCharacter():AddAction(action_table.ActionSymbols.S_FLY_DOWNWARD);
		end
	end
	return true;
end

function InputProcessor.selectBlock(event, paras)
	local result = InputProcessor.mousePick();
	if (not result or not result.blockX) then
		return
	end



	-- if paras.extend == "true" then
		Selector.extend(result.blockX,result.blockY,result.blockZ)
	-- else
		-- Selector.selectOne(result.blockX,result.blockY,result.blockZ)
	-- end


	return true;
end


function InputProcessor.unselectBlock(event, paras)
	local result = InputProcessor.mousePick();
	if (not result or not result.blockX) then
		return
	end

	if paras.all == "true" then
		Selector.unselectAll();
	else
		return Selector.unselectOne(result.blockX,result.blockY,result.blockZ)
	end
	return true;
end

function InputProcessor.blockTurnLeft(event, paras)
	if not Editor.isTransforming() then
		return 
	end
	Editor.rotate(0,math.pi * 0.5,0);
	return true;
end

function InputProcessor.blockTurnRight(event, paras)
	if not Editor.isTransforming() then
		return 
	end
	Editor.rotate(0,math.pi * 0.5,0);
	return true;
end

function InputProcessor.blockScaleUp(event, paras)
	if not Editor.isTransforming() then
		return 
	end	
	Editor.scale(1.1, 1.1, 1.1);
	return true;
end

function InputProcessor.blockScaleDown(event, paras)
	if not Editor.isTransforming() then
		return 
	end	
	Editor.scale(0.9,0.9,0.9);
	return true;
end

local input;
function InputProcessor.setInput(op)
	input = op;
end

function InputProcessor.input(event, paras)
	local result = InputProcessor.mousePick();
	if input then
		event.accepted = input(event, result)
		return event.accepted;
	else
		return false;
	end	
end

function InputProcessor.pasteSelectedBlock()
	if not Editor.isTransforming() then
		return 
	end

	local result = InputProcessor.mousePick();
	if not result or not result.blockX then 
		return 
	end

	local x,y,z = Editor.getCenter();
	Editor.setPosition(result.blockX - x, result.blockY - y + 1, result.blockZ - z);
end

function InputProcessor.toggleCursor()
	NPL.load("(gl)script/apps/Aries/Creator/Game/World/CameraController.lua");
	local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
	
	local mode = CameraController:GetMode()
	if mode == 0 then 
		CameraController.ToggleCamera(3)
	elseif mode == 3 then 
		CameraController.ToggleCamera(0)
	elseif mode == 1 then 
		CameraController.ToggleCursor();
	end
end

