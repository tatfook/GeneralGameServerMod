--[[
Title: main
Author(s):  wxa
Date: 2021-06-01
Desc: 入口文件
use the lib:
]]

-- require("@/npc.lua");
local Level = require("%gi%/App/sunzibingfa/Level/Level.lua");
local Level1 = require("%gi%/App/sunzibingfa/Level/Level1.lua");

local Level2 = require("%gi%/App/sunzibingfa/Level/Level2.lua");
local Level3 = require("%gi%/App/sunzibingfa/Level/Level3.lua");
local Level4 = require("%gi%/App/sunzibingfa/Level/Level4.lua");

-- Level1:EditOld("level1")
-- Level1:Edit("level1")
-- Level1:Export();
Level1:Import();

-- Level2:EditOld()
-- Level2:Edit();
-- Level2:Export();
-- Level2:Import();

-- Level3:EditOld()
-- Level3:Edit();
-- Level3:Import();

-- Level4:EditOld()
-- Level4:Edit();
-- Level4:Import();

-- local tower = Level:CreateTowerEntity(19205,5,19202);
-- local hunter = Level:CreateHunterEntity(19205,5,19206);
-- SetCameraLookAtPos(hunter:GetPosition())

-- -- sleep(3000);

-- local wolf = Level:CreateWolfEntity(19210,5,19206);
-- wolf:MoveForward();

function clear()
    cmd("/mode edit");
    cmd("/home");
    -- Level:UnloadMap();
end


-- todo
-- 手持物品  比较麻烦            困难
-- 范围攻击 浪寻找一定的人攻击    中等
-- 弓箭攻击           中等
-- 箭塔               中等   
-- 触碰玩家消失        简单
-- 建桥拆桥            简单
-- 生成时间任务         简单
-- 血块                简单
-- movexy ... 其它API

-- 问题
-- 关卡过多, 有点重复
-- 感觉关卡都是反向设计出来, 正向去玩难度过大, 且指引不够, 很多关卡可能根本不知道怎么玩, 特别动态出现的场景.  感觉没必要设计这么复杂
-- 自己过关会出现奇怪问题 比如movexy在地图一个位置, 可能根本走不过去, 被方块挡住一直原地走
-- 前面关卡了解东西在后面可能无法复用, 比如狼的行为, 感觉特定关卡有特定行为, 增加游戏难度
-- 通关代码有百分之一的概率不能通关, 再次执行又可以
-- 关卡设计的需要写的代码有点多和复杂(问题不大, 但影响关卡设计的者的效率, 感觉也是设计太复杂, 导致有点难玩)

-- 目的
-- 不为了做而做, 还是的做少做好. 否则意义不是很大, 目前 GI 对前面几关比较友好, 上述todo会实现类似功能, 但可能不以现有方式去做, 
-- 会往通用性,一致性的方向去做.
