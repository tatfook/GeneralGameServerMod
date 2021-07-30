
-- local levels = {
--     --levels of chapter1
--     {
--         {
--             name="鬼谷学堂", x=334, y=111, status = config.Open, 
--             pos = getCodePos(),
--             desc = "鬼谷仙山中，孙膑和庞涓是鬼谷子门下的两位高徒，讲学堂是鬼谷子师父平日里授课的地方，也是孙膑庞涓等师兄弟平日里讨论学习的主要场所，课余时间这里也会有一些欢乐的小比赛…",
--             keypoints = "【参数】【基本语法】",
--             mapRegion = {min={19419,7,19220}, size={50, 50}},
--             sceneFile = "blocktemplates/level1.blocks.xml",
--             bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
--             sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
--             chapter=1,
--             index=1,
--         },
--     }
-- }
-- local npc = CreateEntity({
--     bx = 19191,
--     by = 5,
--     bz = 19199,
--     assetfile = "character/CC/artwar/game/sunbin.x"
-- });
-- local level = {
--     minX = 
-- }
local EntityNPC = require("EntityNPC");

-- local npc = EntityNPC:new():Init({
--     bx = 19191,
--     by = 5,
--     bz = 19199,
--     assetfile = "character/CC/artwar/game/sunbin.x"
-- });

-- npc:Say("hello world", 1);
-- npc:Turn(180);
-- npc:MoveForward(10, 3);

-- -- ShowWindow(nil, {
-- --     url = "%vue%/Example/3D.html",
-- --     __is_3d_ui__ = true,  
-- --     __3d_object__ = obj,
-- --     G = {},
-- --     x = 0,
-- --     y = -300,
-- --     width = 100,
-- --     height = 100,
-- -- });



local minX, minY, minZ = 20000, 8, 20000;
local maxX, maxY, maxZ = 20128, 30, 20128;
local function LoadRegion()
    cmd("/property UseAsyncLoadWorld false")
    cmd("/property AsyncChunkMode false");
    cmd(format("/loadregion %d %d %d 256",  math.floor((maxX + minX) / 2), minY, math.floor((maxZ + minZ) / 2)));
    cmd("/property AsyncChunkMode true");
    cmd("/property UseAsyncLoadWorld true");

    -- 底座
    for x = minX, maxX do
        for z = minZ, maxZ do
            SetBlock(x, minY, z, 62);
        end
    end
    
    -- cmd(format("/goto %s %s %s", centerX, centerY, centerZ));
end

local function UnloadRegion()
    for x = minX, maxX do
        for z = minZ, maxZ do
            for y = minY, maxY do
                SetBlock(x, y, z, 0);
            end
        end
    end
    -- cmd(format("/goto %s %s %s", math.floor((maxX + minX) / 2), minY, math.floor((maxZ + minZ) / 2)));
end

-- cmd(format("/goto %s %s %s", centerX, centerY, centerZ));

local function LoadLevel()
    LoadRegion();
    cmd("/property UseAsyncLoadWorld false")
    cmd("/property AsyncChunkMode false");
    cmd(format("/loadtemplate -nohistory %d %d %d %s", math.floor((maxX + minX) / 2), minY + 1, math.floor((maxZ + minZ) / 2), "blocktemplates/level1.blocks.xml"));
    cmd("/property AsyncChunkMode true");
    cmd("/property UseAsyncLoadWorld true");
    cmd(format("/goto %s %s %s", math.floor((maxX + minX) / 2), minY, math.floor((maxZ + minZ) / 2)));

    local sunbin = EntityNPC:new():Init({
        bx = 20090,
        by = 9,
        bz = 20067,
        assetfile = "character/CC/artwar/game/sunbin.x"
    });
    sunbin:Turn(-90);

    SetCameraLookAtBlockPos(20090, 8, 20072);
    SetCamera(20, 45, -90);

    CreateEntity({bx = 20090, by = 9, bz = 20077, assetfile = "character/CC/05effect/fireglowingcircle.x"});
    CreateEntity({bx = 20090, by = 9, bz = 20077, assetfile = "@/blocktemplates/tianshucanjuan.x"});
    CreateEntity({bx = 20090, by = 9, bz = 20089, assetfile = "character/CC/artwar/game/pangjuan.x"}):Turn(90);

    local CodeGlobal = {
        sunbin = sunbin,
    }
    
    local function RunCode(code, G)
        local code_func, errormsg = loadstring(code, "loadstring:RunCode");
        if (errmsg) then return warn("invalid code", code) end

        G = G or {};
        setmetatable(G, {__index = _G});
    	-- 设置代码环境
    	setfenv(code_func, G);

        code_func();
    end

    ShowBlocklyCodeEditor({
        run = function(code)
            RunCode(code, CodeGlobal);
        end,
        pause = function()
        end,
    })
end

UnloadRegion();
LoadLevel();
-- sleep(3000);
-- cmd(format("/goto %s %s %s", math.floor((maxX + minX) / 2), minY, math.floor((maxZ + minZ) / 2)));
