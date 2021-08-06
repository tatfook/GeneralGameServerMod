

local npc = CreateEntity({
    bx = 19191,
    by = 5,
    bz = 19199,
    assetfile = "character/CC/artwar/game/sunbin.x"
});
npc:SetFocus(true);
npc:Say("hello world", 1);
npc:Turn(180);
npc:MoveForward(10, 3);
