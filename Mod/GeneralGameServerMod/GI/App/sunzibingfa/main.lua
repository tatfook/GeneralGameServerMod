--[[
Title: main
Author(s):  wxa
Date: 2021-06-01
Desc: 入口文件
use the lib:
]]

-- require("@/npc.lua");
local Level = require("./Level/Level.lua");
local Level1 = require("./Level/Level1.lua");
local Level2 = require("./Level/Level2.lua");
local Level3 = require("./Level/Level3.lua");
local Level4 = require("./Level/Level4.lua");
local Level5 = require("./Level/Level5.lua");
local Level6 = require("./Level/Level6.lua");
local Level7 = require("./Level/Level7.lua");
local Level8 = require("./Level/Level8.lua");

local function TranformTemplate(old_level_name, new_level_name)
    cmd("/property UseAsyncLoadWorld false")
    cmd("/property AsyncChunkMode false");
    Level:ClearRegion();

    if (old_level_name and old_level_name ~= "") then cmd(format("/loadtemplate 10064 12 10064 %s", old_level_name)) end
    -- cmd(format("/goto %s %s %s", 10064, 8, 10064));
    sleep(200);
    Level:Export(new_level_name);
    sleep(200);

    if (old_level_name and old_level_name ~= "") then cmd(format("/loadtemplate -r 10064 12 10064 %s", old_level_name)) end
    cmd("/property AsyncChunkMode true");
    cmd("/property UseAsyncLoadWorld true");
end

-- TranformTemplate("level5", "_level8");
-- Level:ClearRegion();

-- Level1:Edit()
-- Level1:Load();

-- Level2:Edit();
-- Level2:Export();
-- Level2:Load();

-- Level3:Edit();
-- Level3:Load();

-- Level4:Edit();
-- Level4:Load();

-- Level5:Edit();
-- Level5:Load();

-- Level6:Edit();
-- Level6:Load();

-- Level7:Edit();
-- Level7:Load();

-- Level8:Load();
-- Level8:Edit(true);

Level:CreateSunBinEntity(19197,5,19202):MoveForward(1)
function clear()
    cmd("/mode edit");
    cmd("/home");
    cmd("/show quickselectbar");
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
