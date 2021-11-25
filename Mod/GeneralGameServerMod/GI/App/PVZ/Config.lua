
local Config = module();


-- 游戏结束标志
Config.__gameover__ = false;

-- 初始化太阳数
Config.InitSunCount = 100;

-- 僵尸批次数
Config.ZombieBatchCount = 4;

-- 每批次僵尸数
Config.ZombieCountPerBatch = 20;

-- 僵尸出现前的等待时间
Config.WaitTimeBeforeAppearZombie = 10;  -- 秒 

Config.guard_config = {
    ["CreateEntityBasicGuard"] = {
        -- 消耗的太阳数
        use_sun_count = 50,
        -- 血量
        blood = 100,
        -- 攻击伤害
        attack_blood = 5,
        -- 攻击频率
        attack_speed = 1000, -- 毫秒每次
    },
    ["CreateEntitySeniorGuard"] = {
        -- 消耗的太阳数
        use_sun_count = 100,
        -- 血量
        blood = 100,
        -- 攻击伤害
        attack_blood = 5,
        -- 攻击频率
        attack_speed = 1000, -- 毫秒每次
    },
    ["CreateEntityIronGuard"] = {
        -- 消耗的太阳数
        use_sun_count = 200,
        -- 血量
        blood = 100,
        -- 攻击伤害
        attack_blood = 5,
        -- 攻击频率
        attack_speed = 1000, -- 毫秒每次
    },
    ["CreateEntitySacredGuard"] = {
        -- 消耗的太阳数
        use_sun_count = 300,
        -- 血量
        blood = 100,
        -- 攻击伤害
        attack_blood = 20,
        -- 攻击频率
        attack_speed = 1000, -- 毫秒每次
    },
    ["CreateEntityRockGuard"] = {
        -- 消耗的太阳数
        use_sun_count = 400,
        -- 血量
        blood = 500,
        -- 攻击伤害
        attack_blood = 5,
        -- 攻击频率
        attack_speed = 1000, -- 毫秒每次
    },
}

Config.zombie_config = {
    ["CreateEntityBronzeZombie"] = {
        -- 移动速度
        speed = 1,    -- 取1,2,3,4 默认为1
        -- 血量
        blood = 100,
        -- 攻击伤害
        attack_blood = 1,
        -- 攻击频率
        attack_speed = 500, -- 毫秒每次
    },

    ["CreateEntitySilverZombie"] = {
        -- 移动速度
        speed = 1,    -- 取1,2,3,4 默认为1
        -- 血量
        blood = 100,
        -- 攻击伤害
        attack_blood = 1,
        -- 攻击频率
        attack_speed = 500, -- 毫秒每次
    },

    ["CreateEntityGoldZombie"] = {
        -- 移动速度
        speed = 1,    -- 取1,2,3,4 默认为1
        -- 血量
        blood = 100,
        -- 攻击伤害
        attack_blood = 80,
        -- 攻击频率
        attack_speed = 500, -- 毫秒每次
    },

    ["CreateEntityDiamondsZombie"] = {
        -- 移动速度
        speed = 1,    -- 取1,2,3,4 默认为1
        -- 血量
        blood = 200,
        -- 攻击伤害
        attack_blood = 100,
        -- 攻击频率
        attack_speed = 500, -- 毫秒每次
    },

    ["CreateEntitySpeedZombie"] = {
        -- 移动速度
        speed = 1,                        -- 取1,2,3,4 默认为1
        -- 血量
        blood = 200,
        -- 攻击伤害
        attack_blood = 50,
        -- 攻击频率
        attack_speed = 500,               -- 毫秒每次
    },
}
