--[[
Title: EntityNPC
Author(s):  wxa
Date: 2021-06-01
Desc: 定制 entity
use the lib:
------------------------------------------------------------
local EntityNPC = NPL.load("Mod/GeneralGameServerMod/GI/Game/Entity/EntityNPC.lua");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/mathlib.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityNPC.lua");

local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local EntityNPC = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovable"), NPL.export());

EntityNPC.framemove_interval = 0.02;

function EntityNPC:ctor()
    self.stepCount = 0;
end

function EntityNPC:Init(opts)
    opts = opts or {};

    if (opts.name) then self:SetName(opts.name) end 
    if (opts.opacity) then self:SetOpacity(opts.opacity) end
    if (opts.item_id and opts.item_id ~= 0) then self.item_id = item_id end 
    
    self:SetBlockPos(opts.bx or 0, opts.by or 0, opts.bz or 0);
    self:SetMainAssetPath(opts.assetfile or "character/CC/02human/actor/actor.x");

    self:CreateInnerObject(self:GetMainAssetPath(), true, 0, 1, self:GetSkin());
	self:RefreshClientModel();
    self:Attach();

	return self;
end

-- virtual function: overwrite to customize physical object
function EntityNPC:CreatePhysicsObject()
	local physic_obj = Entity._super.CreatePhysicsObject(self);
    physic_obj:SetRadius(BlockEngine.half_blocksize);
    physic_obj:SetCanBounce(false);
    physic_obj:SetSurfaceDecay(3);
    physic_obj:SetAirDecay(0);
    physic_obj:SetMinSpeed(0.1);
    return physic_obj;
end

function EntityNPC:SetAnimId(animId)
    self:GetInnerObject():SetField("AnimID", animId or 0);
end

function EntityNPC:Turn(degree)
    self:SetFacingDelta(degree * math.pi / 180);
end

function EntityNPC:TurnTo(degree)
    self:SetFacing(mathlib.ToStandardAngle(degree * math.pi / 180));
end

function EntityNPC:MoveForward(dist, duration)
    local facing = self:GetFacing();
    local distance = (dist or 1) * BlockEngine.blocksize;
    local dx, dy, dz = math.cos(facing) * distance, 0, -math.sin(facing) * distance;
    local x, y, z = self:GetPosition();
    self.targetX, self.targetY, self.targetZ = x + dx, y + dy, z + dz;
    self.stepCount = self:GetTickCount(duration);
    self.stepX, self.stepY, self.stepZ = dx / self.stepCount, dy / self.stepCount, dz / self.stepCount;
end

function EntityNPC:GetTickCount(duration)
    return (duration or 1) / self.framemove_interval;
end

function EntityNPC:FrameMove(deltaTime)
    if (self.stepCount > 0) then
        self.stepCount = self.stepCount - 1;
        if (self.stepCount == 0) then
            self:SetPosition(self.targetX, self.targetY, self.targetZ);
        else
            local x, y, z = self:GetPosition();
            self:SetPosition(x + self.stepX, y + self.stepY, z + self.stepZ);
        end
    end
end