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
NPL.load("(gl)script/apps/Aries/Creator/Game/World/CameraController.lua");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController");

local SceneAPI = NPL.export()

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
    if x then 
        attr:SetField("CameraLiftupAngle", x);
    end

    if y then 
        attr:SetField("CameraRotY", y);
    end

    if z then 
        attr:SetField("CameraRotZ", z);
    end
end

local function CameraZoomInOut(cam_dist)
    local attr = ParaCamera.GetAttributeObject();
    attr:SetField("CameraObjectDistance", cam_dist);
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
            CodeEnv.CameraZoomInOut = CameraZoomInOut
            CodeEnv.GetFOV = GetFOV
            CodeEnv.SetFOV = SetFOV
            CodeEnv.GetScreenSize = GetScreenSize
        end
    }
)
