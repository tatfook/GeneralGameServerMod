--[[
    NPL.load("(gl)script/Truck/Game/Input/Input.lua");
    local Input = commonlib.gettable("Mod.Truck.Game.Input");
]]

--I suggest you to add game logic here , NOT UI LOGIC

local Input = commonlib.inherit(commonlib.gettable("Mod.Truck.Game.Module"),commonlib.gettable("Mod.Truck.Game.Input"));


local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
NPL.load("(gl)script/Truck/Game/Input/InputProcessor.lua");
local InputProcessor = commonlib.gettable("Mod.Truck.Game.Input.InputProcessor");
NPL.load("(gl)script/Truck/KeyInput.lua");
local KeyInput = commonlib.gettable("Mod.Truck.KeyInput");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
NPL.load("(gl)script/Truck/Utility/CommonUtility.lua");
local CommonUtility = commonlib.gettable("Mod.Truck.Utility.CommonUtility");

NPL.load("(gl)script/Truck/Game/Input/ButtonObject.lua");
local ButtonObject = commonlib.gettable("Mod.Truck.Game.Input.ButtonObject");
NPL.load("(gl)script/Truck/Game/Input/KeyObject.lua");
local KeyObject = commonlib.gettable("Mod.Truck.Game.Input.KeyObject");
NPL.load("(gl)script/Truck/Game/Input/TouchObject.lua");
local TouchObject = commonlib.gettable("Mod.Truck.Game.Input.TouchObject");
NPL.load("(gl)script/Truck/Game/Editor/Batch.lua");
local Batch = commonlib.gettable("Mod.Truck.Game.Batch");

local GamingRoomInfo = commonlib.gettable("Mod.Truck.Game.MultiPlayer.GamingRoomInfo");
local YcProfile = commonlib.gettable("Mod.Truck.Network.YcProfile");
local Selector = commonlib.gettable("Mod.Truck.Game.Editor.Selector");
local Independent = commonlib.gettable("Mod.Truck.Independent");
local AnimationController = NPL.load("script/Truck/Game/Input/AnimationController.lua");


local quickClick = 120
local damageBlock = 
{
	effect = true;
	usingTool = nil,
	maxBreakTime = 600.0,
	time = 0,

	clear = function (self)
		AnimationController.play("stand")

		local timer = self.timer;
		if (timer) then
			timer:Change()
			self.timer = nil
		end
		self.block = nil
		ParaTerrain.SetDamagedDegree(0.0);
	end,

	onmove = function (self)
		local result = InputProcessor.mousePick();
		local block = self.block
		if (not block) then
			return false
		end
		if (not result or not result.blockX or result.entity or 
			result.blockX ~= block.x or result.blockY ~= block.y or result.blockZ ~= block.z) then
			self:clear()
		end
		return false
	end,

	onrelease = function (self,event, paras)
		local result = InputProcessor.mousePick();
		local block = self.block
		if (not result or not block or result.blockX ~= block.x or result.blockY ~= block.y or result.blockZ ~= block.z) then
			self:clear()
			return false;
		end

		self:clear()
		local diff = ParaGlobal.timeGetTime() - self.time;
		if (diff >= self.maxBreakTime) then
			InputProcessor.destroyBlock(event, paras)
			return true;
		end

		return false;
	end,

	onpress = function (self, event)
		self:clear()
		if event.accepted then 
			return false;
		end
		local result = InputProcessor.mousePick();

		if (not result or not result.blockX or result.entity ) then
			return false
		end
		if self.usingTool then
			local itemStack = EntityManager.GetPlayer():GetItemInRightHand();
			local block_id = 0;
			local block_data = nil;
			if(itemStack) then
				block_id = itemStack.id;
			end
			local canDestroyBlock = block_id == self.usingTool
			if (not canDestroyBlock) then
				return false
			end
		end



		self.time = ParaGlobal.timeGetTime();
		ParaTerrain.SetDamagedBlock(result.blockX,result.blockY,result.blockZ);
		self.block = {x = result.blockX, y = result.blockY, z = result.blockZ};
		if self.effect then
			self.timer = commonlib.Timer:new({callbackFunc = function (t) 
				local diff = ParaGlobal.timeGetTime() - self.time;
				ParaTerrain.SetDamagedDegree(math.max(0,math.min(diff /self.maxBreakTime,1)) * 0.7);
				AnimationController.play("attack")
			end})

			local step = 3;
			local period = self.maxBreakTime / step;
			self.timer:Change(0 ,period);
		end
	end,
}

