--[[
    NPL.load("(gl)script/Truck/Game/Input/InputListener.lua");
    local InputListener = commonlib.gettable("Mod.Truck.Game.Input.InputListener");
]]

NPL.load("(gl)script/Truck/Game/Input/InputProcessor.lua");
local InputProcessor = commonlib.gettable("Mod.Truck.Game.Input.InputProcessor");


local InputListener = commonlib.inherit(commonlib.gettable("System.Core.SceneContext"), commonlib.gettable("Mod.Truck.Game.Input.InputListener"));
local ModManager = commonlib.gettable("Mod.ModManager");

local instance;

function InputListener.enablePlayerController(enable)
	instance:EnableAutoCamera(enable)
end

function InputListener:ctor()
	--allow to notify mousemove event
	self:setMouseTracking(true)

	self:EnableAutoCamera(true);
	instance = self;
end


function InputListener:mousePressEvent(mouse_event)
	ModManager:handleMouseEvent(mouse_event);
end

function InputListener:mouseMoveEvent(mouse_event)
	ModManager:handleMouseEvent(mouse_event)
end

function InputListener:mouseReleaseEvent(mouse_event)
	ModManager:handleMouseEvent(mouse_event)
end

function InputListener:mouseWheelEvent(mouse_event)
	ModManager:handleMouseEvent(mouse_event)
end

function InputListener:keyPressEvent(key_event)
	ModManager:handleKeyEvent(key_event)
end

function InputListener:keyReleaseEvent(key_event)
	ModManager:handleKeyEvent(key_event)
end

