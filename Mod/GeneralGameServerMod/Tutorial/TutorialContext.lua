--[[
Title: Tutorial Context
Author(s): wxa
Date: 2015/12/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/TutorialContext.lua");
local TutorialContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.TutorialContext");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/EditContext.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameMode.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local TutorialContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditContext"), NPL.export());

TutorialContext:Property({"Name", "TutorialContext"});
TutorialContext:Property("TutorialSandbox");
TutorialContext:Property("ModeCanDestroyBlock", true);
TutorialContext:Property("ModeCanRightClickToCreateBlock", true);
TutorialContext:Property("ModeHasJumpRestriction", true);
TutorialContext:Property("CanFly", false, "IsCanFly");
TutorialContext:Property("CanJump", false, "IsCanJump");
TutorialContext:Property("CanClickScene", true, "IsCanClickScene");


local shift_pressed, ctrl_pressed, alt_pressed = nil;

local function GetMouseKeyState(event)
	return event.mouse_button == "left" and 1 or (event.mouse_button == "right" and 2 or 0);
end

function TutorialContext:Init(tutorialSandbox)
	self:SetTutorialSandbox(tutorialSandbox);
	return self;
end

function TutorialContext:handleCodeGlobalKeyPressEvent(event)
	if(GameLogic.GetCodeGlobal():BroadcastKeyPressedEvent(event.keyname)) then
		event:accept();
		return true;
	end
end 

function TutorialContext:HandleGlobalKey(event)
	-- 禁用全局按键行为
	TutorialContext._super.HandleGlobalKey(self, event);
end

function TutorialContext:handlePlayerKeyEvent(event)
	TutorialContext._super.handlePlayerKeyEvent(self, event);
end

function TutorialContext:keyPressEvent(event)
	if (self:GetTutorialSandbox():OnKeyPressEvent(event)) then return end

	local dik_key, ctrl_pressed, shift_pressed, alt_pressed = event.keyname, event.ctrl_pressed, event.shift_pressed, event.alt_pressed;
	if(not ctrl_pressed and not alt_pressed and not shift_pressed) then
		if(dik_key == "DIK_SPACE") then
			if (self:IsCanJump()) then GameLogic.DoJump() end
			return self:handleCodeGlobalKeyPressEvent(event);
		elseif(dik_key == "DIK_F") then
			if(self:IsCanFly()) then GameLogic.ToggleFly() end
			return self:handleCodeGlobalKeyPressEvent(event);
		end
	end

	if(dik_key == "DIK_S" and ctrl_pressed) then
		GameLogic.RunCommand("/save");
		return self:handleCodeGlobalKeyPressEvent(event);
	end

	TutorialContext._super.keyPressEvent(self, event);
end

-- 创建方块
function TutorialContext:OnCreateSingleBlock(blockX, blockY, blockZ, blockId, result)
	local data = {blockX = blockX, blockY = blockY, blockZ = blockZ, blockId = blockId, mouseKeyState = 2, mouseButton = "right", shift_pressed = shift_pressed, ctrl_pressed = ctrl_pressed, alt_pressed = alt_pressed};
	if(self:GetTutorialSandbox():IsCanClick(data)) then return TutorialContext._super.OnCreateSingleBlock(self, blockX, blockY, blockZ, blockId, result) end
end

-- 鼠标事件
function TutorialContext:handleMouseEvent(event)
	-- 忽略移动鼠标事件
	if (event:GetType() == "mouseMoveEvent") then return TutorialContext._super.handleMouseEvent(self, event) end

	-- 是否可点击
	if (not self:IsCanClickScene()) then return end

	-- 更新事件值
	event:updateModifiers();
	
	-- 保存按键
	shift_pressed, ctrl_pressed, alt_pressed = event.shift_pressed, event.ctrl_pressed, event.alt_pressed;
	
	-- 获取鼠标方块
	local result = SelectionManager:MousePickBlock();

	-- 无方块选中直接默认处理
	if (not result) then return TutorialContext._super.handleMouseEvent(self, event) end

	-- 检测使能
	-- 无功能键按下右击
	if (event.mouse_button == "right" and not (shift_pressed or ctrl_pressed or alt_pressed)) then
		-- 待创建的方块信息
		-- local blockX, blockY, blockZ = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
		-- local itemStack = EntityManager.GetPlayer():GetItemInRightHand();
		-- local blockId = itemStack and itemStack.id or 0;
		-- local data = {blockX = blockX, blockY = blockY, blockZ = blockZ, blockId = blockId, mouseKeyState = event:buttons(), mouseButton = event.mouse_button, shift_pressed = shift_pressed, ctrl_pressed = ctrl_pressed, alt_pressed = alt_pressed};
		-- if(not self:GetTutorialSandbox():IsCanClick(data) and blockId > 0) then return event:accept() end
	else
		-- 左击 或者 功能键按下
		local data = {blockX = result.blockX, blockY = result.blockY, blockZ = result.blockZ, blockId = result.block_id, mouseKeyState = GetMouseKeyState(event), mouseButton = event.mouse_button, shift_pressed = shift_pressed, ctrl_pressed = ctrl_pressed, alt_pressed = alt_pressed};
		if(not self:GetTutorialSandbox():IsCanClick(data)) then 
			return event:accept();
		end
	end
	-- 默认处理
	return TutorialContext._super.handleMouseEvent(self, event);
end