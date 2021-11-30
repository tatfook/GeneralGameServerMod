


local Config = require("./Config.lua");
local Entity = require("./Entity.lua");

local __ui_G__ = {
	Config = Config,
    sun_count = Config.InitSunCount,
    select_guard_type = "CreateEntityBasicGuard",
};

local __ui__ = ShowWindow(__ui_G__, {
    x = 10,
    y = 200,
    width = 400,
    height = 400,
    url = Config.PathPrefix .. "pvz.html",
    alignment = "_lt",
});

local __tip_ui_G__ = {title = "开始游戏", subtitle = 3};
local __tip_ui__ = ShowWindow(__tip_ui_G__, {width = 400, height = 400, url = Config.PathPrefix .. "tip.html"});

--Entity.CreateEntityBasicGuard(19207,12,19217);
--Entity.CreateEntitySeniorGuard(19207,12,19215);
--Entity.CreateEntityIronGuard(19207,12,19213);
--Entity.CreateEntitySacredGuard(19207,12,19211);
--Entity.CreateEntityRockGuard(19207,12,19209);

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
--设置玩家位置
GetPlayer():SetBlockPos(19212,12,19225);

RegisterEventCallBack(EventType.MOUSE_DOWN, function(e)
    local result = MousePick();
    if (not result) then return end 
    local bx, by, bz, blockId, entity = result.blockX, result.blockY, result.blockZ, result.block_id, result.entity;
    if (e.mouse_button == "right" and blockId == 12) then
        local bi = ConvertToBlockIndex(bx, by, bz);
        local entities = Entity:GetAllEntityInBlockIndex(bi);
        if (#entities > 0) then return Tip("当前位置已被占用, 无法创建") end
        local cfg = Config.guard_config[__ui_G__.select_guard_type];
        if (__ui_G__.sun_count < cfg.use_sun_count) then return Tip("太阳数量不足, 无法创建") end
        (Entity[__ui_G__.select_guard_type])(bx, by + 1, bz);
        __ui_G__.sun_count = __ui_G__.sun_count - cfg.use_sun_count;
    end 

    if (e.mouse_button == "left" and entity and type(entity.IsPlant) == "function" and entity:IsPlant()) then
        entity:Destroy();
    end
end);


SetCamera(30, 75, 90);
SetCameraLookAtBlockPos(19201,11,19214);

Tip("开始游戏");
sleep(1000);
__tip_ui_G__.subtitle = __tip_ui_G__.subtitle - 1;
__tip_ui_G__.RefreshWindow();
sleep(1000);
__tip_ui_G__.subtitle = __tip_ui_G__.subtitle - 1;
__tip_ui_G__.RefreshWindow();
sleep(1000);
__tip_ui__:CloseWindow();
Config.__failed__  = false;

-- 产生僵尸
async_run(function()
    local pos_list = {
        { 19187,12,19220 },
        { 19187,12,19216 },
        { 19187,12,19212 },
        { 19187,12,19208 },
        { 19187,12,19204 },
    }

    local zombie_list = {
        "CreateEntityBronzeZombie",
        "CreateEntitySilverZombie",
        "CreateEntityGoldZombie",
        "CreateEntityDiamondsZombie",
        "CreateEntitySpeedZombie",
    }
    math.randomseed(__get_timestamp__());
    
    local zombie_size = math.max((#zombie_list) - Config.ZombieBatchCount, 1);
    for i = 1, Config.ZombieBatchCount do
        local zombie_count = Config.ZombieCountPerBatch; 
        local text = string.format("第 %s 批僵尸将在 %s 秒内抵达战场", i, Config.WaitTimeBeforeAppearZombie);
        Tip(text);
        
        __tip_ui_G__.title = text;
        __tip_ui_G__.subtitle = Config.WaitTimeBeforeAppearZombie;
        __tip_ui__ = ShowWindow(__tip_ui_G__, {width = 800, height = 400, url = Config.PathPrefix .. "tip.html"});
        for j = Config.WaitTimeBeforeAppearZombie, i, -1 do
            sleep(1000);
            __tip_ui_G__.subtitle = __tip_ui_G__.subtitle - 1;
            __tip_ui_G__.RefreshWindow();
        end
        __tip_ui__:CloseWindow();

        while (not Config.__gameover__ and zombie_count > 0) do
            local pos = pos_list[math.random(#pos_list)];
            local zombie = zombie_list[math.random(math.min(#zombie_list, zombie_size + i))];
            sleep(math.random(499, 500));
            (Entity[zombie])(pos[1], pos[2], pos[3]);
            zombie_count = zombie_count - 1;
        end
        if (Config.__gameover__) then break end 
    end

    while(not Config.__gameover__) do
        if (Config.CurrentZombieCount == 0) then
            Config.__gameover__ = true;
        end
        sleep(500);
    end

    if (Config.__failed__) then 
        __tip_ui_G__.title = "挑战失败";
    else
        __tip_ui_G__.title = "挑战成功";
    end
    Tip(__tip_ui_G__.title);
    __tip_ui_G__.subtitle = 3;
    __tip_ui__ = ShowWindow(__tip_ui_G__, {width = 800, height = 400, url = Config.PathPrefix .. "tip.html"});
    sleep(1000);
    __tip_ui_G__.subtitle = __tip_ui_G__.subtitle - 1;
    __tip_ui_G__.RefreshWindow();
    sleep(1000);
    __tip_ui_G__.subtitle = __tip_ui_G__.subtitle - 1;
    __tip_ui_G__.RefreshWindow();
    sleep(1000);
    __tip_ui__:CloseWindow();
end);


-- 太阳定时器
async_run(function()
    while(not Config.__gameover__) do
        __ui_G__.sun_count = __ui_G__.sun_count + 10;
        sleep(500);
        __ui__:GetG().RefreshWindow();
    end
end)


function clear()
    Config.__gameover__ = true;
end


-- 103409