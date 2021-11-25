
local Config = require("./Config.lua");
local Entity = inherit(require("Entity"), module());


function Entity:ctor()

end

function Entity:Init(opts)
    if (opts.isCanAutoAttack == nil) then opts.isCanAutoAttack = false end 
    if (opts.isCanAutoAvoid == nil) then opts.isCanAutoAvoid = false end 
    if (opts.visibleRadius == nil) then opts.visibleRadius = 1 end 

    Entity._super.Init(self, opts);

    return self;
end

function Entity:IsZombie()
    return false;
end

function Entity:IsPlant()
    return false;
end


local Zombie = inherit(Entity, {});

function Zombie:IsZombie()
    return true;
end

function Zombie:Init(opts)
    Zombie._super.Init(self, opts);

    local __self__ = self;
    local step = 20;
    async_run(function()
        local attacking = false;
        while(not Config.__gameover__ and step > 0 and not __self__:IsDestory()) do
            step = step - 1;
            if (not attacking) then 
                __self__:MoveForward(1);
            else
                sleep(100);
            end
            attacking = false;
            local blockindex = __self__:GetBlockIndex();
            local entities = self:GetAllEntityInBlockIndex(blockindex);
            for _, entity in ipairs(entities) do
                if (entity:IsPlant()) then
                    __self__:Attack(entity);
                    step = step + 1;
                    attacking = true;
                    break;
                end
            end
        end
        if (step == 0) then 
            Tip("游戏失败");
            Config.__gameover__ = true;
        end
    end);
    return self;
end

-- 青铜僵尸
local EntityBronzeZombie = inherit(Zombie, {});
function EntityBronzeZombie:ctor()
end
function EntityBronzeZombie:Init(bx, by, bz)
    local cfg = Config.zombie_config.CreateEntityBronzeZombie;

    local opts = {
        bx = bx, by = by, bz = bz,
        name = "BronzeZombie",
        biped = true,
        assetfile = "character/v5/10mobs/HaqiTown/UndeadMonkey/UndeadMonkey.x",  
        types = {["zombie"] = 0, ["plant"] = 1},
        speed = cfg.speed, 
        blood = cfg.blood,
        defaultSkill = CreateSkill({
            skillRadius = 1,
            targetBlood = cfg.attack_blood,
            skillInterval = cfg.attack_speed,
            skillTime = 200,
        }),
    };

    EntityBronzeZombie._super.Init(self, opts);

    return self;
end

function Entity.CreateEntityBronzeZombie(...)
    return EntityBronzeZombie:new():Init(...);
end

--白银僵尸
local EntitySilverZombie = inherit(Zombie, {});
function EntitySilverZombie:ctor()
end
function EntitySilverZombie:Init(bx, by, bz)
    local cfg = Config.zombie_config.CreateEntitySilverZombie;
    local opts = {
        bx = bx, by = by, bz = bz,
        name = "SilverZombie",
        biped = true,
        assetfile = "character/v5/10mobs/HaqiTown/UndeadMonkey_Boss/UndeadMonkey_Boss.x",  
        types = {["zombie"] = 0, ["plant"] = 1},
        speed = cfg.speed, 
        blood = cfg.blood, 
        defaultSkill = CreateSkill({
            skillRadius = 1,
            targetBlood = cfg.attack_blood,
            skillInterval = cfg.attack_speed,
            skillTime = 200,
        }),
    };

    EntitySilverZombie._super.Init(self, opts);

    return self;
end

function Entity.CreateEntitySilverZombie(...)
    return EntitySilverZombie:new():Init(...);
end

-- 黄金僵尸
local EntityGoldZombie = inherit(Zombie, {});
function EntityGoldZombie:ctor()
end
function EntityGoldZombie:Init(bx, by, bz)
    local cfg = Config.zombie_config.CreateEntityGoldZombie;
    local opts = {
        bx = bx, by = by, bz = bz,
        name = "GoldZombie",
        biped = true,
        assetfile = "character/v5/10mobs/HaqiTown/UndeadMonkey_Fuben/UndeadMonkey_Fuben.x",  
        types = {["zombie"] = 0, ["plant"] = 1},
        speed = cfg.speed, 
        blood = cfg.blood, 
        defaultSkill = CreateSkill({
            skillRadius = 1,
            targetBlood = cfg.attack_blood,
            skillInterval = cfg.attack_speed,
            skillTime = 200,
        }),
    };

    EntityGoldZombie._super.Init(self, opts);

    return self;
end

function Entity.CreateEntityGoldZombie(...)
    return EntityGoldZombie:new():Init(...);
end

