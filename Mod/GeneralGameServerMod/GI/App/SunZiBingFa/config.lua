config = gettable("game.config")

config.ticketExid = 10020;
config.ticketGsid = 10004;

config.levelExid = 10023;
config.levelGsid = 30250;
config.tipinfoExid = 10030;
config.tipinfoGsid = 30260;

-- chapters and levels status
config.Dev = 0;
config.Passed = 1;
config.Open = 2;
config.Locked = 3;

local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local KeepWorkItemManager = GameLogic.KeepWorkItemManager;

-- 注意：如果有sceneFile: 请保证存为模板时，原点在左下角minX，minZ的地方
--第一章
local cx, cy, cz = 19210,5,19200
local function getCodePos(dx, dz, isAdding,branchNum)
    if branchNum then
        return {cx + branchNum*5,cy,cz}
    else
        if(isAdding) then
            cx = cx + (dx or 0)
            cz = cz + (dz or 0)
            return {cx, cy, cz}
        else
            return {cx + (dx or 0), cy, cz + (dz or 0)}
        end
    end
end
--第二章
local cx2, cy2, cz2 = 19199,5,19185
local function getCodePos2(dx, dz, isAdding,branchNum)
    if branchNum then
        return {cx2 + branchNum*5,cy2,cz2}
    else
        if(isAdding) then
            cx2 = cx2 + (dx or 0)
            cz2 = cz2 + (dz or 0)
            return {cx2, cy2, cz2}
        else
            return {cx2 + (dx or 0), cy2, cz2 + (dz or 0)}
        end
    end
end

