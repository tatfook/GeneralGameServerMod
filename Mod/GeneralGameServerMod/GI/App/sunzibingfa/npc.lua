--[[
Title: npc
Author(s):  wxa
Date: 2021-06-01
Desc: npc 简化
use the lib:
]]

-- 创建孙膑NPC
function CreateSunBinEntity(bx, by, bz)
    return CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "sunbin",
        biped = true,
        assetfile = "character/CC/artwar/game/sunbin.x",
        physicsHeight = 1.765,
    });
end

-- 创建天书残卷NPC
function CreateTianShuCanJuanEntity(bx, by, bz)
    local fireglowingcircle = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "fireglowingcircle",
        assetfile = "character/CC/05effect/fireglowingcircle.x",
    });
    fireglowingcircle:AddGoods(CreateGoods({gsid = 1}));
    local tianshucanjuan = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "tianshucanjuan",
        assetfile = "@/blocktemplates/tianshucanjuan.x",
    });
    tianshucanjuan:AddGoods(CreateGoods({gsid = 1}));
    tianshucanjuan:AddGoods(CreateGoods({gsid = 2, name = "tianshucanjuan"}));
    tianshucanjuan:SetPositionChangeCallBack(function()
        fireglowingcircle:SetPosition(tianshucanjuan:GetPosition())
    end);
    return tianshucanjuan;
end

-- 创建庞涓NPC
function CreatePangJuanEntity(bx, by, bz)
    return CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "pangjuan",
        assetfile = "character/CC/artwar/game/pangjuan.x",
    });
end

-- 创建目标位置NPC
function CreateTargetPositionEntity(bx, by, bz)
    local target_position = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "target_position",
        assetfile = "@/blocktemplates/goalpoint.bmax",
    });
    target_position:AddGoods(CreateGoods({name = "target_position", title = "目标位置", description = "角色到达指定地点获得该物品"}));
end
