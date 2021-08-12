

local npc = CreateEntity({
    bx = 19191,
    by = 5,
    bz = 19199,
    -- assetfile = "character/CC/artwar/game/sunbin.x"
});
-- npc:SetFocus(true);
-- npc:Say("hello world", 1);
-- npc:Turn(180);
-- npc:MoveForward(10, 3);


ShowWindow({
 
}, {
    __is_3d_ui__ = true,
    __3d_object__ = npc:GetInnerObject(),
    width = 100,
    height = 100,
    y = -200,
    alignment = "_lt",
    -- url = "%vue%/Example/3D.html",
    template = [[
<template style="width: 100%; height: 100%">
    <div style="color:#ffffff; font-size: 30px; background-color: #000000;">
        hello worlddsafdafdafdafdsdfsffdafdadadfa
    </div>
</template>
]],
});
