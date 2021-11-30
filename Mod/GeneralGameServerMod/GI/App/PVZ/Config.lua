
local Config = module();

Config.IsGGSEnv = true;

Config.PathPrefix = Config.IsGGSEnv and "%gi%/App/PVZ/" or "@/pvz/";

-- 游戏结束标志
Config.__gameover__ = false;
Config.__failed__ = false;
-- 当前僵尸数量
Config.CurrentZombieCount = 0;
-- 当前植物数量
Config.CurrentPlantCount = 0;
-- 初始化太阳数
Config.InitSunCount = 100;

-- 僵尸批次数
Config.ZombieBatchCount = 4;

-- 每批次僵尸数
Config.ZombieCountPerBatch = 60;

-- 僵尸出现前的等待时间
Config.WaitTimeBeforeAppearZombie = 10;  -- 秒 

Config.guard_config = {
    ["CreateEntityBasicGuard"] = {
        -- 消耗的太阳数
        use_sun_count = 20,
        -- 血量
        blood = 10,
        -- 攻击伤害
        attack_blood = 6,
        -- 攻击频率
        attack_speed = 1000, -- 毫秒每次
    },
    ["CreateEntitySeniorGuard"] = {
        -- 消耗的太阳数
        use_sun_count = 40,
        -- 血量
        blood = 10,
        -- 攻击伤害
        attack_blood = 2,
        -- 攻击频率
        attack_speed = 200, -- 毫秒每次
    },
    ["CreateEntityIronGuard"] = {
        -- 消耗的太阳数
        use_sun_count = 80,
        -- 血量
        blood = 50,
        -- 攻击伤害
        attack_blood = 20,
        -- 攻击频率
        attack_speed = 500, -- 毫秒每次
    },
    ["CreateEntitySacredGuard"] = {
        -- 消耗的太阳数
        use_sun_count = 160,
        -- 血量
        blood = 100,
        -- 攻击伤害
        attack_blood = 40,
        -- 攻击频率
        attack_speed = 500, -- 毫秒每次
    },
    ["CreateEntityRockGuard"] = {
        -- 消耗的太阳数
        use_sun_count = 50,
        -- 血量
        blood = 100,
        -- 攻击伤害
        attack_blood = 0,
        -- 攻击频率
        attack_speed = 1000, -- 毫秒每次
    },
}

Config.zombie_config = {
    ["CreateEntityBronzeZombie"] = {
        -- 移动速度
        speed = 1,    -- 取1,2,3,4 默认为1
        -- 血量
        blood = 5,
        -- 攻击伤害
        attack_blood = 5,
        -- 攻击频率
        attack_speed = 1000, -- 毫秒每次
    },

    ["CreateEntitySilverZombie"] = {
        -- 移动速度
        speed = 2,    -- 取1,2,3,4 默认为1
        -- 血量
        blood = 12,
        -- 攻击伤害
        attack_blood = 5,
        -- 攻击频率
        attack_speed = 1000, -- 毫秒每次
    },

    ["CreateEntityGoldZombie"] = {
        -- 移动速度
        speed = 3,    -- 取1,2,3,4 默认为1
        -- 血量
        blood = 60,
        -- 攻击伤害
        attack_blood = 10,
        -- 攻击频率
        attack_speed = 1000, -- 毫秒每次
    },

    ["CreateEntityDiamondsZombie"] = {
        -- 移动速度
        speed = 3,    -- 取1,2,3,4 默认为1
        -- 血量
        blood = 100,
        -- 攻击伤害
        attack_blood = 10,
        -- 攻击频率
        attack_speed = 1000, -- 毫秒每次
    },

    ["CreateEntitySpeedZombie"] = {
        -- 移动速度
        speed = 5,                        -- 取1,2,3,4 默认为1
        -- 血量
        blood = 100,
        -- 攻击伤害
        attack_blood = 10,
        -- 攻击频率
        attack_speed = 500,               -- 毫秒每次
    },
}
