
local Level = require("Level");

-- SetCamera(20, 45, -90);
-- SetCameraLookAtBlockPos(10090,12,10075);

-- __ClearAllEntity__();
-- local sunbin = CreateEntity({
--     bx = 10090,
--     by = 12,
--     bz = 10067,
--     biped = true,
--     assetfile = "character/CC/artwar/game/sunbin.x",
--     physicsHeight = 1.765,
-- });
-- sunbin:Turn(-90);

-- local fireglowingcircle = CreateEntity({bx = 10090, by = 12, bz = 10077, destroyBeCollided = true, assetfile = "character/CC/05effect/fireglowingcircle.x"});
-- local tianshucanjuan = CreateEntity({bx = 10090, by = 12, bz = 10077, destroyBeCollided = true, assetfile = "@/blocktemplates/tianshucanjuan.x"});
-- local pangjuan = CreateEntity({bx = 10090, by = 12, bz = 10089, physicsRadius = 2, assetfile = "character/CC/artwar/game/pangjuan.x"});
-- pangjuan:Turn(90);

-- local tianshucanjuan_goods = CreateGoods({transfer = true, title = "天书残卷"});
-- local position_goods = CreateGoods({transfer = true, title = "目标位置"});
-- tianshucanjuan:AddGoods(tianshucanjuan_goods);
-- pangjuan:AddGoods(position_goods);


-- Level:LoadMap();
-- Level:Edit();

-- Level:Export();
-- print(Level:GetCenterPoint());

-- ShowBlocklyCodeEditor({
--     run = function(code)
--     end,
--     restart = function()
--     end
-- });

function clear()
    cmd("/mode edit");
    cmd("/home");
    -- Level:UnloadMap();
end