local levels = {
    --levels of chapter1
    {
        {
            name="鬼谷学堂", x=334, y=111, status = config.Open, 
            pos = getCodePos(),
            desc = "鬼谷仙山中，孙膑和庞涓是鬼谷子门下的两位高徒，讲学堂是鬼谷子师父平日里授课的地方，也是孙膑庞涓等师兄弟平日里讨论学习的主要场所，课余时间这里也会有一些欢乐的小比赛…",
            keypoints = "【参数】【基本语法】",
            mapRegion = {min={19419,7,19220}, size={50, 50}},
            sceneFile = "blocktemplates/level1.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=1,
            index=1,
        },
        {
            name="森林探险", x=255, y=160, status = config.Locked, 
            pos = getCodePos(0, -5, true, 1),
            desc = "出了讲学堂往山下走有一片森林，是孙膑和庞涓娱乐和冒险的地方，诺大的森林充满着未知，师兄弟乐于在这片森林中探索着新鲜事物来满足自己的好奇心。",
            keypoints = "【参数】【基本语法】",
            mapRegion = {min={19419,8,19223}, size={50, 50}},
            sceneFile = "blocktemplates/level1.1.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=1,
            index=2,
        },
        {
            name="林中竞赛", x=190, y=245, status = config.Locked, 
            pos = getCodePos(0, -5, true),
            desc = "在森林中探索未知的领域一直是孙膑和庞涓喜欢做的事情，他们师兄弟还经常约定比赛看谁先到达终点，不过大多数时候，师弟庞涓总是能使一些小聪明率先到达目标点。",
            keypoints = "【参数】【基本语法】",
            mapRegion = {min={19419,8,19217}, size={50, 50}},
            sceneFile = "blocktemplates/level2.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=1,
            index=3,
        },
        {
            name="突发险情", x=175, y=345, status = config.Locked, 
            pos = getCodePos(0, -5, true),
            desc = "这一次的林中探险出现了一些问题，孙膑和庞涓分开后，孙膑到达终点等候许久后也没有发现庞涓的身影，眼见天色渐晚，孙膑开始焦急的四处寻找师弟。",
            keypoints = "【参数】【基本语法】",
            mapRegion = {min={19419,8,19214}, size={50, 50}},
            sceneFile = "blocktemplates/level3.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/Area_FrostRoarIsland.ogg",
            chapter=1,
            index=4,
        },
        {
            name="洞内营救", x=209, y=440, status = config.Locked, 
            pos = getCodePos(0, -5, true, 1),
            desc = "在寻找的途中发现了一处洞穴，在入口处隐约听到有呼救的声音，孙膑意识到师弟庞涓很可能就在山洞里，并且面临着危险，必须马上想办法救援师弟…",
            keypoints = "【参数】【基本语法】",
            mapRegion = {min={19413,10,19218}, size={50, 50}},
            sceneFile = "blocktemplates/level3.1.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            chapter=1,
            index=5,
        },
        {
            name="寻求出口", x=309, y=510, status = config.Locked,
            pos = getCodePos(0, -5, true),
            desc = "山洞中光线昏暗，道路难寻，但孙膑根据不时吹来的拂面微风知道，只要沿着空气流通的方向就可以找到出口，然而前路未知，还需谨慎小心才能保证师兄弟的安全。",
            keypoints = "【参数】【基本语法】",
            mapRegion = {min={19409,9,19223}, size={50, 50}},
            sceneFile = "blocktemplates/level4.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            chapter=1,
            index=6,
        },
        {
            name="乱石迷窟", x=414, y=535, status = config.Locked, 
            pos = getCodePos(0, -5, true, 1),
            desc = "出了昏暗的山洞后，视野豁然开朗，呈现在眼前的是一片如同迷宫般的乱石迷窟，错综复杂的道路上布满了捕兽夹，好像是有人故意而为，小心选择正确的路径来穿越迷窟。",
            keypoints = "【参数】【基本语法】",
            mapRegion = {min={19411,8,19214}, size={50, 50}},
            sceneFile = "blocktemplates/level4.1.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_FrostRoarIsland.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkPlain.ogg",
            chapter=1,
            index=7,
        },
        {
            name="恶狼之森", x=534, y=535, status = config.Locked,
            pos = getCodePos(0, -5, true),
            desc = "幽暗的森林中经常出现四处游荡的恶狼，想必之前迷窟中的捕兽夹就是用来对付它们的，但现在单凭师兄弟两人的力量是无法正面打败这些恶狼的，所以最好避开它们才能通过森林。",
            keypoints = "【参数】【基本语法】",
            mapRegion = {min={19419,8,19210}, size={50, 50}},
            sceneFile = "blocktemplates/level5.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkforest.ogg",
            chapter=1,
            index=8,
        },
        {
            name="夜路前行", x=622, y=490, status = config.Locked,
            pos = getCodePos(0, -5, true),
            desc = "在森林中走夜路往往是伴随着危险的，所以山下的村民有时会在道路旁边放一些火把来给过往的旅人提供帮助，既然之前已经使用过，想必已经知道火把的作用了，那就好好运用吧。",
            keypoints = "【参数】【基本语法】",
            mapRegion = {min={19415,8,19212}, size={50, 50}},
            sceneFile = "blocktemplates/level6.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkforest.ogg",
            chapter=1,
            index=9,
        },
        {
            name="初遇猎人", x=527, y=460, status = config.Locked, 
            pos = getCodePos(0, -5, true, 1),
            desc = "虽然万分小心的通过了森林，但还是有一头恶狼跟在了后面，再往前走就到山下的村庄了，不能将危险带到村民那里，不过村庄的入口大多会有猎人的守护，想办法消灭恶狼吧！",
            keypoints = "【参数】【基本语法】",
            mapRegion = {min={19419,8,19218}, size={50, 50}},
            sceneFile = "blocktemplates/level6.1.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=1,
            index=10,
        },
        {  
            name="修复要道", x=368, y=440, status = config.Locked,
            pos = getCodePos(0, -5, true),
            desc = "从猎人那里得知，山上森林盘踞的凶猛狼群一直威胁着村民的安全，为首的狼王更是会带领狼群下山觅食，不久之前，村民们用火驱赶狼群时，不小心将村口的桥梁给烧毁了，现在需要尽快重建才能恢复交通… ",
            keypoints = "【参数】【基本语法】【字符串】",
             mapRegion = {min={19414,8,19219}, size={50, 50}},
            sceneFile = "blocktemplates/level7.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=1,
            index=11,
        },
        {
            name="切断隐患", x=397, y=365, status = config.Locked, 
            pos = getCodePos(0, -5, true, 1),
            desc = "在村庄的另一侧有一处没有猎人看守的小桥，虽然位置比较隐蔽，但还是被狼群发现，时常有恶狼从那里溜进村庄伤害人畜，既然村庄出入口处的桥梁已经修复，不如拆除小桥断绝隐患。",
            keypoints = "【参数】【基本语法】【字符串】",
            mapRegion = {min={19419,8,19216}, size={50, 50}},
            sceneFile = "blocktemplates/level7.1.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=1,
            index=12,
        },
        {
            name="计策关:上屋抽梯", x=516, y=335, status = config.Locked,
            pos = getCodePos(0, -5, true),
            desc = "【上屋抽梯意思是借给敌人一些方便，以诱导敌人深入我方，乘机切断他的后援和前应，最终打败敌人。】狼王的存在时时刻刻威胁着村庄，村外有一处小岛，是否可以将狼王困在岛上，再伺机消灭它呢？",
            keypoints = "【参数】【基本语法】【字符串】",
            mapRegion = {min={19419,8,19212}, size={50, 50}},
            sceneFile = "blocktemplates/level8.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_DarkForestIsland.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkForestSea.ogg",
            chapter=1,
            index=13,
        },
        {
            name="动身返程", x=560, y=250, status = config.Locked, 
            pos = getCodePos(0, -5, true, 1),
            desc = "虽然下山的道路磕磕绊绊，但也收获颇丰，在猎人那里学会了基本的攻击技能，回去的路上也不怕落单的恶狼了，既然帮助村民解决了狼王的威胁，就尽快返回山上鬼谷学堂，以免师父担心。",
            keypoints = "【参数】【基本语法】",
            mapRegion = {min={19419,8,19219}, size={50, 50}},
            sceneFile = "blocktemplates/level8.1.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=1,
            index=14,
        },
        {
            name="村庄危机", x=648, y=200, status = config.Locked,
            pos = getCodePos(0, -5, true),
            desc = "本以为消灭了狼王，山下村庄便会安全，但是从慌忙出逃的村民口中得知，狼群由于狼王的消失也变得更加狂躁，大举下山找寻狼王的踪迹，猎人也不见了踪影，现在村庄正面临着前所未有的危险…",
            keypoints = "【参数】【基本语法】【字符串】",
            mapRegion = {min={19419,8,19221}, size={50, 50}},
            sceneFile = "blocktemplates/level9.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Combat_Teen_Common_TrialVersion.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambGrassland.ogg",
            chapter=1,
            index=15,
        },
        {
            name="村民的请求", x=745, y=160, status = config.Locked, 
            pos = getCodePos(0, -5, true, 1),
            desc = "长期以来，猎人一直守护着山下村庄，现在他忽然失踪了，村民们都担心猎人和村庄的安全，为此请求孙膑帮忙寻找，然而前路未知，村民们准备了一些干粮以备路途所需，请到村庄各处收集吧！",
            keypoints = "【参数】【基本语法】【while循环】",
            mapRegion = {min={19419,8,19216}, size={50, 50}},
            sceneFile = "blocktemplates/level9.1.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambGrassland.ogg",
            chapter=1,
            index=16,
        },
        {
            name="未知的足迹", x=820, y=195, status = config.Locked,
            pos = getCodePos(0, -5, true),
            desc = "在猎人住处外的森林中，发现了两种脚印，一种是人的，也就可能是失踪的猎人留下的，还有一种脚印巨大，像是某种野兽，这两种脚印都通向森林的深处，这是仅有的线索，事不宜迟，赶快出发吧！ ",
            keypoints = "【参数】【基本语法】【while循环】",
            mapRegion = {min={19419,8,19214}, size={50, 50}},
            sceneFile = "blocktemplates/level10.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=1,
            index=17,
        },
        {
            name="幽林箭塔", x=805, y=280, status = config.Locked, 
            pos = getCodePos(0, -5, true, 1),
            desc = "蜿蜒的林中小道走到尽头后，映入眼帘的是一座陈旧的箭塔，虽然年久失修导致外表稍显破落，但精妙的设计还是吸引了孙膑上前查看，然而不料意外触发了机关，一时间箭如雨下…",
            keypoints = "【参数】【基本语法】【while循环】",
            mapRegion = {min={19419,8,19215}, size={50, 50}},
            sceneFile = "blocktemplates/level10.1.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_FrostRoarIsland.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkPlain.ogg",
            chapter=1,
            index=18,
        },
        {
            name="再遇群狼", x=862, y=350, status = config.Locked,
            pos = getCodePos(0, -5, true),
            desc = "自从消灭狼王，又击退了进犯的狼群后，村庄西边的森林中已经很少有恶狼出现了，原来它们都集结到了人迹罕至的东部森林，也许是想伺机再次进犯村庄，看来找回猎人刻不容缓，先想办法通过这里吧！",
            keypoints = "【参数】【基本语法】【字符串】【while循环】",
            mapRegion = {min={19419,8,19216}, size={50, 50}},
            sceneFile = "blocktemplates/level11.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkforest.ogg",
            chapter=1,
            index=19,
        },
        {
            name="正面交锋", x=945, y=380, status = config.Locked,
            pos = getCodePos(0, -5, true),
            desc = "在找到猎人前，山下村庄无人守护，决不能让狼群在此时对村庄发动攻击，既然向猎人已经学到了不少攻击的技巧，就借此机会多加练习，先消灭沿途的恶狼，再继续寻找猎人的路途…  ",
            keypoints = "【参数】【基本语法】【while循环】",
            mapRegion = {min={19419,8,19216}, size={50, 50}},
            sceneFile = "blocktemplates/level12.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkforest.ogg",
            chapter=1,
            index=20,
        },
        {
            name="断桥寻路", x=967, y=455, status = config.Locked, 
            pos = getCodePos(0, -5, true, 1),
            desc = "夜幕降临，穿过幽暗的森林后，眼前竟然出现了点点火光，隐隐约约可以看出远处是一座古老的寨子，可通向寨子的桥梁却被人破坏，但桥上的脚印分明是不久前留下的，难道是有人通过后破坏了桥梁？",
            keypoints = "【参数】【基本语法】【字符串】【while循环】",
            mapRegion = {min={19419,8,19213}, size={50, 50}},
            sceneFile = "blocktemplates/level12.1.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkforest.ogg",
            chapter=1,
            index=21,
        },
        {
            name="古寨追踪", x=1007, y=525, status = config.Locked,
            pos = getCodePos(0, -5, true),
            desc = "密集的房屋，交错的道路，显示着这座山寨昔日的繁华，如今时过境迁，这里早已破落不堪，古老的山寨处处游荡着恶狼，路上依稀可见的脚印指引着追寻猎人踪迹的方向，努力完成目标，通过这危机四伏的古山寨吧！",
            keypoints = "【参数】【基本语法】【字符串】【while循环】",
            mapRegion = {min={19416,8,19209}, size={50, 50}},
            sceneFile = "blocktemplates/level13.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_FrostRoarIsland.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkPlain.ogg",
            chapter=1,
            index=22,
        },
        {
            name="猎人现身", x=1106, y=520, status = config.Locked, 
            pos = getCodePos(0, -5, true, 1),
            desc = "跟随着脚印的方向来到了一间陈旧的密室，微弱的光线中终于发现了猎人的身影，但在猎人面前，出现了无数双发着绿光的眼睛，显然猎人正遭遇着群狼的威胁，然而远处低沉的怒吼声，说明危险不止于此…",
            keypoints = "【参数】【基本语法】【字符串】【while循环】",
            mapRegion = {min={19419,8,19211}, size={50, 50}},
            sceneFile = "blocktemplates/level13.1.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_FrostRoarIsland.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkPlain.ogg",
            chapter=1,
            index=23,
        },    
        {
            name="并肩作战", x=1170, y=470, status = config.Locked,
            pos = getCodePos(0, -5, true),
            desc = "逃出密室后，在短暂的休整期间得知了猎人这几天的遭遇，但随着猛虎追出密室，山寨中的群狼也开始接近，新的挑战又开始了，这一次，是和猎人的并肩作战，分工明确，相互救援才能逃出生天…",
            keypoints = "【参数】【基本语法】【字符串】【while循环】",
            mapRegion = {min={19419,8,19212}, size={50, 50}},
            sceneFile = "blocktemplates/level14.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_DarkForestIsland.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkForestSea.ogg",
            chapter=1,
            index=24,
        },
        {
            name="突出重围", x=1203, y=390, status = config.Locked,
            pos = getCodePos(0, -5, true),
            desc = "尽管有着和猎人相互之间的配合和援助，但也只是在这危机四伏，困难重重的古寨之中争取了一点生存的时间，要想真正的脱离危险，还是要想办法离开这里，只有各自为战，才能突出重围！",
            keypoints = "【参数】【基本语法】【字符串】【while循环】",
            mapRegion = {min={19415,8,19212}, size={50, 50}},
            sceneFile = "blocktemplates/level15.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Combat_Teen_Common_TrialVersion.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambGrassland.ogg",
            chapter=1,
            index=25,
        },
        {
            name="计策关：借刀殺人", x=1171, y=310, status = config.Locked, 
            pos = getCodePos(0, -5, true, 1),
            desc = "【借刀殺人意思是利用他人的力量去消灭敌人，自己不需要付出什么力量。】在古山寨突出重围后，终于回到了东部森林的入口处，然而猛虎仍是紧跟其后，是否可以利用眼前的幽林箭塔，彻底击败猛虎呢？",
            keypoints = "【参数】【基本语法】【字符串】",
            mapRegion = {min={19419,8,19211}, size={50, 50}},
            sceneFile = "blocktemplates/level15.1.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Combat_Teen_Common_TrialVersion.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambGrassland.ogg",
            chapter=1,
            index=26,
        }, 
        {
            name="鬼谷来信", x=1215, y=235, status = config.Locked,
            pos = getCodePos(0, -5, true),
            desc = "利用计策借助箭塔的力量成功消灭了猛虎，但正当与猎人一起返回村庄时，山上鬼谷学堂派人送来了师弟庞涓的信，信上说师弟即将出仕魏国，希望临行前能够与之相见……可山路漫漫，能不能来的及呢？",
            keypoints = "【参数】【基本语法】【字符串】【while循环】",
            mapRegion = {min={19419,8,19212}, size={50, 50}},
            sceneFile = "blocktemplates/level16.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=1,
            index=27,
        },
        {
            name="另辟蹊径", x=1213, y=165, status = config.Locked,
            pos = getCodePos(0, -5, true),
            desc = "山路本就难行，眼前的崇山峻岭又挡住了去路，若要翻山越岭，恐怕不能在师弟离开前赶回鬼谷，高山之侧有一条隐蔽的小道，若是能通过这条道路，想必一定会加快行进的速度，早日抵达鬼谷。",
            keypoints = "【参数】【基本语法】【字符串】【while循环】",
            mapRegion = {min={19419,8,19212}, size={50, 50}},
            sceneFile = "blocktemplates/level17.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=1,
            index=28,
        },
        {
            name="巧避山贼", x=1139, y=115, status = config.Locked, 
            pos = getCodePos(0, -5, true, 1),
            desc = "虽然通过小道减少了返回鬼谷的路程，但是山间小道错综复杂，在匆忙赶路时不小心误入了山贼的营寨，如果被山贼捉到，就不能按时赶回鬼谷了，想办法避开山贼的攻击，尽快通过营寨才是上策…",
            keypoints = "【参数】【基本语法】【字符串】【while循环】",
            mapRegion = {min={19419,8,19211}, size={50, 50}},
            sceneFile = "blocktemplates/level17.1.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=1,
            index=29,
        }, 
        {
            name="长亭送别", x=1049, y=105, status = config.Locked,
            pos = getCodePos(0, -5, true),
            desc = "尽管从东部森林的上山之路充满曲折，但也算是减去了不少路程，在离鬼谷已经近在咫尺时，却得知师弟庞涓马上就要启程了，如今已在鬼谷学堂外的长亭等候，长亭外古道边，能否赶上与师弟见最后一面呢？",
            keypoints = "【参数】【基本语法】【字符串】【while循环】",
            mapRegion = {min={19419,8,19212}, size={50, 50}},
            sceneFile = "blocktemplates/level18.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=1,
            index=30,
        },
    
    },

    --levels of chapter2
    {
        {
            name="师徒相聚", x=207, y=115, status = config.Locked, 
            pos = getCodePos2(),
            desc = "斗转星移，岁月如梭，转眼之间师兄弟已经到了分离的时刻，在长亭送别后，接到了鬼谷学堂传来的消息，师父鬼谷子交代庞涓走后，马上赶回学堂，似乎是有什么要紧的事，还是快些去面见师父吧！",
            keypoints = "【参数】【基本语法】",
            mapRegion = {min={19419,8,19211}, size={50, 50}},
            sceneFile = "blocktemplates/2level1.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=1,
        },
        {
            name="青梅煮酒", x=406, y=245, status = config.Locked, 
            pos = getCodePos2(0, -5, true),
            desc = "山谷之外皆是乱世，鬼谷之中与世无争，一片和平宁静的光景，然而虽身处鬼谷，但不能置身世外，正所谓“风声雨声读书声，声声入耳；家事国事天下事，事事关心”，今日师徒齐聚，青梅煮酒论英雄！",
            keypoints = "【参数】【基本语法】【字符串】",
            mapRegion = {min={19419,8,19214}, size={50, 50}},
            sceneFile = "blocktemplates/2level2.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=2,
        },
        {
            name="师父的考验", x=512, y=255, status = config.Locked, 
            pos = getCodePos2(0, -5, true),
            desc = "相传鬼谷之中有一种山花，不为世人所常见，鬼谷子师父派你去采集一些，却并未告知具体的用途，听闻鬼谷学堂外的高山脚下出现过这种山花，可那里在山贼营寨的附近，危机重重，难道这是鬼谷子师父的一种考验？",
            keypoints = "【参数】【基本语法】【字符串】",
            mapRegion = {min={19419,8,19214}, size={50, 50}},
            sceneFile = "blocktemplates/2level3.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=3,
        },
        {
            name="鬼谷试炼一", x=613, y=260, status = config.Locked, 
            pos = getCodePos2(0, -5, true),
            desc = "战乱连年又时逢旱灾，山下的难民也越来越多，听闻鬼谷之中有一片沃土，鬼谷子师父交付的第一个任务——收集粮草，帮助山下难民，然而山上的山贼也盯上了这片沃土，要想办法阻止他们抢夺粮草才行….",
            keypoints = "【参数】【基本语法】【字符串】【while循环】",
            mapRegion = {min={19419,8,19213}, size={50, 50}},
            sceneFile = "blocktemplates/2level4.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/Area_FrostRoarIsland.ogg",
            chapter=2,
            index=4,
        },
        {
            name="鬼谷试炼二", x=766, y=225, status = config.Locked, 
            pos = getCodePos2(0, -5, true),
            desc = "山贼没能掠夺到沃土的粮草，一定心有不甘，最近下山的路上总有山贼拦路抢劫，鬼谷子交付的第二个任务——消灭劫道的贼人，将粮草送至难民手中，可单凭现在自身的力量，可能无法与山贼正面对抗…",
            keypoints = "【参数】【基本语法】【字符串】",
            mapRegion = {min={19415,8,19212}, size={50, 50}},
            sceneFile = "blocktemplates/2level5.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            chapter=2,
            index=5,
        },
        {
            name="鬼谷试炼三", x=675, y=200, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "掠夺沃土未果，拦截粮草又受挫，山贼想必不会善罢甘休，而山下的村庄一定会是他们的矛头所指，果不其然，昔日并肩作战的猎人发来了求救信，这一次，游侠为了报恩决定伸出援手，三人协力能否化险为夷呢？",
            keypoints = "【参数】【基本语法】【字符串】【while循环】",
            mapRegion = {min={19419,8,19216}, size={50, 50}},
            sceneFile = "blocktemplates/2level6.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            chapter=2,
            index=6,
        },
        {
            name="村长的回信", x=745, y=155, status = config.Locked, 
            pos = getCodePos2(0, -5, true),
            desc = "在游侠和猎人的协助下，成功的抵御了进犯的山贼，保卫了村庄的安全，为此村长特意写了一封感谢信给鬼谷子师父，这封信也是对鬼谷试炼完成的肯定，既然已经完成了试炼，就尽快返回面见师父吧~",
            keypoints = "【参数】【基本语法】【字符串】",
            mapRegion = {min={19419,8,19212}, size={50, 50}},
            sceneFile = "blocktemplates/2level7.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_FrostRoarIsland.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkPlain.ogg",
            chapter=2,
            index=7,
        },
        {
            name="遗失的章节", x=857, y=145, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "收到村长的感谢信后，鬼谷子师父对试炼的结果十分满意，并将《孙子兵法》残卷相赠，同时告知了兵法的来历和重要性，可有很多遗失的章节仍然流落在外，现在鬼谷子师父探知了有兵法残卷就散落在这鬼谷之中...",
            keypoints = "【参数】【基本语法】【字符串】",
            mapRegion = {min={19419,8,19217}, size={50, 50}},
            sceneFile = "blocktemplates/2level8.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkforest.ogg",
            chapter=2,
            index=8,
        },
        {
            name="误入埋伏", x=1062, y=155, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "虽然巧妙的将两卷《孙子兵法》收集到手，但喜出望外时，却没料到山贼已经埋伏在返程的路上，若不是游侠及时赶到告知了这个消息，恐怕这次在劫难逃，有了游侠的协助，或许能够躲过敌人的伏击？",
            keypoints = "【参数】【基本语法】【字符串】",
            mapRegion = {min={19419,8,19214}, size={50, 50}},
            sceneFile = "blocktemplates/2level9.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkforest.ogg",
            chapter=2,
            index=9,
        },
        {
            name="游侠的指引", x=1164, y=230, status = config.Locked, 
            pos = getCodePos2(0, -5, true),
            desc = "崎岖的山路充满着未知的危险，无论是草丛中隐藏的捕兽夹，还是埋伏在路侧的山贼，都有可能让孙膑再次身陷危险之中，不过幸好游侠来的时候已经探索出一条安全的道路，紧跟猎人的步伐，才能到达终点…",
            keypoints = "【参数】【基本语法】【字符串】【变量】",
            mapRegion = {min={19419,8,19215}, size={50, 50}},
            sceneFile = "blocktemplates/2level10.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=10,
        },
        {  
            name="重返鬼谷", x=1210, y=355, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "这段返回鬼谷的路程并不算远，但却险象环生，虽然跟随游侠避免了很多麻烦，但一不小心还是落开了距离，前方又有山贼的营地，想办法在阻止山贼追赶的前提下，尽快赶上游侠，再跟着他的指引向终点进发！ ",
            keypoints = "【参数】【基本语法】【字符串】【变量】",
             mapRegion = {min={19419,8,19215}, size={50, 50}},
            sceneFile = "blocktemplates/2level11.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=11,
        },
        {
            name="武学修炼一", x=1042, y=310, status = config.Locked, 
            pos = getCodePos2(0, -5, true),
            desc = "即使有了剑术秘籍的帮助，以及游侠的指导，但技艺生疏的情况下还是不能轻举妄动，游侠多次探查终于发现了一个落单的山贼，也许这正是练手的好时机，快赶往游侠所在的位置吧！",
            keypoints = "【参数】【基本语法】【字符串】【变量】",
            mapRegion = {min={19419,8,19213}, size={50, 50}},
            sceneFile = "blocktemplates/2level12.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=12,
        },
        {
            name="武学修炼二", x=872, y=310, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "经过了一天对新攻击方式的训练，又有剑术秘籍的帮助和游侠的指导，孙膑的武学技艺已经有了不小的提升，转眼间天色已晚，游侠不经意间发现了一间密室，正好可以挨过山中的漫漫寒夜…",
            keypoints = "【参数】【基本语法】【字符串】【变量】",
            mapRegion = {min={19419,8,19213}, size={50, 50}},
            sceneFile = "blocktemplates/2level13.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_DarkForestIsland.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkForestSea.ogg",
            chapter=2,
            index=13,
        },
        {
            name="武学修炼三", x=779, y=315, status = config.Locked, 
            pos = getCodePos2(0, -5, true),
            desc = "在新的攻击方式已经能够熟练运用的时候，不妨去探查一下山贼的活动，游侠近来发觉山贼要运送抢到的粮草到山寨，如果让他们得逞，山贼的势力恐怕会扩大，一定要想办法阻止他们，截获粮草！",
            keypoints = "【参数】【基本语法】【字符串】",
            mapRegion = {min={19419,8,19216}, size={50, 50}},
            sceneFile = "blocktemplates/2level14.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=14,
        },
        {
            name="山贼的阴谋", x=675, y=325, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "武学修炼归来，对于新的攻击方式和技巧，孙膑已是能够熟练运用，而这段时间里，鬼谷子师父也对鬼谷突然出现的山贼作了调查，原来他们真正的目的是搜集和掠夺鬼谷之中的《孙子兵法》…",
            keypoints = "【参数】【基本语法】【字符串】【变量】",
            mapRegion = {min={19419,8,19214}, size={50, 50}},
            sceneFile = "blocktemplates/2level15.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Combat_Teen_Common_TrialVersion.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambGrassland.ogg",
            chapter=2,
            index=15,
        },
        {
            name="计策关：隔岸观火", x=660, y=395, status = config.Locked, 
            pos = getCodePos2(0, -5, true),
            desc = "【隔岸观火比喻置身事外，对别人的危难不去救助，采取袖手旁观的态度。】 既然山贼意在掠夺兵法，不如用兵法设计勾引山贼陷入埋伏，以此削弱山贼的势力，从而保护鬼谷中的平民。",
            keypoints = "【参数】【基本语法】【while循环】【字符串】【变量】",
            mapRegion = {min={19419,8,19213}, size={50, 50}},
            sceneFile = "blocktemplates/2level16.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambGrassland.ogg",
            chapter=2,
            index=16,
        },
        {
            name="山寨突破口", x=761, y=435, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "计策“隔岸观火”的成功使用，大大削弱了山贼的势力，山寨的外围防守力量也减少了很多，现在正是夺回被掠夺的兵法残卷的好时机，游侠经过探查，发现了一条隐蔽的小道，也许正是山寨的突破口… ",
            keypoints = "【参数】【基本语法】【字符串】【变量】",
            mapRegion = {min={19419,8,19211}, size={50, 50}},
            sceneFile = "blocktemplates/2level17.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=17,
        },
        {
            name="潜在的危险", x=946, y=445, status = config.Locked, 
            pos = getCodePos2(0, -5, true),
            desc = "通过小路顺利的进入到了山寨内部，此时山贼大多注重于山寨外围的防御，内部反倒没有太多的贼人，然而千万不能掉以轻心，敌人可能会不经意间出现在某个地方，如果发现敌人的踪迹一定要将其消灭…",
            keypoints = "【参数】【基本语法】【字符串】【变量】【if语句】",
            mapRegion = {min={19419,8,19214}, size={50, 50}},
            sceneFile = "blocktemplates/2level18.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_FrostRoarIsland.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkPlain.ogg",
            chapter=2,
            index=18,
        },
        {
            name="截断通信", x=1040, y=445, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "尽管游侠尽力守住入口，但还是有几个山贼溜了进来，如果他们向山寨大营通风报信，那么不仅夺回的兵法残卷又将不保，连孙膑和游侠也将陷入危险的境地，所以一定要拦截并消灭报信的山贼！",
            keypoints = "【参数】【基本语法】【字符串】【变量】【while循环】【if语句】",
            mapRegion = {min={19419,8,19217}, size={50, 50}},
            sceneFile = "blocktemplates/2level19.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkforest.ogg",
            chapter=2,
            index=19,
        },
        {
            name="密地之门", x=1115, y=450, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "为了尽量躲开山贼的视野，孙膑走向了一条隐蔽的小道，而小道的尽头是一道坚固的大门，这大门后面，会不会就是山贼储藏掠夺而来的天书残卷的密地呢，不过首先要耗点时间打开大门…  ",
            keypoints = "【参数】【基本语法】【字符串】【变量】【while循环】【if语句】",
            mapRegion = {min={19419,8,19221}, size={50, 50}},
            sceneFile = "blocktemplates/2level20.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkforest.ogg",
            chapter=2,
            index=20,
        },
        {
            name="山贼的秘密一", x=1136, y=535, status = config.Locked, 
            pos = getCodePos2(0, -5, true),
            desc = "打开并通过大门后，终于来到了山寨中隐蔽的密地，然而眼前的景象却出乎人的意料，这里的一切都显得井然有序以致看起来不像是山贼的巢穴，倒像是……，然而现在还来不及多想，巡逻的山贼马上就会到达…",
            keypoints = "【参数】【基本语法】【字符串】【变量】【while循环】【if语句】",
            mapRegion = {min={19419,8,19217}, size={50, 50}},
            sceneFile = "blocktemplates/2level21.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkforest.ogg",
            chapter=2,
            index=21,
        },
        {
            name="山贼的秘密二", x=1010, y=540, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "夜幕降临，然而寻求兵法残卷的脚步却不能停歇，功夫不负有心人，趁着夜色深入密地后，相继发现了不少的兵法残卷，但敌人也像是有所防备，在残卷周围，布置了不少的陷阱，所以收集时一定要多加小心…",
            keypoints = "【参数】【基本语法】【字符串】【变量】【while循环】【if语句】",
            mapRegion = {min={19419,8,19216}, size={50, 50}},
            sceneFile = "blocktemplates/2level22.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_FrostRoarIsland.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkPlain.ogg",
            chapter=2,
            index=22,
        },
        {
            name="山贼的秘密三", x=928, y=555, status = config.Locked, 
            pos = getCodePos2(0, -5, true),
            desc = "密地的尽头，是敌人的大营，营寨外赫然飘着秦国的军旗，孙膑料想鬼谷之中突然出现的山贼必定和秦国军队有什么联系，然而现在还是抓紧夺回兵法残卷要紧，同时也要注意不能让巡逻的敌人逃脱去报信！",
            keypoints = "【参数】【基本语法】【字符串】【变量】【while循环】【if语句】",
            mapRegion = {min={19419,8,19213}, size={50, 50}},
            sceneFile = "blocktemplates/2level23.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_FrostRoarIsland.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkPlain.ogg",
            chapter=2,
            index=23,
        },    
        {
            name="满载而归", x=837, y=555, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "想不到这次出其不意的山寨探查，不仅夺回了大量兵法残卷，还探知了鬼谷中山贼的秘密，这一趟可谓是收获颇丰，而现在还不到庆祝的时候，趁着夜色，赶快想办法返回鬼谷学堂，才算是满载而归…",
            keypoints = "【参数】【基本语法】【字符串】【变量】【if语句】",
            mapRegion = {min={19419,8,19216}, size={50, 50}},
            sceneFile = "blocktemplates/2level24.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_DarkForestIsland.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambDarkForestSea.ogg",
            chapter=2,
            index=24,
        },
        {
            name="路遇信使", x=760, y=540, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "返回鬼谷的途中，偶然间遇到了一个身着魏国军装的信使，但他像是遇到了些麻烦，想必是因为对路况不熟悉，才在鬼谷之中迷失了方向，既然是魏国信使来到鬼谷，想必是有要事，还是帮他走出困境吧…",
            keypoints = "【参数】【基本语法】【字符串】【变量】【if语句】",
            mapRegion = {min={19415,8,19212}, size={50, 50}},
            sceneFile = "blocktemplates/2level25.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Combat_Teen_Common_TrialVersion.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambGrassland.ogg",
            chapter=2,
            index=25,
        },
         {
            name="师弟的来信", x=694, y=495, status = config.Locked, 
            pos = getCodePos2(0, -5, true),
            desc = "从信使那里得知，师弟庞涓现在已经是魏国的大将军了，信使正是奉了他的命令送信到鬼谷，而收信人正是孙膑，前有山贼的秘密，后有师弟的来信，诸多事宜，还是先赶回鬼谷学堂请教鬼谷子师父吧！",
            keypoints = "【参数】【基本语法】【字符串】【变量】【if语句】【函数】",
            mapRegion = {min={19419,8,19214}, size={50, 50}},
            sceneFile = "blocktemplates/2level26.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Combat_Teen_Common_TrialVersion.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambGrassland.ogg",
            chapter=2,
            index=26,
        }, 
        {
            name="守卫学堂", x=435, y=335, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "在返回鬼谷的路上，得到了山贼意图袭击鬼谷学堂，抢夺兵法的消息，虽然游侠已经在学堂外抵挡了一部分山贼，但仍有潜入学堂周围的敌人，这次，还能否击败进犯的山贼，守卫鬼谷学堂的安全呢？",
            keypoints = "【参数】【基本语法】【字符串】【while循环】【变量】【if语句】【函数】",
            mapRegion = {min={19419,8,19214}, size={50, 50}},
            sceneFile = "blocktemplates/2level27.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=27,
        },
        {
            name="告别鬼谷", x=324, y=315, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "离开鬼谷的路途中，孙膑发现鬼谷中果然少有山贼活动了，难道真如师父所说，山贼开始撤出鬼谷了？但现在还不能掉以轻心，漫漫下山路，很难保证不会有突发情况发生，还是小心为好…",
            keypoints = "【参数】【基本语法】【字符串】【变量】【if语句】【函数】",
            mapRegion = {min={19419,8,19214}, size={50, 50}},
            sceneFile = "blocktemplates/2level28.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=28,
        },
        {
            name="下山之路", x=220, y=305, status = config.Locked, 
            pos = getCodePos2(0, -5, true),
            desc = "“没有永远的敌人，反之亦然”孙膑若有所思，下山的路上，孙膑愈发感觉师父这句话是在提示着自己什么，随着天色渐晚，可能出现的狼群以及还未完全撤走的山贼，不得不让孙膑停止了思考，专心赶路…",
            keypoints = "【参数】【基本语法】【字符串】【变量】【if语句】【函数】",
            mapRegion = {min={19419,8,19214}, size={50, 50}},
            sceneFile = "blocktemplates/2level29.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=29,
        }, 
        {
            name="计策关：笑里藏刀", x=181, y=395, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "【笑里藏刀意思是对人外表和气，内心却阴险毒辣。】身陷埋伏的孙膑，终于相信了游侠信上的内容，并想起信上提到，如果进了城，务必想办法到城中大院后门处，游侠会帮助他暂避危险…",
            keypoints = "【参数】【基本语法】【字符串】【变量】【if语句】【函数】",
            mapRegion = {min={19419,8,19215}, size={50, 50}},
            sceneFile = "blocktemplates/2level30.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=30,
        },
        {
            name="逃离危城", x=398, y=425, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "虽然在游侠的帮助下，获得了喘息的机会，但想必城中杀手用不了多久就会找上门来，想要逃出生天，必须想办法逃出这座危机四伏的古城，虽然困难重重，但好在有游侠相助，增加了许多生机。",
            keypoints = "【参数】【基本语法】【字符串】【变量】【if语句】【函数】",
            mapRegion = {min={19419,8,19212}, size={50, 50}},
            sceneFile = "blocktemplates/2level31.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=31,
        },
        {
            name="渡人渡己", x=335, y=465, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "由于对山下的路况并不熟悉，加上逃亡时十分匆忙，孙膑逃出危城后就和游侠走散了，慌不择路中来到了一处刚刚经历过战乱的村落，村中有许多受伤的平民，想办法救助他们吧，也许这对自己也有帮助…",
            keypoints = "【参数】【基本语法】【字符串】【变量】【if语句】【函数】",
            mapRegion = {min={19419,8,19213}, size={50, 50}},
            sceneFile = "blocktemplates/2level32.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=32,
        },
        {
            name="峡谷险情", x=236, y=470, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "峡谷中青山绿水，风景秀丽，孙膑紧张的心情在此得到了一些舒缓，然而这一片宁静的风光背后已然暗藏杀机，几个探路的杀手已经到达了这里，必须要消灭他们，不然势必会引来更多敌人！",
            keypoints = "【参数】【基本语法】【字符串】【while循环】【变量】【if语句】【函数】",
            mapRegion = {min={19419,8,19214}, size={50, 50}},
            sceneFile = "blocktemplates/2level33.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=33,
        },
        {
            name="有的放矢", x=182, y=525, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "穿过峡谷后视野豁然开朗，眼前萧瑟的树林中，交错的道路上，想必还有困难和危险在等着，然而现在已经没有退路了，但到底那条路线才是最合适的呢，正在孙膑迟疑时，道路的尽头传来了游侠熟悉的声音…",
            keypoints = "【参数】【基本语法】【字符串】【变量】【if语句】【函数】",
            mapRegion = {min={19416,8,19211}, size={50, 50}},
            sceneFile = "blocktemplates/2level34.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=34,
        },
        {
            name="抵达国都", x=395, y=575, status = config.Locked,
            pos = getCodePos2(0, -5, true),
            desc = "历经艰险终于看到了远处巍然的国都城池，然而这最后一段路千万不能掉以轻心，庞涓想必会在这里设下最后一道埋伏，不过还好这次有游侠相助，只要齐心合力，一定能突破埋伏，抵达国都！",
            keypoints = "【参数】【基本语法】【字符串】【变量】【if语句】【函数】",
            mapRegion = {min={19416,8,19213}, size={50, 50}},
            sceneFile = "blocktemplates/2level35.blocks.xml",
            bgm = "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg",
            sound1 = "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg",
            chapter=2,
            index=35,
        },
    },

    --levels of chapter3
    {

    }, 
    
    --levels of chapter4
    {

    }, 
}

