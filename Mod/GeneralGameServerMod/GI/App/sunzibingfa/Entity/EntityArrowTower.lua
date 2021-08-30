local Entity = require("./Entity.lua");

local EntityArrowTower = inherit(Entity, module());

EntityArrowTower:Property("AttackInterval", 500);

function EntityArrowTower:ctor()
end

function EntityArrowTower:Init(bx, by, bz)
    self.__towerbase__ = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "__arrow_tower_base__",
        assetfile = "@/blocktemplates/jiguannu_dipan.x",  
        hasBlood = false,
        isCanBeCollided = false,
    });
    local tower_opts = {
        bx = bx, by = by, bz = bz,
        name = "__arrow_tower__",
        hasBlood = false,
        isCanBeCollided = false,
        assetfile = "@/blocktemplates/jiguannu.x",  
        defaultSkill = CreateSkill({
            entity_config = {
                name = "__arrow_tower_arrow__",
                assetfile = "character/CC/07items/arrow.x", 
                speed = 5, 
                hasBlood = false,
                checkTerrain = false,
                isCanVisible = false,
                destroyBeCollided = true,
                biped = true,
                goods = {
                    [1] = {
                        gsid = "__arrow_tower_arrow__",
                        blood_peer = true,
                        blood_peer_value = -20, 
                    }
                },
                types = {["sunbin"] = ENTITY_TYPE.COLLIDE_TYPE},
            },
            skillDistance = 10,
            skillTime = 0,
            offsetY = 1,
            skillInterval = 0,
        })
    };

    EntityArrowTower._super.Init(self, tower_opts);

    return self;
end

function EntityArrowTower:Destroy()
    self.__towerbase__:Destroy();
    EntityArrowTower._super.Destroy(self);
end
