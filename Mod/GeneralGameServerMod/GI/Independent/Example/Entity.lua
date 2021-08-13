
print(__BlockSize__)
-- local npc = CreateEntity({
--     bx = 19191,
--     by = 5,
--     bz = 19199,
--     assetfile = "character/CC/artwar/game/sunbin.x",
--     types = {["human"] = 0},
--     biped = true,
-- });


-- local wolf = CreateEntity({
--     bx = 19195,
--     by = 5,
--     bz = 19203,
--     biped = true,
--     assetfile = "character/CC/codewar/lang.x",
--     types = {["lang"] = 0, ["animal"] = 0, ["human"] = 1},
--     isAutoAttack = true,
--     visibleRadius = 5,
--     speed = 2,
--     defaultSkill = CreateSkill({skillRadius = 1}),
-- });

-- npc:MoveForward(4)
-- wolf:AddSkill(Skill:new():Init({
--     skillTime = 0,
--     skillDistance = 10,
--     entity_config = {
--         assetfile = "character/CC/07items/arrow.x",
--     },
-- }));
-- npc:Turn(180);
-- npc:MoveForward(3);
-- npc:MoveForward(3);
-- npc:MoveForward(3);
-- npc:ShowHeadOnDisplay();
-- npc:SetCurrentBlood(30);

-- npc:SetFocus(true);
-- npc:Say("hello world", 1);
-- npc:Turn(180);
-- npc:MoveForward(10, 3);

-- npc:SetHeadOnDisplay({
--     url =  LuaXML_ParseString('<pe:mcml><div style="background-color:red">hello world</div></pe:mcml>'),
--     is3D = true,
-- });

-- local obj = npc:GetInnerObject();
-- obj:SetHeadOnOffset(0, 2, 0, 0);
-- ShowWindow({
 
-- }, {
--     __is_3d_ui__ = true,
--     __3d_object__ = npc:GetInnerObject(),
--     __offset_y__ = 3,
--     __offset_z__ = 0.05,
--     x = -100,
--     width = 200,
--     height = 100,
--     -- url = "%vue%/Example/3D.html",
--     template = [[
-- <template style="width: 100%; height: 100%;">
--     <div style="color:#ffffff; font-size: 30px; background-color: #000000;">
--         hello worlddsafdafdafdafdsdfsffdafdadadfa
--     </div>
-- </template>
-- ]],
-- });


-- ShowWindow(nil, {
--     width = 200,
--     height = 100,
--     template = [[
--         <template style="width: 10/0%; height: 100%;">
--             <progress style="background-color: #FF0000" color="#00FF00" percentage=50></progress>
--         </template>    
--     ]]
-- })

-- local Skill = require("Skill");
-- local wolf = CreateEntity({
--     bx = 19205,
--     by = 5,
--     bz = 19198,
--     assetfile = "character/CC/codewar/lang.x"
-- });

-- -- wolf:AddSkill(Skill:new():Init({
-- --     skillTime = 0,
-- --     skillDistance = 10,
-- --     entity_config = {
-- --         assetfile = "character/CC/07items/arrow.x",
-- --     },
-- -- }));

-- wolf:AddSkill(Skill:new():Init())
-- sleep(1000)
-- wolf:Attack();
-- sleep(1000)
-- wolf:Attack();