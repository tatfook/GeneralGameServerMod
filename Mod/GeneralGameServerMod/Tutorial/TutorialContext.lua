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
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local TutorialContext = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditContext"), NPL.export());

TutorialContext:Property({"Name", "TutorialContext"});
TutorialContext:Property("Tutorial");


function TutorialContext:Init(tutorial)
	self:SetTutorial(tutorial);
	return self;
end

function TutorialContext:handleLeftClickScene(event, result)
	local result = result or self:CheckMousePick()
	local shift_pressed = event.shift_pressed;
	local ctrl_pressed = event.ctrl_pressed;
	local alt_pressed = event.alt_pressed;

	-- 删除逻辑
	if(not shift_pressed and not alt_pressed and not ctrl_pressed and result and result.blockX) then
		local data = {blockX = result.blockX, blockY = result.blockY, blockZ = result.blockZ, blockId = result.block_id};
		if (not self:GetTutorial():IsCanLeftClickToDestroyBlock(data)) then return end
	end

	return TutorialContext._super.handleLeftClickScene(self, event, result);
end

function TutorialContext:handleRightClickScene(event, result)
	result = result or SelectionManager:GetPickingResult();
	if(self.click_data.right_holding_time < 400 and result and result.blockX) then
		local data = {blockX = result.blockX, blockY = result.blockY, blockZ = result.blockZ, blockId = result.block_id};
		if(not self:GetTutorial():IsCanRightClickToCreateBlock(data)) then return end
	end
end