local function makeClickProcessor(paras, processor)
	local ctrl = paras.ctrl == "true";
	local shift = paras.shift == "true";
	local alt = paras.alt == "true";

	local click = ButtonObject.create(paras.hotkey,ButtonObject.Click, ctrl, shift, alt);
	click:setCallback(
		function (type,button, event) 
			if event.accepted then
				return false;
			else
				return processor(event, paras) 
			end
		end);
	return function (event) return click:handleEvent(event) end;
end

local function makeKeyProcessor(paras, processor)
	local ctrl = paras.ctrl == "true";
	local shift = paras.shift == "true";
	local alt = paras.alt == "true";

	local key = KeyObject.create(paras.hotkey,KeyObject.KeyDown, ctrl, shift, alt);
	key:setCallback(
		function (type,key, event) 
			return processor(event, paras) 
		end);
	return function (event) return key:handleEvent(event) end;
end

local function makeTouchProcessor(paras, processor)
	local flag = TouchObject.Click;
	if (paras.flag) then	
		flag = tonumber(paras.flag);
	end
	local touch = TouchObject.create(flag);
	touch:setCallback(
		function (type,touch, event) 
			if event.accepted then
				return false;
			else
				return processor(event, paras) 
			end
		end);
	return function (event) return touch:handleEvent(event) end;
end

local function makeGestureProcessor(paras, processor)
	local hotkey = paras.hotkey;
	local gesture;
	if (hotkey == "gesture_pinch") then
		NPL.load("(gl)script/Truck/Game/Input/TouchGesturePinch.lua");
    	local TouchGesturePinch = commonlib.gettable("Mod.Truck.Game.Input.TouchGesturePinch");
		gesture = TouchGesturePinch.create(tonumber(paras.flag));
	elseif (hotkey =="gesture_rotate") then
		NPL.load("(gl)script/Truck/Game/Input/TouchGestureRotate.lua");
    	local TouchGestureRotate = commonlib.gettable("Mod.Truck.Game.Input.TouchGestureRotate");
		gesture = TouchGestureRotate.create(tonumber(paras.flag));
	elseif hotkey == "gesture_move" then
		NPL.load("(gl)script/Truck/Game/Input/TouchGestureMove.lua");
    	local TouchGestureMove = commonlib.gettable("Mod.Truck.Game.Input.TouchGestureMove");
		gesture = TouchGestureMove.create(tonumber(paras.flag));
	end
	gesture:setCallback(
		function(type, args, event)
			return processor(event, paras);
		end)
	return function(event) return gesture:handleEvent(event) end, gesture;
end

local function makeProcessor(paras, processor)
	if (paras.dev == "true" and not CommonUtility:IsDevVersion()) then
		return function() return false end;
	elseif string.match(paras.hotkey,"^DIK_.+") then
		return makeKeyProcessor(paras,processor)
	elseif string.match(paras.hotkey,"touch") then
		return makeTouchProcessor(paras, processor)
	elseif string.match(paras.hotkey,"^gesture_.+") then
		return makeGestureProcessor(paras, processor)
	else
		return makeClickProcessor(paras,processor)
	end
end

local function getProcessorFunc(func)
	return function(paras)  return makeProcessor(paras, func) end
end

