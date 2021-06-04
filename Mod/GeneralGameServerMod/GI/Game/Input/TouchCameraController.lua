--[[
    NPL.load("(gl)script/Truck/Game/Input/TouchCameraController.lua");
    local TouchCameraController = commonlib.gettable("Mod.Truck.Game.Input.TouchCameraController");
]]
NPL.load("(gl)script/Truck/Game/Input/TouchSession.lua");
local TouchSession = commonlib.gettable("Mod.Truck.Game.Input.TouchSession");
local TouchCameraController = commonlib.gettable("Mod.Truck.Game.Input.TouchCameraController");

local camera_smoothness = 0.4;
local camera_start = nil;
local liftup = nil
local rot_y = nil;
local targetCameraYaw;
local targetCameraPitch;
local preCameraYaw;
local preCameraPitch;
local camera_timer
local cameraYaw
local cameraPitch;

function TouchCameraController.handleTouchEvent(event)
    --echo("cellfy", "----------------------------------touch camera controller handle touch event----------------------------------");
	if event.accepted then
		stop();
		return;
	end

    local session = TouchSession.get(event.id);
    if TouchSession.size() > 1 or not session then
        --echo("cellfy", "----------------------------------tcch stop----------------------------------");
        stop();
    else
        if(event.type == "WM_POINTERDOWN") then
            --echo("cellfy", "----------------------------------tcch down----------------------------------");
            camera_start = session;
            RotateCamera(session);
            return true
        elseif(event.type == "WM_POINTERUPDATE") and session.isMoving then
            --echo("cellfy", "----------------------------------tcch update----------------------------------");
            RotateCamera(session);
            return true;
        elseif(event.type == "WM_POINTERUP") then
            --echo("cellfy", "----------------------------------tcch up----------------------------------");
            stop();
        end
    end
end

function stop()
    if (camera_timer) then
        camera_timer:Change()
    end
    camera_start = nil;
    liftup = nil;
    rot_y = nil;

end

function RotateCamera(touch_session)
	if(touch_session and liftup and rot_y) then
		local InvertMouse = GameLogic.options:GetInvertMouse();
		-- the bigger, the more precision. 
		local camera_sensitivity = GameLogic.options:GetSensitivity()*1000+10;
		local delta_x, delta_y = touch_session.ox , touch_session.oy
		
		if(delta_x~=0) then
			targetCameraYaw = rot_y - (delta_x) / camera_sensitivity * if_else(InvertMouse, 1, -1);
		end
		if(delta_y~=0) then
			local liftup = liftup - delta_y / camera_sensitivity * if_else(InvertMouse, 1, -1);
			targetCameraPitch = math.max(-1.57, math.min(liftup, 1.57));
		end
	else
		local att = ParaCamera.GetAttributeObject();
		rot_y = att:GetField("CameraRotY", 0);
		preCameraYaw = rot_y;
		liftup = att:GetField("CameraLiftupAngle", 0);
		preCameraPitch = liftup;
		camera_timer = camera_timer or commonlib.Timer:new({callbackFunc = function(timer)
			OnTickCamera(timer);
		end})
		camera_timer:Change(0.0166, 0.0166);
	end
end

function OnTickCamera(timer)
	local bCameraReached = true;
	if(preCameraYaw ~= targetCameraYaw and preCameraYaw and targetCameraYaw) then
		-- smoothing
		cameraYaw = preCameraYaw + (targetCameraYaw - preCameraYaw) * camera_smoothness
		if(math.abs(targetCameraYaw - cameraYaw) < 0.001) then
			cameraYaw = targetCameraYaw;
		else
			bCameraReached = false;
		end
		local att = ParaCamera.GetAttributeObject();
		att:SetField("CameraRotY", cameraYaw);
		preCameraYaw = cameraYaw;
	end
	if(targetCameraPitch ~= preCameraPitch and targetCameraPitch and preCameraPitch) then
		-- smoothing
		cameraPitch = preCameraPitch + (targetCameraPitch - preCameraPitch) * camera_smoothness
		if(math.abs(targetCameraPitch - cameraPitch) < 0.001) then
			cameraPitch = targetCameraPitch;
		else
			bCameraReached = false;
		end
		local att = ParaCamera.GetAttributeObject();
		att:SetField("CameraLiftupAngle", cameraPitch);
		preCameraPitch = cameraPitch;
	end
	if(bCameraReached and not camera_start) then
		timer:Change(nil);
	end
end
