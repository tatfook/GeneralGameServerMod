--[[
Title: level
Author(s):  wxa
Date: 2021-06-01
Desc: 关卡模板文件
use the lib:
]]

local Level = inherit(require("Level"), module()) ;

function Level:ctor()
    self.__all_entity__ = {};
end

-- 监听关卡加载事件,  完成关卡内容设置
function Level:LoadLevel()
end

-- 监听关卡卸载事件,  移除关卡相关资源
function Level:UnloadLevel()
    __ClearAllEntity__();
end

-- 执行关卡代码前, 
function Level:RunLevelCodeBefore()
end

-- 执行关卡代码后
function Level:RunLevelCodeAfter()
end

-- 重置关卡
function Level:ResetLevel()
end

-- 创建孙膑NPC
function Level:CreateSunBinEntity(bx, by, bz)
    local sunbin = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "sunbin",
        biped = true,
        assetfile = "character/CC/artwar/game/sunbin.x",
        physicsHeight = 1.765,
    });
    self.__all_entity__["sunbin"] = sunbin;
    return sunbin;
end

-- 创建天书残卷NPC
function CreateTianShuCanJuanEntity(bx, by, bz)
    local fireglowingcircle = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "fireglowingcircle",
        assetfile = "character/CC/05effect/fireglowingcircle.x",
    });
    self.__all_entity__["fireglowingcircle"] = fireglowingcircle;

    fireglowingcircle:AddGoods(CreateGoods({gsid = 1}));
    local tianshucanjuan = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "tianshucanjuan",
        assetfile = "@/blocktemplates/tianshucanjuan.x",
    });
    self.__all_entity__["tianshucanjuan"] = tianshucanjuan;
    tianshucanjuan:AddGoods(CreateGoods({gsid = 1}));
    tianshucanjuan:AddGoods(CreateGoods({gsid = 2, name = "tianshucanjuan"}));
    tianshucanjuan:SetPositionChangeCallBack(function()
        fireglowingcircle:SetPosition(tianshucanjuan:GetPosition())
    end);
    return tianshucanjuan;
end

-- 创建庞涓NPC
function CreatePangJuanEntity(bx, by, bz)
    local pangjuan = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "pangjuan",
        assetfile = "character/CC/artwar/game/pangjuan.x",
    });
    self.__all_entity__["pangjuan"] = pangjuan;
    return pangjuan;
end

-- 创建目标位置NPC
function CreateTargetPositionEntity(bx, by, bz)
    local target_position = CreateEntity({
        bx = bx, by = by, bz = bz,
        name = "target_position",
        -- assetfile = "@/blocktemplates/goalpoint.bmax",
        assetfile = "character/CC/05effect/fireglowingcircle.x",
    });
    self.__all_entity__["target_position"] = target_position;
    target_position:AddGoods(CreateGoods({name = "target_position", title = "目标位置", description = "角色到达指定地点获得该物品"}));
    return target_position;
end

Level:InitSingleton();
-- -- 监听关卡加载事件,  完成关卡内容设置
-- On("LoadLevel", function()
-- end);

-- -- 监听关卡卸载事件,  移除关卡相关资源
-- On("UnloadLevel", function()
-- end)

-- -- 执行关卡代码前, 
-- On("RunLevelCodeBefore", function()
-- end)

-- -- 执行关卡代码后
-- On("RunLevelCodeAfter", function()
-- end)

-- -- 重置关卡
-- On("ResetLevel", function()
-- end);

-- -- 触发关卡重置
-- Emit("ResetLevel");