local chapters = {
    {
        name="求学之旅",
        x = 110,
        y = 250,
        total = 0,
        passed = 0,
        status = config.Locked,
        gsid = 30251,
    },
    {
        name="新的征程",
        x = 110 + 165 * 1,
        y = 250,
        total = 0,
        passed = 0,
        status = config.Locked,   
        gsid = 30252,
    },
    {
        name="牛刀小试",
        x = 110 + 165 * 2,
        y = 250,
        total = 0,
        passed = 0,
        status = config.Locked,   
        gsid = 30253,
    },
    {
        name="牛刀小试",
        x = 110 + 165 * 3,
        y = 250,
        total = 0,
        passed = 0,
        status = config.Locked,   
        gsid = 30254,
    },
}


function config.getChapters()
    return chapters;
end

function config.getLevelsInChapter(index)
    if (index < 1 or index > #levels) then
        return
    end
    return levels[index];
end

local function getItemMax(gsid)
    local template = KeepWorkItemManager.GetItemTemplate(gsid);
    if (template) then
        return template.holdingLimit or 0;
    else
        return 0;
    end
end

local function getItemCount(gsid)
    local bOwn, guid, bag, copies = KeepWorkItemManager.HasGSItem(gsid);
    copies = copies or 0;
    return copies;
end

function config.isLogin()
    return KeepworkService:IsSignedIn();
end

function config.getUserName()
    return System.User.username;
end

function config.isVip()
    return System.User.isVip;
end

function config.isVipOrHasPermission(callback)
    if config.isVip() then
        callback(true)
        return
    end

    GameLogic.IsVip("VipCodeGameArtOfWar", false, function(result)
        if (result) then
            callback(true)
        else
            callback(false)
        end
    end);
end

function config.isTeacher()
    local userType = System.User.userType;
    return userType and userType.teacher;
end

function config.isStudent()
    local userType = System.User.userType;
    return userType and userType.student;
end

function config.isOrganizationAdmin()
    local userType = System.User.userType;
    return userType and userType.orgAdmin;
end

function config.onLogin(callback)
    KeepWorkItemManager.GetFilter():add_filter("loaded_all", function()
        KeepWorkItemManager.GetFilter():remove_all_filters("loaded_all");
        
        config.receiveTicket(function()
            config.load(function()
                if (callback) then
                    callback();
                end
            end);
        end);
    end);
    LoginModal:Init();
end

function config.receiveTicket(ticketCallback, levelCallback)
    KeepWorkItemManager.CheckExchange(config.ticketExid, function(canExchange)
        if (canExchange.data and canExchange.data.ret == true) then
            KeepWorkItemManager.DoExtendedCost(config.ticketExid, function()
                if (levelCallback) then
                    KeepWorkItemManager.DoExtendedCost(config.levelExid, function()
                        levelCallback();
                    end);
                elseif (ticketCallback) then
                    ticketCallback();
                end
            end, function(err, msg, data)
                if (ticketCallback) then
                    ticketCallback();
                end
            end);
        elseif (ticketCallback) then
            ticketCallback();
        end
    end, function(canExchange)
        if (ticketCallback) then
            ticketCallback();
        end
    end);
end

local init = false;

function config.OnKeepWorkLogin_Callback()
    KeepWorkItemManager.GetFilter():add_filter("loaded_all", function()
        KeepWorkItemManager.GetFilter():remove_all_filters("loaded_all");
        
        config.receiveTicket(function()
            config.load(function()
                game.ui.chapter.refresh();
            end);
        end);
    end);
end

function config.OnKeepWorkLogout_Callback()
    config.reset();
    game.ui.chapter.refresh();
end

function config.reset()
    for i, chapter in ipairs(chapters) do
        chapter.total = 0;
        chapter.passed = 0;
        chapter.status = config.Locked;

        local levelsinchapter = levels[i];
        for j, level in ipairs(levelsinchapter) do
            level.status = config.Locked;
        end
    end
    KeepWorkItemManager.SetClientData(config.levelGsid, {});
end

function config.load(callback, receive)
    if (not init) then
        init = true;
        GameLogic.GetFilters():add_filter("OnKeepWorkLogin", config.OnKeepWorkLogin_Callback);
        GameLogic.GetFilters():add_filter("OnKeepWorkLogout", config.OnKeepWorkLogout_Callback);
    end
    -- must login before loading keepworkitems
    if (not game.config.isLogin()) then
        if (callback) then
            callback();
        end
        return;
    end

    local function loadChaptersAndLevels()
        for i, chapter in ipairs(chapters) do
            chapter.total = getItemMax(chapter.gsid) or 0;
            if i == 1 and chapter.passed == 1 then--特殊处理试试
                chapter.passed = chapter.passed or 1
                --print("chapter.passed")
            else
                chapter.passed = config.getChapterPassed(i) or 0;
            end
            
            if (i > 1) then
                local last = chapters[i-1];
                if (last.total == last.passed and last.total > 0) then
                    last.status = config.Passed;
                    if (chapter.total > 0) then
                        chapter.status = config.Open;
                    else
                        chapter.status = config.Locked;
                    end
                else
                    chapter.status = config.Locked;
                end
            else
                chapter.status = config.Open;
            end
    
            local levelsinchapter = levels[i];
            for j, level in ipairs(levelsinchapter) do
                if (j > chapter.passed + 1) then
                    level.status = config.Locked;
                elseif (j > chapter.passed) then
                    level.status = config.Open;
                else
                    level.status = config.Passed;
                end
                if i == 1 then
                 --print("loadChaptersAndLevels" , j , level.status)
                end
                level.hasPassCode = config.getLevelPassCode(level) or config.isVip();
            end
        end

        if (callback) then
            callback();
        end
        broadcast("update_level_data")
    end

    if (receive) then
        game.config.receiveTicket(loadChaptersAndLevels);
        --[[
        if (getItemCount(config.levelGsid) < 1) then
            game.config.receiveTicket(nil, loadChaptersAndLevels);
        else
            game.config.receiveTicket(loadChaptersAndLevels);
        end
        ]]
    else
        loadChaptersAndLevels();
    end
end

function config.exchangeLevel(level)
    local function setData(level)
        local clientData = KeepWorkItemManager.GetClientData(config.levelGsid) or {};
        local key = format("chapter%d_passed", level.chapter);
        local pass = clientData[key] or 0;
        
        if (level.index > pass) then
            local DailyTaskManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DailyTask/DailyTaskManager.lua");
            if DailyTaskManager then
                DailyTaskManager.AchieveTask(DailyTaskManager.task_id_list.Classroom)
            end
            clientData[key] = level.index;
            KeepWorkItemManager.SetClientData(config.levelGsid, clientData);
        end
    end
    
    if (getItemCount(config.levelGsid) < 1) then
        KeepWorkItemManager.DoExtendedCost(config.levelExid, function()
            setData(level);
            config.load();
        end );
    else
        setData(level);
        config.load();
    end
end

function config.getChapterPassed(chapter)
    if (chapter) then
        local clientData = KeepWorkItemManager.GetClientData(config.levelGsid) or {};
        local key = format("chapter%d_passed", chapter);
        --print("config.getChapterPassed" , key , clientData[key])
        return clientData[key];
    end
end

function config.exchangeTipInfo(level, callback)
    if (level and level.chapter and level.index) then
        KeepWorkItemManager.DoExtendedCost(config.tipinfoExid, function()
            local tipClientData = KeepWorkItemManager.GetClientData(config.tipinfoGsid) or {};
            local key = format("chapter%d_level%d", level.chapter, level.index);
            tipClientData[key] = true;
            KeepWorkItemManager.SetClientData(config.tipinfoGsid, tipClientData);
            config.load();
            level.hasPassCode = true;
            if (callback) then
                callback();
            end
        end);
    end
end

function config.getLevelPassCode(level)
    if(level) then
        local clientData = KeepWorkItemManager.GetClientData(config.tipinfoGsid) or {};
        local key = format("chapter%d_level%d", level.chapter, level.index);
        return clientData[key];
    end
end

function config.setLevelClientData(level)
    if(level) then
        local entity = getBlockEntity(level.pos[1],level.pos[2],level.pos[3])
        if(entity) then
            --print("setLevelClientData111111111111111111111111111111")
            local clientData = KeepWorkItemManager.GetClientData(config.levelGsid) or {};
            local key = format("chapter%d_level%d", level.chapter, level.index);

            local code = entity:GetNPLCode();
            NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
            local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
            local textCtrl = CodeBlockWindow.GetTextControl();     
            if(textCtrl)then
                code = textCtrl:GetText();
            end
            --print("setLevelClientData222222222222222222222222222222222222222222")
            if (code ~= clientData[key]) then
                clientData[key] = code;
                KeepWorkItemManager.SetClientData(config.levelGsid, clientData);
                --print("setLevelClientData" , clientData)
            end
        end
    end
end

function config.getLevelClientData(level)
    if(level) then
        local clientData = KeepWorkItemManager.GetClientData(config.levelGsid) or {};
        local key = format("chapter%d_level%d", level.chapter, level.index);
        return clientData[key];
    end
end

function config.getTicketCount()
    return getItemCount(config.ticketGsid);
end

function config.getTicketMax()
    return getItemMax(config.ticketGsid);
end