local timergroup = {};
local function retainAction(processor,group)
	group = group or "gesture";
	return function (paras)
		if string.match(paras.hotkey,"^gesture_.+") then
			local _, gesture = makeGestureProcessor(paras, processor)
			gesture:setCallback(
				function(type, args, event) 
					local ret = processor(event, paras); 
					if ret then
						if (timergroup[group]) then
							timergroup[group]:Change();
						end
						timergroup[group] = commonlib.Timer:new({callbackFunc = function()
							processor(event, paras);
						end})
						timergroup[group]:Change(30,30);
					end
					return ret; 
				end)
			return function(event) 
				if event.type == "WM_POINTERUP" and timergroup[group] then
					timergroup[group]:Change();
				end
				return gesture:handleEvent(event);
			end
		else
			return makeProcessor(paras, processor);
		end
	end
end

function convertTouchToMouseEvent(event)
	local type = event.type;
	if not type then
		return event;
	end

	local result = {
		GetType = function(self)
			return self.event_type;
		end,
		GetHandlerFuncName = function(self)
			return self.event_type;
		end,
		accept = function(self)
			self.accepted = true;
			return self.accepted;
		end,
		button = function(self)
			return self.mouse_button;
		end,
		mouse_button = "left",
		x = event.x;
		y = event.y;
	};
	if type == "WM_POINTERDOWN" then
		result.event_type = "mousePressEvent";
	elseif type =="WM_POINTERUP" then
		result.event_type = "mouseReleaseEvent";
	elseif type == "WM_POINTERUPDATE" then
		result.event_type = "mouseMoveEvent"
	else
		return event;
	end

	return result;
end

local functionTable = 
{
	destroyBlock = function(paras) 
		if (paras.force == "true" ) then
			if string.match(paras.hotkey,"touch") then
				local touch = TouchObject.create(TouchObject.TouchUp + TouchObject.TouchDown);
				local db = commonlib.copy(damageBlock);
				db.effect = false
				touch:setCallback(
					function (type, touch,event)
						if type == TouchObject.TouchDown then
							return db:onpress();
						elseif type == TouchObject.TouchUp then
							return db:onrelease(event, paras);
						end
					end)

				return function(event) return  touch:handleEvent(event) end
			else --mouse
				local button = ButtonObject.create(paras.hotkey, ButtonObject.ButtonUp + ButtonObject.DragMove + ButtonObject.ButtonDown);
				local db = commonlib.copy(damageBlock);
				db.effect = true;
				
				button:setCallback(
					function(type, button, event)
						if type == ButtonObject.ButtonDown then
							return db:onpress(event, paras);
						elseif type == ButtonObject.ButtonUp then
							return db:onrelease(event, paras);
						elseif type == ButtonObject.DragMove then
							return db:onmove();
						end
					end)
				return function (event) return button:handleEvent(event) end;
			end
		else
			return makeProcessor(paras, InputProcessor.destroyBlock) 
		end
	end,
	useItem = function (paras) -- accept all the mouse events
		return function (event)
			InputProcessor.useItem(event, paras);
			return event.accepted;
		end 
	end,
	touchCamera = function(paras)-- MUST BE Touch event
		NPL.load("(gl)script/Truck/Game/Input/TouchCameraController.lua");
    	local TouchCameraController = commonlib.gettable("Mod.Truck.Game.Input.TouchCameraController");
		return TouchCameraController.handleTouchEvent;
	end,
	flyUpward = retainAction(InputProcessor.flyUpward),
	flyDownward = retainAction(InputProcessor.flyDownward),
	handleEditBlockManipulator = function (paras)
	    NPL.load("(gl)script/Truck/Game/Editor/Editor.lua");
   	 	local Editor = commonlib.gettable("Mod.Truck.Game.Editor");
		return function (event) 
					if Editor.isTransforming() then
						return Editor.handleEvent(convertTouchToMouseEvent(event)) 
					else
						return false;
					end;
				end; 
	end,
	batchOperation = function (paras)


		if string.match(paras.hotkey,"touch") then
			local touch = TouchObject.create(TouchObject.TouchUp + TouchObject.TouchDown + TouchObject.TouchMove);
			touch:setCallback(
				function (type, touch,event)
					if event.accepted then
						return true
					end
					if type == TouchObject.TouchUp then
						event.accepted = Batch.onStop();
						return event.accepted
					elseif type == TouchObject.TouchMove or type == TouchObject.TouchDown then
						if not Batch.isEnabled() then
							return false;
						end
						local result = InputProcessor.mousePick();
						if result.blockX then
							event.accepted = Batch.onPick(result.blockX, result.blockY, result.blockZ, result.side)
						end
						return true;
					end
				end)

			return function(event) return  touch:handleEvent(event) end
		else --mouse
			local button = ButtonObject.create(paras.hotkey, ButtonObject.ButtonUp + ButtonObject.ButtonDown +  ButtonObject.DragMove);
			button:setCallback(
				function(type, button, event)
					if event.accepted then
						return true
					end
					if type == ButtonObject.ButtonUp then
						event.accepted = Batch.onStop();
						return event.accepted;
					elseif type == ButtonObject.DragMove or type ==  ButtonObject.ButtonDown then
						if not Batch.isEnabled() then
							return false;
						end
						local result = InputProcessor.mousePick();
						if result.blockX then
							event.accepted = Batch.onPick(result.blockX, result.blockY, result.blockZ,result.side);
							return event.accepted;
						else
							return false; 
						end
					end
				end)
			return function (event) return button:handleEvent(event) end;
		end

		return function (event)
			return Batch.execute();	
		end
	end
}

