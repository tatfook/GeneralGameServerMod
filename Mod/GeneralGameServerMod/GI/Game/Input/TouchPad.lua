--[[
    NPL.load("(gl)script/Truck/Game/Input/TouchPad.lua");
    local TouchPad = commonlib.gettable("Mod.Truck.Game.Input.TouchPad");

	desc:
		accept all touch inputs
]]

local UIManager = commonlib.gettable("Mod.Truck.Game.UI.UIManager");
local UIBase = commonlib.gettable("Mod.Truck.Game.UI.UIBase");

local ModuleManager = commonlib.gettable("Mod.Truck.Game.ModuleManager");

NPL.load("(gl)script/Truck/Game/Input/TouchSession.lua");
local TouchSession = commonlib.gettable("Mod.Truck.Game.Input.TouchSession");

local TouchPad = commonlib.inherit(UIBase,commonlib.gettable("Mod.Truck.Game.Input.TouchPad"));
UIManager.registerUI("TouchPad", TouchPad,"script/Truck/Game/Input/TouchPad.html",
{
	zorder = -1,
});

function TouchPad:onCreate()
	-- default to 300 ms. 
	self.min_hold_time = 300;
	-- default to 30 pixels
	self.finger_size = 30;
	-- the smaller, the smoother. value between (0,1]. 1 is without smoothing. 
	self.camera_smoothness = 0.4;
        echo("cellfy", "----------------------------------touch pad inited----------------------------------");
end

function TouchPad:onTouchScene(name, mcmlNode, touch)
    echo("cellfy", "----------------------------------on touch scene----------------------------------");
    echo("cellfy", touch);
	local session = TouchSession.handle(touch);

	ParaUI.SetMousePosition(touch.x, touch.y);

	ModuleManager.handleTouchEvent(touch)
end