-- 钻石僵尸
local EntityDiamondsZombie = inherit(Zombie, {});
function EntityDiamondsZombie:ctor()
end
function EntityDiamondsZombie:Init(bx, by, bz)
    local cfg = Config.zombie_config.CreateEntityDiamondsZombie;
    local opts = {
        bx = bx, by = by, bz = bz,
        name = "GoldZombie",
        biped = true,
        assetfile = "character/v5/10mobs/HaqiTown/FireBeatle_Boss/FireBeatle_Boss.x",  
        types = {["zombie"] = 0, ["plant"] = 1},
        speed = cfg.speed, 
        blood = cfg.blood,  
        defaultSkill = CreateSkill({
            skillRadius = 1,
            targetBlood = cfg.attack_blood,
            skillInterval = cfg.attack_speed,
            skillTime = 200,
        }),
    };

    EntityDiamondsZombie._super.Init(self, opts);

    return self;
end

function Entity.CreateEntityDiamondsZombie(...)
    return EntityDiamondsZombie:new():Init(...);
end

-- 极速僵尸
local EntitySpeedZombie = inherit(Zombie, {});
function EntitySpeedZombie:ctor()
end
function EntitySpeedZombie:Init(bx, by, bz)
    local cfg = Config.zombie_config.CreateEntitySpeedZombie;
    local opts = {
        bx = bx, by = by, bz = bz,
        name = "SpeedZombie",
        biped = true,
        assetfile = "character/v5/10mobs/HaqiTown/DeathSnake_Boss/DeathSnake_Boss.x",  
        types = {["zombie"] = 0, ["plant"] = 1},
        speed = cfg.speed, 
        blood = cfg.blood,  
        defaultSkill = CreateSkill({
            skillRadius = 1,
            targetBlood = cfg.attack_blood,
            skillInterval = cfg.attack_speed,
            skillTime = 200,
        }),
    };

    EntitySpeedZombie._super.Init(self, opts);

    return self;
end

function Entity.CreateEntitySpeedZombie(...)
    return EntitySpeedZombie:new():Init(...);
end

local Plant = inherit(Entity, {});

function Plant:IsPlant()
    return true;
end

function Plant:Init(opts)
    Plant._super.Init(self, opts);

    local __self__ = self;
    self:Turn(180);
    async_run(function()
        while(not __self__:IsDestory()) do
            local skill = __self__:GetSkill();
            skill:Activate(__self__);
            sleep(skill:GetNextActivateTimeStamp());
        end
    end);
    return self;
end

-- 基础守卫
local EntityBasicGuard = inherit(Plant, {});
function EntityBasicGuard:Init(bx, by, bz)
    local cfg = Config.guard_config.CreateEntityBasicGuard;
    local opts = {
        bx = bx, by = by, bz = bz,
        name = "BasicGuard",
        assetfile = "character/CC/02human/blockman/lan_gongbing.x",  
        types = {["plant"] = 0, ["zombie"] = 1},
        speed = 0, 
        blood = cfg.blood,
        defaultSkill = CreateSkill({
            skillRadius = 10,
            entity_config = {
                name = "arrow",
                assetfile = "character/CC/07items/arrow.x", 
                speed = 5, 
                hasBlood = false,
                checkTerrain = false,
                isCanVisible = false,
                destroyBeCollided = true,
                biped = true,
                goods = {
                    [1] = {
                        gsid = "arrow",
                        blood_peer = true,
                        blood_peer_value = -cfg.attack_blood, 
                    }
                },
                types = {["arrow"] = ENTITY_TYPE.DEFAULT_TYPE, ["plant"] = ENTITY_TYPE.NOT_COLLIDE_TYPE, ["zombie"] = ENTITY_TYPE.COLLIDE_TYPE},
            },
            moveToTargetEntity = true,
            skillDistance = 15,
            skillInterval = cfg.attack_speed,
            skillTime = 0,
        }),
    };

    EntityBasicGuard._super.Init(self, opts);

    return self;
end

function Entity.CreateEntityBasicGuard(...)
    return EntityBasicGuard:new():Init(...);
end

