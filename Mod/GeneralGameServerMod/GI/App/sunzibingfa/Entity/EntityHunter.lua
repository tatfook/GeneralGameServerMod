
local Entity = require("./Entity.lua");

local EntityHunter = inherit(Entity, module());

function EntityHunter:ctor()

end

function EntityHunter:Init(bx, by, bz)
    local opts = {
        bx = bx, by = by, bz = bz,
        name = "hunter",
        biped = true,
        assetfile = "character/CC/artwar/game/lieren.x",  
        isCanAutoAttack = true,
        types = {["hunter"] = ENTITY_TYPE.DEFAULT_TYPE, ["wolf"] = ENTITY_TYPE.ATTACK_TYPE, ["hunter_arrow"] = ENTITY_TYPE.NOT_COLLIDED_TYPE},
        visibleRadius = 10,
        defaultSkill = CreateSkill({
            skillRadius = 10,
            entity_config = {
                name = "hunter_arrow",
                assetfile = "character/CC/07items/arrow.x", 
                speed = 5, 
                hasBlood = false,
                checkTerrain = false,
                isCanVisible = false,
                destroyBeCollided = true,
                biped = true,
                goods = {
                    [1] = {
                        gsid = "hunter_arrow",
                        blood_peer = true,
                        blood_peer_value = -100, 
                    }
                },
                types = {["hunter_arrow"] = ENTITY_TYPE.DEFAULT_TYPE, ["hunter"] = ENTITY_TYPE.NOT_COLLIDE_TYPE, ["sunbin_not_collide_type"] = ENTITY_TYPE.NOT_COLLIDE_TYPE, ["sunbin_not_collided_type"] = ENTITY_TYPE.NOT_COLLIDED_TYPE},
            },
            moveToTargetEntity = true,
            skillDistance = 15,
            skillInterval = 400,
            skillTime = 0,
        }),
    }

    EntityHunter._super.Init(self, opts);

    return self;
end

function EntityHunter:SetDefaultSkillPeerBlood(blood)
    self:GetDefaultSkill().__entity_config__.goods[1].blood_peer_value = -blood;
end