function Input:process( event)

	local meminfo = GamingRoomInfo.getPlayer(YcProfile.uid);
	local proc ;
	if self.needPermission and meminfo and meminfo.states then
		local states = meminfo.states;
		proc =
			function (p, e)
				if states:has(p[2]) == nil then
					return p[1](e);
				else
					return states:has(p[2]) and p[1](e); 
				end
			end;
	else
 		proc = function (p, e) return p[1](e) end;
	end
	for k,v in ipairs(self.processor) do
		if (proc(v, event)) then
			event.accepted = true;
			--return;
		end
	end
end

function Input:onEnter(paras)
	self.processor = {};
	local processor = self.processor;

    local Config = commonlib.gettable("Mod.Truck.Config");
	if (not paras or not paras.input) then
		return
	end
	local inputconfig = Config.InputConfig[paras.input]:get(1)
	if not inputconfig then
		return
	end

	for k,v in pairs(inputconfig:content()) do
		local name = v:name();
		if functionTable[name] then
			local func = functionTable[name](v);
			processor[#processor + 1] = {func, name};
		elseif InputProcessor[name] then
			local func = getProcessorFunc(InputProcessor[name])(v);
			processor[#processor + 1] = {func, name};
		end
	end

	self.needPermission = paras.needPermission;
	self.showWireFrame = inputconfig.showWireFrame ~= "false";

	self.updateTimer= commonlib.Timer:new({callbackFunc = function ()  self:update() end});
	self.updateTimer:Change(100,100);

end

function Input:update()
	if self.showWireFrame then
		InputProcessor.showWireFrame();
	end

end

function Input:onLeave()
	
	self.updateTimer:Change();
end

function Input:handleKeyEvent(event)
    local dik_key = event.keyname;
	local ctrlPressed = event.ctrl_pressed;


	if self:process( event) then
		return true;
	end
	return false;
end

function Input:handleMouseEvent(event)

	local event_type = event:GetType();
	local config = self.config;

	if self.showWireFrame then
		InputProcessor.showWireFrame();
	end


	--quickmotionbar	
	if (event_type == "mouseWheelEvent" ) then
		if (not event.ctrl_pressed) then
			--local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
			--GameLogic.GetPlayerController():OnClickHandToolIndex(GameLogic.GetPlayerController():GetHandToolIndex() - event.mouse_wheel);
		end
	end

	return self:process( event);
end

function Input:handleTouchEvent(event)
	local type = event.type;
	if self:process(event) then
		return true;
	end
	return false;
end