--  高级守卫
local EntitySeniorGuard = inherit(Plant, {});
function EntitySeniorGuard:Init(bx, by, bz)
    local cfg = Config.guard_config.CreateEntitySeniorGuard;
    local opts = {
        bx = bx, by = by, bz = bz,
        name = "SeniorGuard",
        assetfile = "character/CC/02human/blockman/hong_gongbing.x",  
        types = {["plant"] = 0, ["zombie"] = 1},
        speed = 0, 
        blood = cfg.blood,
        defaultSkill = CreateSkill({
            skillRadius = 10,
            entity_config = {
                name = "arrow",
                assetfile = "character/CC/07items/arrow.x", 
                speed = 5, 
                hasBlood = false,
                checkTerrain = false,
                isCanVisible = false,
                destroyBeCollided = true,
                biped = true,
                goods = {
                    [1] = {
                        gsid = "arrow",
                        blood_peer = true,
                        blood_peer_value = -cfg.attack_blood, 
                    }
                },
                types = {["arrow"] = ENTITY_TYPE.DEFAULT_TYPE, ["plant"] = ENTITY_TYPE.NOT_COLLIDE_TYPE, ["zombie"] = ENTITY_TYPE.COLLIDE_TYPE},
            },
            moveToTargetEntity = true,
            skillDistance = 15,
            skillInterval = cfg.attack_speed,
            skillTime = 0,
        }),
    };

    EntitySeniorGuard._super.Init(self, opts);

    return self;
end

function Entity.CreateEntitySeniorGuard(...)
    return EntitySeniorGuard:new():Init(...);
end

--  钢铁守卫
local EntityIronGuard = inherit(Plant, {});
function EntityIronGuard:Init(bx, by, bz)
    local cfg = Config.guard_config.CreateEntityIronGuard;
    local opts = {
        bx = bx, by = by, bz = bz,
        name = "IronGuard",
        assetfile = "character/v5/01human/QianXianHuWei/QianXianHuWei.x",  
        types = {["plant"] = 0, ["zombie"] = 1},
        speed = 0, 
        blood = cfg.blood,
        defaultSkill = CreateSkill({
            skillRadius = 1,
            targetBlood = cfg.attack_blood,
            skillInterval = cfg.attack_speed,
            skillTime = 200,
        }),
    };

    EntityIronGuard._super.Init(self, opts);

    return self;
end

function Entity.CreateEntityIronGuard(...)
    return EntityIronGuard:new():Init(...);
end

--  神圣守卫
local EntitySacredGuard = inherit(Plant, {});
function EntitySacredGuard:Init(bx, by, bz)
    local cfg = Config.guard_config.CreateEntitySacredGuard;
    local opts = {
        bx = bx, by = by, bz = bz,
        name = "SacredGuard",
        assetfile = "character/v3/GameNpc/SWZS/SWZS.x",  
        types = {["plant"] = 0, ["zombie"] = 1},
        speed = 0, 
        blood = cfg.blood,
        defaultSkill = CreateSkill({
            skillRadius = 1,
            targetBlood = cfg.attack_blood,
            skillInterval = cfg.attack_speed,
            skillTime = 200,
        }),
    };

    EntitySacredGuard._super.Init(self, opts);

    return self;
end

function Entity.CreateEntitySacredGuard(...)
    return EntitySacredGuard:new():Init(...);
end

--  磐石守卫
local EntityRockGuard = inherit(Plant, {});
function EntityRockGuard:Init(bx, by, bz)
    local cfg = Config.guard_config.CreateEntitySacredGuard;
    local opts = {
        bx = bx, by = by, bz = bz,
        name = "RockGuard",
        assetfile = "character/v3/GameNpc/FCSQ/FCSQ.x",  
        types = {["plant"] = 0, ["zombie"] = 1},
        speed = 0, 
        blood = cfg.blood,
        defaultSkill = CreateSkill({
            skillRadius = 1,
            targetBlood = cfg.attack_blood,
            skillInterval = cfg.attack_speed,
            skillTime = 200,
        }),
    };

    EntityRockGuard._super.Init(self, opts);

    return self;
end

function Entity.CreateEntityRockGuard(...)
    return EntityRockGuard:new():Init(...);
end


-- 基础守卫：filename="character/CC/02human/blockman/lan_gongbing.x"
-- 连射守卫：filename="character/CC/02human/blockman/hong_gongbing.x"
-- 钢铁守卫：filename="character/v5/01human/QianXianHuWei/QianXianHuWei.x"
-- 神圣守卫：filename="character/v3/GameNpc/SWZS/SWZS.x"
-- 磐石守卫：filename="character/v3/GameNpc/FCSQ/FCSQ.x"

-- 青铜僵尸：filename="character/v5/10mobs/HaqiTown/UndeadMonkey/UndeadMonkey.x"
-- 白银僵尸：filename="character/v5/10mobs/HaqiTown/UndeadMonkey_Boss/UndeadMonkey_Boss.x"
-- 黄金僵尸：filename="character/v5/10mobs/HaqiTown/UndeadMonkey_Fuben/UndeadMonkey_Fuben.x"
-- 钻石僵尸：filename="character/v5/10mobs/HaqiTown/FireBeatle_Boss/FireBeatle_Boss.x"
-- 极速僵尸：filename="character/v5/10mobs/HaqiTown/DeathSnake_Boss/DeathSnake_Boss.x"