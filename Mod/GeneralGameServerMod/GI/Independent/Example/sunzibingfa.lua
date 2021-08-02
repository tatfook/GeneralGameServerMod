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

local function LoadMap(map_template_file)
    UnloadRegion();
    LoadRegion();

    cmd("/property UseAsyncLoadWorld false")
    cmd("/property AsyncChunkMode false");
    cmd(format("/loadtemplate -nohistory %d %d %d %s", math.floor((maxX + minX) / 2), minY + 1, math.floor((maxZ + minZ) / 2), map_template_file));
    cmd("/property AsyncChunkMode true");
    cmd("/property UseAsyncLoadWorld true");
end

local function RunCode(code, G)
    local code_func, errormsg = loadstring(code, "loadstring:RunCode");
    if (errmsg) then return warn("invalid code", code) end

    G = G or {};
    setmetatable(G, {__index = _G});
    -- 设置代码环境
    setfenv(code_func, G);

    code_func();
end

local G = {};
local function Reset()
    SetCameraLookAtBlockPos(20090, 8, 20072);
    SetCamera(20, 45, -90);

    __ClearAllEntity__();

    local sunbin = CreateEntity({
        bx = 20090,
        by = 9,
        bz = 20067,
        biped = true,
        assetfile = "character/CC/artwar/game/sunbin.x",
        physicsHeight = 1.765,
    });
    sunbin:Turn(-90);

    local fireglowingcircle = CreateEntity({bx = 20090, by = 9, bz = 20077, destroyBeCollided = true, assetfile = "character/CC/05effect/fireglowingcircle.x"});
    local tianshucanjuan = CreateEntity({bx = 20090, by = 9, bz = 20077, destroyBeCollided = true, assetfile = "@/blocktemplates/tianshucanjuan.x"});
    local pangjuan = CreateEntity({bx = 20090, by = 9, bz = 20089, physicsRadius = 2, assetfile = "character/CC/artwar/game/pangjuan.x"});
    pangjuan:Turn(90);

    local tianshucanjuan_goods = CreateGoods({transfer = true, title = "天书残卷"});
    local position_goods = CreateGoods({transfer = true, title = "目标位置"});
    tianshucanjuan:AddGoods(tianshucanjuan_goods);
    pangjuan:AddGoods(position_goods);

    G.sunbin = sunbin;
end

local function LoadLevel()
    LoadMap("blocktemplates/level1.blocks.xml");

    Reset();

    local function RunCodeBefore()
    
    end

    local function RunCodeAfter()
        if (G.sunbin:HasGoods(tianshucanjuan_goods) and G.sunbin:HasGoods(position_goods)) then
        end
    end

    ShowBlocklyCodeEditor({
        ToolBoxXmlText = [[
<toolbox>
    <category name="运动">
        <block type="MoveForward"/>
    </category>
</toolbox>
        ]],
        run = function(code)
            RunCodeBefore();
            RunCode(code, G);
            RunCodeAfter();
        end,
        restart = function()
            Reset();
        end
    });
end

LoadLevel();
-- sleep(3000);
-- cmd(format("/goto %s %s %s", math.floor((maxX + minX) / 2), minY, math.floor((maxZ + minZ) / 2)));


function clear()
    cmd("/home");
end