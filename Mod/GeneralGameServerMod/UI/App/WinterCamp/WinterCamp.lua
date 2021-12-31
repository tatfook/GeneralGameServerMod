
local Enitiy = require("Entity");
local Movie = require("Movie");
local __winter_camp__ = {};

-- 垃圾分类任务配置
local LaJiFenLeiMovieTasks = {
    -- targetPos 电影触发方块坐标   teleportPos 玩家传送方块坐标   moviePos 电影方块坐标 
    {targetPos = {18139,12,18985}, teleportPos = {18141,12,18985}, moviePos = {18165,2,19164}, state = 0, text = "电影一", title = "厨余垃圾介绍"},
    {targetPos = {18226,12,19010}, teleportPos = {18224,12,19009}, moviePos = {18165,2,19162}, state = 0, text = "电影二", title = "可回收物后续处理"},
    {targetPos = {18213,12,19015}, teleportPos = {18211,12,19015}, moviePos = {18165,2,19160}, state = 0, text = "电影三", title = "可回收物介绍"},
    {targetPos = {18075,12,18949}, teleportPos = {18073,12,18949}, moviePos = {18165,2,19158}, state = 0, text = "电影四", title = "厨余垃圾后续处理"},
    {targetPos = {18245,12,18980}, teleportPos = {18243,12,18980}, moviePos = {18165,2,19156}, state = 0, text = "电影五", title = "有害垃圾后续处理"},
    {targetPos = {18138,12,19021}, teleportPos = {18142,12,19021}, moviePos = {18165,2,19154}, state = 0, text = "电影六", title = "其他垃圾介绍"},
    {targetPos = {18088,12,19037}, teleportPos = {18086,12,19037}, moviePos = {18165,2,19152}, state = 0, text = "电影七", title = "其他垃圾后续处理"},
    {targetPos = {18213,12,18981}, teleportPos = {18211,12,18981}, moviePos = {18165,2,19150}, state = 0, text = "电影八", title = "有害垃圾介绍"},
}

