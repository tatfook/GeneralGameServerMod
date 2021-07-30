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
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local Entity = NPL.load("./Entity.lua", IsDevEnv);
local EntityNPC = commonlib.inherit(Entity, NPL.export());

function EntityNPC:ctor()
    self.stepCount = 0;
end

function EntityNPC:Init(opts)
    opts = opts or {};

    EntityNPC._super.Init(self, opts);
	
    local physic_obj = self:GetPhysicsObject();
    physic_obj:SetRadius(BlockEngine.half_blocksize);
    physic_obj:SetCanBounce(false);
    physic_obj:SetSurfaceDecay(3);
    physic_obj:SetAirDecay(0);
    physic_obj:SetMinSpeed(0.1);

    return self;
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

function EntityNPC:FrameMoveRidding()
end

function EntityNPC:FrameMove()
    if (self.stepCount > 0) then
        self.stepCount = self.stepCount - 1;
        if (self.stepCount == 0) then
            self:SetPosition(self.targetX, self.targetY, self.targetZ);
            self:SetAnimId(0);
        else
            self:SetAnimId(5);
            local x, y, z = self:GetPosition();
            self:SetPosition(x + self.stepX, y + self.stepY, z + self.stepZ);
        end
    end
end