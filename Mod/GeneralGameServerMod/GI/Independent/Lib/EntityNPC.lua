--[[
Title: EntityNPC
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local EntityNPC = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/EntityNPC.lua");
------------------------------------------------------------
]]
local EntityNPC = inherit(__EntityNPC__, module("EntityNPC"));

function EntityNPC:Init(opts)
    EntityNPC._super.Init(self, opts);

    __AddEntity__(self);

    return self;
end

function EntityNPC:FrameMove()
end

function EntityNPC:FrameMoveRidding()
end

function EntityNPC:MoveForward(dist, duration)
    local facing = self:GetFacing();
    local distance = (dist or 1) * __BlockSize__;
    local dx, dy, dz = math.cos(facing) * distance, 0, -math.sin(facing) * distance;
    local x, y, z = self:GetPosition();
    local tickCountPerSecond = __get_loop_tick_count__();
    local stepCount = math.floor((duration or 1) * tickCountPerSecond);
    self:SetAnimId(5);
    while(stepCount > 0) do
        local stepX, stepY, stepZ = dx / stepCount, dy / stepCount, dz / stepCount;
        x, y, z = x + stepX, y + stepY, z + stepZ;
        self:SetPosition(x, y, z);
        stepCount = stepCount - 1;
        dx, dy, dz = dx - stepX, dy - stepY, dz - stepZ;
        sleep();
    end
    self:SetAnimId(0);
end

