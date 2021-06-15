--[[
Title: SceneAPI
Author(s):  wxa
Date: 2021-06-01
Desc: API 模板文件
use the lib:
------------------------------------------------------------
local SceneAPI = NPL.load("Mod/GeneralGameServerMod/GI/Independent/API/SceneAPI.lua");
------------------------------------------------------------
]]
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");

local SceneAPI = NPL.export()

local last_select_entity = nil;
local last_select_block = {};

local function ClearBlockPickDisplay()
	ParaTerrain.DeselectAllBlock(GameLogic.options.wire_frame_group_id);
	last_select_block.blockX, last_select_block.blockY, last_select_block.blockZ = nil, nil,nil;
end

local function HighlightPickBlock(result)
	if(last_select_block.blockX ~= result.blockX or last_select_block.blockY ~= result.blockY or last_select_block.blockZ ~= result.blockZ) then
        -- 取消选择
		if(last_select_block.blockX) then 
            ParaTerrain.SelectBlock(last_select_block.blockX, last_select_block.blockY, last_select_block.blockZ, false, GameLogic.options.wire_frame_group_id);
        end

        -- 取消组选择
		if(last_select_block.group_index) then
			ParaSelection.ClearGroup(last_select_block.group_index);
			last_select_block.group_index = nil;
		end

        -- 选择特效
		local selection_effect;
		if(result and result.block_id and result.block_id > 0) then
			local block = block_types.get(result.block_id);
			if(block) then
				selection_effect = block.selection_effect;
				if(selection_effect == "model_highlight") then
					if(block:AddToSelection(result.blockX,result.blockY, result.blockZ, 2)) then
						selection_effect = "none";
						last_select_block.group_index = 2;
					end
				end
			end
		end
			
        -- 选择默认效果
		if(not selection_effect) then
			ParaTerrain.SelectBlock(result.blockX, result.blockY, result.blockZ, true, GameLogic.options.wire_frame_group_id);	
		elseif(selection_effect == "none") then
			--  do nothing
		else
			-- TODO: other effect. 
			ParaTerrain.SelectBlock(result.blockX, result.blockY, result.blockZ, true, GameLogic.options.wire_frame_group_id);	
		end
		last_select_block.blockX, last_select_block.blockY, last_select_block.blockZ = result.blockX,result.blockY, result.blockZ;
	end
end

local function ClearEntityPickDisplay()
    if(last_select_entity) then
        last_select_entity = nil;
        ParaSelection.ClearGroup(1);
    end
end

local function HighlightPickEntity(result)
    if(not result.block_id and result.entity and result.obj) then
		last_select_entity = result.entity;
		ParaSelection.AddObject(result.obj, 1);
		ClearBlockPickDisplay();
	elseif(last_select_entity) then
		last_select_entity = nil;
		ParaSelection.ClearGroup(1);
	end
end

local function ClearPickDisplay()
	ClearBlockPickDisplay();
    ClearEntityPickDisplay();
end

local function MousePickTimerCallBack()
    local result = SelectionManager:MousePickBlock();
	CameraController.OnMousePick(result, SelectionManager:GetPickingDist());
	
	-- highlight the block or terrain that the mouse picked
	if(result.length and result.length < SelectionManager:GetPickingDist()) then
    	HighlightPickBlock(result);
		HighlightPickEntity(result);
	else
		ClearPickDisplay();
	end
end

local function MousePick()
    local result = SelectionManager:MousePickBlock();
	CameraController.OnMousePick(result, SelectionManager:GetPickingDist());
    if(result.length and result.length<SelectionManager:GetPickingDist()) then return result end
end

local function SetCameraMode(mode)
    CameraController.ToggleCamera(mode);
end

local function GetCameraMode()
    return CameraController.GetMode();
end

local function GetCameraRotation()
    local attr = ParaCamera.GetAttributeObject();		
    return attr:GetField("CameraLiftupAngle"), attr:GetField("CameraRotY"), attr:GetField("CameraRotZ");
end

local function SetCameraRotation(x,y,z)
    local attr = ParaCamera.GetAttributeObject();		
    if x then attr:SetField("CameraLiftupAngle", x) end
    if y then attr:SetField("CameraRotY", y) end
    if z then attr:SetField("CameraRotZ", z) end
end

local function CameraZoomInOut(cam_dist)
    local attr = ParaCamera.GetAttributeObject();
    attr:SetField("CameraObjectDistance", cam_dist);
end	

local function SetCameraLookAtBlockPos(bx, by, bz)
    local x, y, z = BlockEngine:ConvertToRealPosition_float(bx, by, bz);
    ParaCamera.SetLookAtPos(x, y, z);
end
local function GetFOV()
    return CameraController.GetFov();
end

local function SetFOV(fov, speed)
    CameraController.AnimateFieldOfView(fov or GameLogic.options.normal_fov, speed);
end

local function GetScreenSize()
    local root_ = ParaUI.GetUIObject("root");
    local _, _, width_screen, height_screen = root_:GetAbsPosition();
    return width_screen, height_screen;
end

setmetatable(
    SceneAPI,
    {
        __call = function(_, CodeEnv)
            CodeEnv.SwitchOrthoView = ParaCamera.SwitchOrthoView
            CodeEnv.SwitchPerspectiveView = ParaCamera.SwitchPerspectiveView
            CodeEnv.EnableAutoCamera = function(...) return CodeEnv.SceneContext:EnableAutoCamera(...) end
            CodeEnv.SetCameraMode = SetCameraMode
            CodeEnv.GetCameraMode = GetCameraMode
            CodeEnv.GetCameraRotation = GetCameraRotation
            CodeEnv.SetCameraRotation = SetCameraRotation
            CodeEnv.SetCameraLookAtBlockPos = SetCameraLookAtBlockPos
            CodeEnv.CameraZoomInOut = CameraZoomInOut
            CodeEnv.GetFOV = GetFOV
            CodeEnv.SetFOV = SetFOV
            CodeEnv.GetScreenSize = GetScreenSize
            CodeEnv.GetPickingDist = function() return SelectionManager:GetPickingDist() end
	        CodeEnv.GetHomePosition = GameLogic.GetHomePosition
            CodeEnv.GetFacingFromCamera = Direction.GetFacingFromCamera
            CodeEnv.GetDirection2DFromCamera = Direction.GetDirection2DFromCamera

            -- mouse pick
            CodeEnv.HighlightPickBlock = HighlightPickBlock
            CodeEnv.HighlightPickEntity = HighlightPickEntity
            CodeEnv.ClearBlockPickDisplay = ClearBlockPickDisplay
            CodeEnv.ClearEntityPickDisplay = ClearEntityPickDisplay
            CodeEnv.ClearPickDisplay = ClearPickDisplay
            CodeEnv.MousePickTimerCallBack = MousePickTimerCallBack
            CodeEnv.MousePick = MousePick;
        end
    }
)
