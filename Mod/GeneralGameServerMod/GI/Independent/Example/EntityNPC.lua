

local npc = CreateEntityNPC({
    bx = 19191,
    by = 5,
    bz = 19199
});

npc:SetAnimId(5);
npc:Turn(180);

npc:MoveForward(4, 1)