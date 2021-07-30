

-- local npc = CreateEntity({
--     bx = 19191,
--     by = 5,
--     bz = 19199,
--     assetfile = "character/CC/artwar/game/sunbin.x"
-- });

local EntityNPC = require("EntityNPC");

local npc = EntityNPC:new():Init({
    bx = 19191,
    by = 5,
    bz = 19199,
    assetfile = "character/CC/artwar/game/sunbin.x"
});

npc:Say("hello world", 1);
npc:Turn(180);
npc:MoveForward(10, 3);

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


-- local x, y, z = 19419,7,19220;
-- cmd("/property UseAsyncLoadWorld false")
-- cmd(format("/loadregion %d %d %d 200", x, y, z));
-- cmd("/property UseAsyncLoadWorld true")
-- cmd(format("/loadtemplate -nohistory %d %d %d %s", x, y, z, "blocktemplates/level1.blocks.xml"));
-- -- print(format("/loadtemplate -r -nohistory %d %d %d %s", x, y, z, "blocktemplates/level1.blocks.xml"))
-- cmd(format("/goto %s %s %s", x + 26, y, z + 3))


-- SetCameraLookAtBlockPos(19444, 7, 19235);
-- SetCamera(20, 90, -90);

-- local CodeGlobal = {
--     sunbin = npc,
-- }
-- local function RunCode(code, G)
--     local code_func, errormsg = loadstring(code, "loadstring:RunCode");
--     if (errmsg) then return warn("invalid code", code) end

--     G = G or {};
--     setmetatable(G, {__index = _G});
-- 	-- 设置代码环境
-- 	setfenv(code_func, G);

--     code_func();
-- end

-- ShowWindow({
--     run = function(code)
--         RunCode(code, CodeGlobal);
--     end,
--     pause = function()
        
--     end,
-- }, {
--     url = "%gi%/Independent/UI/BlocklyCodeEditor.html",
--     draggable = true,
-- })