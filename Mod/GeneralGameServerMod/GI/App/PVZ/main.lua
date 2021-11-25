


local Config = require("./Config.lua");
local Entity = require("./Entity.lua");

local __ui_G__ = {
    sun_count = Config.InitSunCount,
    select_guard_type = "CreateEntityBasicGuard",
};

local __ui__ = ShowWindow(__ui_G__, {
    width = 300,
    height = 300,
    url = "@/pvz/pvz.html",
    alignment = "_lt",
});


Entity.CreateEntityBasicGuard(19207,12,19217);
Entity.CreateEntitySeniorGuard(19207,12,19215);
Entity.CreateEntityIronGuard(19207,12,19213);
Entity.CreateEntitySacredGuard(19207,12,19211);
Entity.CreateEntityRockGuard(19207,12,19209);

-- Entity.CreateEntityBronzeZombie(19189,12,19217);
-- Entity.CreateEntitySilverZombie(19189,12,19215);
-- Entity.CreateEntityGoldZombie(19189,12,19213);
-- Entity.CreateEntityDiamondsZombie(19189,12,19211);
-- Entity.CreateEntitySpeedZombie(19189,12,19209);

-- plant:ShowHeadOnDisplay();
-- zombie:ShowHeadOnDisplay();
cmd("/mode game");
cmd("/clearbag");
cmd("/hide quickselectbar");

RegisterEventCallBack(EventType.MOUSE_DOWN, function(e)
    if (e.mouse_button ~= "right") then return end 
    local result = MousePick();
    if (not result or result.block_id ~= 12) then return end 
    local bx, by, bz = result.blockX, result.blockY, result.blockZ;
    local bi = ConvertToBlockIndex(bx, by, bz);
    local entities = Entity:GetAllEntityInBlockIndex(bi);
    if (#entities > 0) then return Tip("当前位置已被占用, 无法创建") end
    local cfg = Config.guard_config[__ui_G__.select_guard_type];
    if (__ui_G__.sun_count < cfg.use_sun_count) then return Tip("太阳数量不足, 无法创建") end
    (Entity[__ui_G__.select_guard_type])(bx, by + 1, bz);
    __ui_G__.sun_count = __ui_G__.sun_count - cfg.use_sun_count;
end);


SetCamera(30, 75, 90);
SetCameraLookAtBlockPos(19201,11,19214);

Tip("开始游戏");
sleep(3000);

-- 产生僵尸
async_run(function()
    local pos_list = {
        { 19189,12,19217 },
        { 19189,12,19215 },
        { 19189,12,19213 },
        { 19189,12,19211 },
        { 19189,12,19209 },
    }

    local zombie_list = {
        "CreateEntityBronzeZombie",
        "CreateEntitySilverZombie",
        "CreateEntityGoldZombie",
        "CreateEntityDiamondsZombie",
        "CreateEntitySpeedZombie",
    }
    math.randomseed(__get_timestamp__());
    
    local zombie_count = Config.ZombieCountPerBatch;
    local zombie_size = math.max((#zombie_list) - Config.ZombieBatchCount, 1);
    for i = 1, Config.ZombieBatchCount do 
        Tip(string.format("第 %s 批僵尸将在 %s 秒内抵达战场", i, Config.WaitTimeBeforeAppearZombie));
        sleep(Config.WaitTimeBeforeAppearZombie * 1000);
        while (not Config.__gameover__ and zombie_count > 0) do
            local pos = pos_list[math.random(#pos_list)];
            local zombie = zombie_list[math.random(math.min(#zombie_list, zombie_size + i))];
            sleep(math.random(300, 3000));
            (Entity[zombie])(pos[1], pos[2], pos[3]);
            zombie_count = zombie_count - 1;
        end
        if (Config.__gameover__) then break end 
    end
end);


-- 太阳定时器
async_run(function()
    while(not Config.__gameover__) do
        __ui_G__.sun_count = __ui_G__.sun_count + 10;
        sleep(500);
        __ui__:GetG().RefreshWindow();
    end
    Tip("游戏结束");
end)


function clear()
    Config.__gameover__ = true;
end


-- 103409