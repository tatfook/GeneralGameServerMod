
local Entity = require("./Entity.lua");

local EntitySunBin = inherit(Entity, module());

function EntitySunBin:ctor()

end

function EntitySunBin:Init(bx, by, bz)
    local opts = {
        bx = bx, by = by, bz = bz,
        name = "sunbin",
        biped = true,
        assetfile = "character/CC/artwar/game/sunbin.x",
        physicsHeight = 1.765,
        types = {["human"] = ENTITY_TYPE.DEFAULT_TYPE, ["sunbin"] = ENTITY_TYPE.DEFAULT_TYPE, ["sunbin_not_collide_type"] = ENTITY_TYPE.DEFAULT_TYPE, ["sunbin_not_collided_type"] = ENTITY_TYPE.DEFAULT_TYPE},
        
        defaultSkill = CreateSkill({
            skillRadius = 1,
            targetBlood = 50,
            skillInterval = 300,
            skillTime = 200,
        }),
    };

    EntitySunBin._super.Init(self, opts);

    return self;
end