-- 课程任务配置
local KeChengTasks = {
    -- 趣味编程
    ["quweibiancheng"] = {
        {teleportPos = {18121,21,19427}, state = 0, text = "第一课", title = "初级跑步训练", subtitle = "前进与说话"},
        {teleportPos = {18117,21,19427}, state = 0, text = "第二课", title = "跨越障碍", subtitle = "位移"},
        {teleportPos = {18113,21,19427}, state = 0, text = "第三课", title = "初级游泳训练", subtitle = "朝向旋转"},
        {teleportPos = {18109,21,19427}, state = 0, text = "第四课", title = "游泳技巧训练", subtitle = "朝向改变"},
        {teleportPos = {18105,21,19427}, state = 0, text = "第五课", title = "跑步跨栏", subtitle = "做出动作"},
        {teleportPos = {18101,21,19427}, state = 0, text = "第六课", title = "高级跑步入门", subtitle = "条件与触碰感知"},
        {teleportPos = {18097,21,19427}, state = 0, text = "第七课", title = "跳远训练", subtitle = "条件与触碰感知"},
        {teleportPos = {18093,21,19427}, state = 0, text = "第八课", title = "体育场馆寻路", subtitle = "高级条件"},
        {teleportPos = {18089,21,19427}, state = 0, text = "第九课", title = "跑步绕圈", subtitle = "循环"},
        {teleportPos = {18085,21,19427}, state = 0, text = "第十课", title = "越野跑步训练", subtitle = "循环与高级条件"},
    }, 
    -- 快乐建造
    ["kuailejianzao"] = {
        {teleportPos = {18122,20,19356}, state = 0, text = "第一课", title = "建造前的准备", subtitle = "工具栏的相关知识"},
        {teleportPos = {18117,20,19356}, state = 0, text = "第二课", title = "清除跑道杂物", subtitle = "删除方块操作"},
        {teleportPos = {18113,20,19356}, state = 0, text = "第三课", title = "填补路面空缺", subtitle = "放置方块操作"},
        {teleportPos = {18109,20,19356}, state = 0, text = "第四课", title = "修整跳远沙坑", subtitle = "吸取与替换方块操作"},
        {teleportPos = {18105,20,19356}, state = 0, text = "第五课", title = "更新滑冰场", subtitle = "选中方块操作"},
        {teleportPos = {18101,20,19356}, state = 0, text = "第六课", title = "移动和旋转跳台", subtitle = "移动和旋转操作"},
        {teleportPos = {18097,20,19356}, state = 0, text = "第七课", title = "镜像马拉松赛场", subtitle = "镜像的使用方法"},
        {teleportPos = {18093,20,19356}, state = 0, text = "第八课", title = "安装休息室灯光", subtitle = "特殊方块的使用"},
        {teleportPos = {18089,20,19356}, state = 0, text = "第九课", title = "保存场馆设施", subtitle = "保存模板或模型的方法"},
        {teleportPos = {18085,20,19356}, state = 0, text = "第十课", title = "创造地标建筑", subtitle = "常用建造指令的运用"},
    },
    -- 精彩动画
    ["jingcaidonghua"] = {
        {teleportPos = {18182,12,19191}, state = 0, text = "第一课", title = "建造前的准备", subtitle = "工具栏的相关知识"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第二课", title = "清除跑道杂物", subtitle = "删除方块操作"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第三课", title = "填补路面空缺", subtitle = "放置方块操作"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第四课", title = "修整跳远沙坑", subtitle = "吸取与替换方块操作"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第五课", title = "更新滑冰场", subtitle = "选中方块操作"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第六课", title = "移动和旋转跳台", subtitle = "移动和旋转操作"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第七课", title = "镜像马拉松赛场", subtitle = "镜像的使用方法"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第八课", title = "安装休息室灯光", subtitle = "特殊方块的使用"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第九课", title = "保存场馆设施", subtitle = "保存模板或模型的方法"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第十课", title = "创造地标建筑", subtitle = "常用建造指令的运用"},
    },
}

-- 体育竞赛
local TiYuJingSaiTasks = {
    {teleportPos = {18312,12,19115}, state = 0, text = "跨栏", description = "在撞上栏杆前，按顺序准确输入字母，即可完成跨栏"},
    {teleportPos = {18310,12,19290}, state = 0, text = "射箭", description = "按下鼠标右键并拖动，瞄准箭靶后，松开右键发射弓箭"},
    {teleportPos = {18343,12,18980}, state = 0, text = "记忆比拼", description = ""},
    {teleportPos = {18383,12,19350}, state = 0, text = "短道竞技", description = ""},
}

-- 证书配置
local CertConfig = {
    ["quweibiancheng"] = {
        cert_img = "@/wintercamp/certs/biancheng_512x368_32bits.png#0 0 512 368",         -- 证书图片路径
        reward_img = "@/wintercamp/certs/biancheng_230x128_32bits.png#0 0 230 128",       -- 奖励图片路径
        suit_img = "@/wintercamp/certs/suit_175x215_32bits.png#0 0 175 215",              -- 套装图片路径
        cert_gsid = "70021",                                                              -- 证书物品ID
        cert_exid = "30062",                                                              -- 兑换物品ID
        cert_name = "冬令营-编程小达人证书",
    },
    ["kuailejianzao"] = {
        cert_img = "@/wintercamp/certs/jianzao_512x368_32bits.png#0 0 512 368",         -- 证书图片路径
        reward_img = "@/wintercamp/certs/jianzao_230x128_32bits.png#0 0 230 128",       -- 奖励图片路径
        suit_img = "@/wintercamp/certs/suit_175x215_32bits.png#0 0 175 215",              -- 套装图片路径
        cert_gsid = "70018",                                                              -- 证书物品ID
        cert_exid = "30059",                                                              -- 兑换物品ID
        cert_name = "冬令营-优秀建造师证书",
    },
    ["jingcaidonghua"] = {
        cert_img = "@/wintercamp/certs/donghua_512x368_32bits.png#0 0 512 368",         -- 证书图片路径
        reward_img = "@/wintercamp/certs/donghua_230x128_32bits.png#0 0 230 128",       -- 奖励图片路径
        suit_img = "@/wintercamp/certs/suit_175x215_32bits.png#0 0 175 215",              -- 套装图片路径
        cert_gsid = "70020",                                                              -- 证书物品ID
        cert_exid = "30061",                                                              -- 兑换物品ID
        cert_name = "冬令营-动画小导演证书",
    }, 
    ["lajifenlei"] = {
        cert_img = "@/wintercamp/certs/huanbao_512x368_32bits.png#0 0 512 368",         -- 证书图片路径
        reward_img = "@/wintercamp/certs/huanbao_230x128_32bits.png#0 0 230 128",       -- 奖励图片路径
        suit_img = "@/wintercamp/certs/suit_175x215_32bits.png#0 0 175 215",              -- 套装图片路径
        cert_gsid = "70017",                                                              -- 证书物品ID
        cert_exid = "30058",                                                              -- 兑换物品ID
        cert_name = "冬令营-环保卫士证书",
    },
    ["tiyujinsai"] = {
        cert_img = "@/wintercamp/certs/tiyu_512x368_32bits.png#0 0 512 368",         -- 证书图片路径
        reward_img = "@/wintercamp/certs/tiyu_230x128_32bits.png#0 0 230 128",       -- 奖励图片路径
        suit_img = "@/wintercamp/certs/suit_175x215_32bits.png#0 0 175 215",              -- 套装图片路径
        cert_gsid = "70019",                                                              -- 证书物品ID
        cert_exid = "30060",                                                              -- 证书兑换ID
        cert_name = "冬令营-体育健将证书",
    },
}

local function GetCert(index)
    local cfg = CertConfig[index];
    if (not cfg) then return end 
    print(string.format("恭喜获得%s证书", cfg.cert_name));
    local owned = KeepWorkItemManager.HasGSItem(cfg.cert_gsid);
    if (owned) then return end 
    KeepWorkItemManager.DoExtendedCost(cfg.cert_exid, function()
        Tip(string.format("恭喜获得%s证书", cfg.cert_name));
    end);
end

local function CheckAndGetCert()
    local isAllFinish = true;
    for index, task in ipairs(LaJiFenLeiMovieTasks) do
        if (task.state == 0) then 
            isAllFinish = false;
            break;
        end 
    end
    if (isAllFinish) then GetCert("lajifenlei") end
    
    isAllFinish = true;
    for _, task in ipairs(TiYuJingSaiTasks) do
        if (task.state == 0) then 
            isAllFinish = false;
            break;
        end
    end
    if (isAllFinish) then GetCert("tiyujinsai") end

    for _, index in ipairs({"quweibiancheng", "kuailejianzao", "jingcaidonghua"}) do
        isAllFinish = true;
        local tasks = KeChengTasks[index];
        for _, task in ipairs(tasks) do
            if (task.state == 0) then 
                isAllFinish = false;
                break;
            end
        end
        if (isAllFinish) then GetCert(index) end
    end
end

function InitTasks()
    local __ClientData__ = KeepWorkItemManager.GetClientData(40008) or {};
    local refuseClassificationData = __ClientData__.refuseClassificationData or {};
    __ClientData__.refuseClassificationData = refuseClassificationData;
    for index, task in ipairs(LaJiFenLeiMovieTasks) do
        task.state = refuseClassificationData[index] or 0;
        task.movie = task.movie or Movie:new():Init(task.moviePos[1], task.moviePos[2], task.moviePos[3]);
        task.circle = task.circle or Enitiy:new():Init({
            bx = task.targetPos[1], by = task.targetPos[2], bz = task.targetPos[3],
            assetfile = "character/CC/05effect/fireglowingcircle.x",
        });
        task.arrow = task.arrow or Enitiy:new():Init({
            bx = task.targetPos[1], by = task.targetPos[2], bz = task.targetPos[3],
            scale = 1.5,
            assetfile = "character/common/headarrow/headarrow.x",
        });
    end

    local GameData = __ClientData__.GameData;
    if (GameData) then
        TiYuJingSaiTasks[1].state = GameData.RunData and GameData.RunData.state or 0;
        TiYuJingSaiTasks[2].state = GameData.ShootData and GameData.ShootData.state or 0;
    end

    -- 课程
    for i = 1, 10 do
        KeChengTasks["quweibiancheng"][i].state = QuestAction.GetDongaoLessonState("code", i) and 1 or 0;
        KeChengTasks["kuailejianzao"][i].state = QuestAction.GetDongaoLessonState("build", i) and 1 or 0;
        KeChengTasks["jingcaidonghua"][i].state = QuestAction.GetDongaoLessonState("anim", i) and 1 or 0;
    end

    -- 检测并领取证书
    CheckAndGetCert();

    async_run(function()
        while(true) do
            local bx, by, bz = GetPlayer():GetBlockPos();
            for index, task in ipairs(LaJiFenLeiMovieTasks) do
                local pos = task.targetPos;
                if (not task.movie:IsPlaying() and bx >= pos[1] - 1 and bx <= pos[1] + 1 and bz >= pos[3] -1 and bz <= pos[3] + 1) then
                    -- print("===============FinishLaJiFenLeiMovieTask=============", index);
                    _G.FinishLaJiFenLeiMovieTask(index);
                    task.movie:Play();
                    local teleportPos = task.teleportPos;
                    cmd(string.format("/goto %s %s %s", teleportPos[1], teleportPos[2], teleportPos[3]));
                end
            end
            sleep(100);
        end
    end);
end

local owned = KeepWorkItemManager.HasGSItem(40008);
if (not owned) then Tip("未登录") end

local function PushClientData(success, fail)
    local __ClientData__ = KeepWorkItemManager.GetClientData(40008) or {};
    KeepWorkItemManager.SetClientData(40008, __ClientData__, __safe_callback__(function()
        if (type(success) == "function") then success() end 
    end), __safe_callback__(function()
        if (type(fail) == "function") then fail() end 
    end));
end

local function FinishLaJiFenLeiMovieTask(index)
    local __ClientData__ = KeepWorkItemManager.GetClientData(40008) or {};
    local refuseClassificationData = __ClientData__.refuseClassificationData or {};
    __ClientData__.refuseClassificationData = refuseClassificationData;
    refuseClassificationData[index] = 1;
    PushClientData(function()
        Tip(string.format("%s 任务完成", LaJiFenLeiMovieTasks[index].title));
    end)
end
_G.FinishLaJiFenLeiMovieTask = FinishLaJiFenLeiMovieTask;

InitTasks();

local __winter_camp_map_ui__ = nil;
function ShowWinterCampMapWindow()
    if (__winter_camp_map_ui__) then return end 
    __winter_camp_map_ui__ = ShowWindow({
        OnClose = function() 
            __winter_camp_map_ui__ = nil;
            CloseWinterCampMainWindow();
        end 
    }, {
        width = 1024, 
        height = 600, 
        url = "Mod/GeneralGameServerMod/UI/App/WinterCamp/WinterCampMap.html",
    })
end

function CloseWinterCampMapWindow()
    if (not __winter_camp_map_ui__) then return end 
    __winter_camp_map_ui__:CloseWindow();
    __winter_camp_map_ui__ = nil;
end

local __winter_camp_ui__ = nil;

function CloseWinterCampMainWindow()
    if (not __winter_camp_ui__) then return end 
    __winter_camp_ui__:CloseWindow();
    __winter_camp_ui__ = nil;
end

function ShowWinterCampMainWindow(defaultTabIndex)
    if (__winter_camp_ui__) then 
        local G = __winter_camp_ui__:GetG();
        if (defaultTabIndex and type(G.SelectCurrentTabIndex) == "function") then
            G.SelectCurrentTabIndex(defaultTabIndex);
        end
        return ;
    end 

    InitTasks();
    -- __winter_camp_ui__ = Page.ShowWinterCampPage({
    __winter_camp_ui__ = ShowWindow({
        DefaultTabIndex = defaultTabIndex,
        CertConfig = CertConfig,
        LaJiFenLeiMovieTasks = LaJiFenLeiMovieTasks, 
        KeChengTasks = KeChengTasks,
        TiYuJingSaiTasks = TiYuJingSaiTasks,
        ShowWinterCampMapWindow = ShowWinterCampMapWindow,
        CloseWinterCampMainWindow = CloseWinterCampMainWindow,
        GoLaJiFenLeiMovieTask = function(index)
            local task = LaJiFenLeiMovieTasks[index];
            cmd(string.format("/goto %s %s %s", task.teleportPos[1], task.teleportPos[2], task.teleportPos[3]));
        end,
        OnClose = function() 
            __winter_camp_ui__ = nil;
        end 
    }, {
        width = 1024, 
        height = 600, 
        url = "Mod/GeneralGameServerMod/UI/App/WinterCamp/WinterCamp.html",
    });
end


ShowWinterCampMainWindow();



-- ShowWinterCampMapWindow();

-- FinishLaJiFenLeiMovieTask(1);
-- function 
-- "%ui%/App/WinterCamp/WinterCamp.lua"
-- __ClientData__ = KeepWorkItemManager.GetClientData(40008) or {
--     -- 垃圾分类数据
--     refuseClassificationData = {
--         [1] = 0,  -- 电影一是否完成
--         [2] = 1,  -- 电影二是否完成
--     },
--     -- 游戏数据
--     GameData = {
--         ShootData = {state = 0},  -- 射击游戏  state = 0 未完成 1 已完成 2 进行中
--         RunData = {state = 0},    -- 跨栏游戏  state = 0 未完成 1 已完成 2 进行中
--         GarbageData = {state},    -- 捡垃圾游戏  state = 0 未完成 1 已完成 2 进行中
--     },
--     -- 课程数据
-- }