--[[
Title: BlockFBX
Author(s):  wxa
Date: 2021-06-01
Desc: FBX 方块
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/GI/Game/Blocks/BlockTrampoline.lua");
local BlockTrampoline = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockTrampoline");
------------------------------------------------------------
]]

local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockTrampoline"));
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

block_types.RegisterBlockClass("BlockTrampoline", block);

function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	if self:IsFunctional(x,y,z) then
		BlockEngine:SetBlockData(x, y, z,  16, 3);
	else
		BlockEngine:SetBlockData(x, y, z,  0, 3);
	end
end

function block:OnStep(x,y,z, entity)
    if not entity:IsRemote() and self:IsFunctional(x,y,z) then
        entity.motionY = self.power;
    end
end

-- if the block under the teleport stone is a light block or indirectly powered, we will return true
function block:IsFunctional(x, y, z)
    local block_template = BlockEngine:GetBlock(x, y-1, z)
	if(block_template and block_template.light) then
		return true;
	else
		return BlockEngine:isBlockIndirectlyGettingPowered(x, y, z);
	end
end

function block:OnBlockAdded(x, y, z)
	if(not GameLogic.isRemote) then
		self:UpdateMe(x, y, z);
	end
end

function block:OnNeighborChanged(x,y,z,neighbor_block_id)
	if(not GameLogic.isRemote) then
		self:UpdateMe(x, y, z);
	end
end

function block:UpdateMe(x, y, z)
	local is_powered = self:IsFunctional(x, y, z)

    if ( (self.power and not is_powered) or (not self.power and is_powered)) then
		self:OnToggle(x, y, z);
    end
end

-- Ticks the block if it's been scheduled
function block:updateTick(x,y,z)
	if(not GameLogic.isRemote) then
		self:UpdateMe(x, y, z);
	end
end