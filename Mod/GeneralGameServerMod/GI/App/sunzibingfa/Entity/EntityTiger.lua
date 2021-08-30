
local Entity = require("./Entity.lua");

local EntityTiger = inherit(Entity, module());

function EntityTiger:ctor()

end

function EntityTiger:Init(bx, by, bz)
    local opts = {
        bx = bx, by = by, bz = bz,
        name = "wolf",
        biped = true,
        assetfile = "character/CC/codewar/laohu.x",  
        isCanAutoAttack = true,
        isCanAutoAvoid = true,
        types = {["wolf"] = 0, ["human"] = 1, ["light"] = 2},
        visibleRadius = 5,
        speed = 2, 
        defaultSkill = CreateSkill({
            skillRadius = 1,
            targetBlood = 100,
            skillInterval = 500,
            skillTime = 200,
        }),
    };

    EntityTiger._super.Init(self, opts);

    return self;
end

function EntityTiger:SetDefaultSkillPeerBlood(blood)
    self:GetDefaultSkill():SetTargetBlood(blood);
end

function EntityTiger:SetDefaultSkillRadius(radius)
    self:GetDefaultSkill():SetSkillRadius(radius);
end
