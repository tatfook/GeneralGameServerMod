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
local Level9 = require("./Level/Level9.lua");
local Level10 = require("./Level/Level10.lua");
local Level11 = require("./Level/Level11.lua");
local Level12 = require("./Level/Level12.lua");
local Level13 = require("./Level/Level13.lua");
local Level14 = require("./Level/Level14.lua");
local Level15 = require("./Level/Level15.lua");
local Level16 = require("./Level/Level16.lua");
local Level17 = require("./Level/Level17.lua");
local Level18 = require("./Level/Level18.lua");
local Level19 = require("./Level/Level19.lua");
local Level20 = require("./Level/Level20.lua");
local Level21 = require("./Level/Level21.lua");
local Level22 = require("./Level/Level22.lua");
local Level23 = require("./Level/Level23.lua");
local Level24 = require("./Level/Level24.lua");
local Level27 = require("./Level/Level27.lua");
local Level28 = require("./Level/Level28.lua");

local function TranformTemplate(old_level_name, new_level_name)
    Level:LoadRegion();
    Level:ClearRegion();

    cmd("/property UseAsyncLoadWorld false")
    cmd("/property AsyncChunkMode false");
    
    if (old_level_name and old_level_name ~= "") then cmd(format("/loadtemplate 10064 12 10064 %s", old_level_name)) end
    -- cmd(format("/goto %s %s %s", 10064, 8, 10064));
    sleep(200);
    Level:Export(new_level_name);
    sleep(200);

    if (old_level_name and old_level_name ~= "") then cmd(format("/loadtemplate -r 10064 12 10064 %s", old_level_name)) end
    cmd("/property AsyncChunkMode true");
    cmd("/property UseAsyncLoadWorld true");
end

-- TranformTemplate("level18", "_level30");
-- Level:ClearRegion();

-- Level1:Edit(true)
Level1:Load();

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

-- Level9:Load();
-- Level9:Edit(true);

-- Level10:Load();
-- Level10:Edit(true);

-- Level11:Load();
-- Level11:Edit(true);

-- Level12:Load();
-- Level12:Edit(true);

-- Level13:Load();
-- Level13:Edit(true);

-- Level14:Load();
-- Level14:Edit(true);

-- Level15:Load();
-- Level15:Edit(true);

-- Level16:Load();
-- Level16:Edit(true);

-- Level17:Load();
-- Level17:Edit(true);

-- Level18:Load();
-- Level18:Edit(true);

-- Level19:Load();
-- Level19:Edit(true);

-- Level20:Load();
-- Level20:Edit(true);

-- Level21:Load();
-- Level21:Edit(true);

-- Level22:Load();
-- Level22:Edit(true);

-- Level23:Load();
-- Level23:Edit(true);

-- Level24:Load();
-- Level24:Edit(true);

-- Level27:Load();
-- Level27:Edit(true);

-- Level28:Load();
-- Level28:Edit(true);

-- local sunbin = CreateSunBinEntity(19197,5,19202);
-- sunbin:SetCurrentBlood(80)
-- local wolf = CreateWolfEntity(19197,5,19206);
-- wolf:SetCurrentBlood(80)
-- sunbin:MoveForward(1)
-- sunbin:MoveForward(1)

function clear()
    if (wolf) then wolf:Destroy() end 
    if (sunbin) then sunbin:Destroy() end 

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
