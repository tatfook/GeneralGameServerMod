
local Entity = require("./Entity.lua");

local EntityWolf = inherit(Entity, module());

function EntityWolf:ctor()

end

function EntityWolf:Init(bx, by, bz)
    local opts = {
        bx = bx, by = by, bz = bz,
        name = "wolf",
        biped = true,
        assetfile = "character/CC/codewar/lang.x",  
        isCanAutoAttack = true,
        isCanAutoAvoid = true,
        types = {["wolf"] = 0, ["human"] = 1, ["light"] = 2},
        visibleRadius = 5,
        speed = 2, 
        defaultSkill = CreateSkill({
            skillRadius = 1,
            targetBlood = 50,
            skillInterval = 500,
            skillTime = 200,
        }),
    };

    EntityWolf._super.Init(self, opts);

    return self;
end

function EntityWolf:SetDefaultSkillPeerBlood(blood)
    self:GetDefaultSkill():SetTargetBlood(blood);
end

function EntityWolf:SetDefaultSkillRadius(radius)
    self:GetDefaultSkill():SetSkillRadius(radius);
end
