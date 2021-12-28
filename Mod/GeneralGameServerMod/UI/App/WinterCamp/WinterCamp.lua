
local Enitiy = require("Entity");
local Movie = require("Movie");
local __ClientData__ = {};

local __winter_camp__ = {};

-- 垃圾分类任务配置
local LaJiFenLeiMovieTasks = {
    -- targetPos 电影触发方块坐标   teleportPos 玩家传送方块坐标   moviePos 电影方块坐标 
    {targetPos = {18182,12,19191}, teleportPos = {18180,12,19191}, moviePos = {18186,12,19191}, state = 0, text = "电影一", title = "厨余垃圾介绍"},
    {targetPos = {18182,12,19179}, teleportPos = {18180,12,19179}, moviePos = {18186,12,19179}, state = 0, text = "电影二", title = "可回收物后续处理"},
    {targetPos = {18182,12,19187}, teleportPos = {18180,12,19187}, moviePos = {18186,12,19187}, state = 0, text = "电影三", title = "可回收物介绍"},
    {targetPos = {18182,12,19183}, teleportPos = {18180,12,19183}, moviePos = {18186,12,19183}, state = 0, text = "电影四", title = "厨余垃圾后续处理"},
    {targetPos = {18182,12,19177}, teleportPos = {18180,12,19177}, moviePos = {18186,12,19177}, state = 0, text = "电影五", title = "有害垃圾后续处理"},
    {targetPos = {18182,12,19189}, teleportPos = {18180,12,19189}, moviePos = {18186,12,19189}, state = 0, text = "电影六", title = "其他垃圾介绍"},
    {targetPos = {18182,12,19181}, teleportPos = {18180,12,19181}, moviePos = {18186,12,19181}, state = 0, text = "电影七", title = "其他垃圾后续处理"},
    {targetPos = {18182,12,19185}, teleportPos = {18180,12,19185}, moviePos = {18186,12,19185}, state = 0, text = "电影八", title = "有害垃圾介绍"},
}

-- 课程任务配置
local KeChengTasks = {
    -- 趣味编程
    ["quweibiancheng"] = {
        {teleportPos = {18182,12,19191}, state = 0, text = "第一课", title = "初级跑步训练", subtitle = "前进与说话"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第二课", title = "跨越障碍", subtitle = "位移"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第三课", title = "初级游泳训练", subtitle = "朝向旋转"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第四课", title = "游泳技巧训练", subtitle = "朝向改变"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第五课", title = "跑步跨栏", subtitle = "做出动作"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第六课", title = "高级跑步入门", subtitle = "条件与触碰感知"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第七课", title = "跳远训练", subtitle = "条件与触碰感知"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第八课", title = "体育场馆寻路", subtitle = "高级条件"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第九课", title = "跑步绕圈", subtitle = "循环"},
        {teleportPos = {18182,12,19191}, state = 0, text = "第十课", title = "越野跑步训练", subtitle = "循环与高级条件"},
    }, 
    -- 快乐建造
    ["kuailejianzao"] = {
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
    {teleportPos = {18315,12,19142}, state = 0, text = "跨栏", description = "跨栏小游戏"},
    {teleportPos = {18316,12,19314}, state = 0, text = "射箭", description = ""},
    {teleportPos = {18182,12,19191}, state = 0, text = "", description = ""},
    {teleportPos = {18182,12,19191}, state = 0, text = "", description = ""},
}

function InitLaJiFenLeiMovieTasks()
    local refuseClassificationData = __ClientData__.refuseClassificationData or {};
    __ClientData__.refuseClassificationData = refuseClassificationData;
    for index, task in ipairs(LaJiFenLeiMovieTasks) do
        task.state = refuseClassificationData[index] or 0;
        task.movie = Movie:new():Init(task.moviePos[1], task.moviePos[2], task.moviePos[3]);

        task.circle = Enitiy:new():Init({
            bx = task.targetPos[1], by = task.targetPos[2], bz = task.targetPos[3],
            assetfile = "character/CC/05effect/fireglowingcircle.x",
        });
        
        task.arrow = Enitiy:new():Init({
            bx = task.targetPos[1], by = task.targetPos[2], bz = task.targetPos[3],
            scale = 1.5,
            assetfile = "character/common/headarrow/headarrow.x",
        });
    end

    local GameData = __ClientData__.GameData;
    if (GameData) then
        TiYuJingSaiTasks[1] = GameData.RunData and GameData.RunData.state or 0;
        TiYuJingSaiTasks[2] = GameData.ShootData and GameData.ShootData.state or 0;
    end

    -- 课程
    for i = 1, 10 do
        KeChengTasks["quweibiancheng"][i].state = QuestAction.GetDongaoLessonState("code", i) and 1 or 0;
        KeChengTasks["kuailejianzao"][i].state = QuestAction.GetDongaoLessonState("build", i) and 1 or 0;
        KeChengTasks["jingcaidonghua"][i].state = QuestAction.GetDongaoLessonState("anim", i) and 1 or 0;
    end

    async_run(function()
        while(true) do
            local bx, by, bz = GetPlayer():GetBlockPos();
            for index, task in ipairs(LaJiFenLeiMovieTasks) do
                local pos = task.targetPos;
                if (bx >= pos[1] - 1 and bx <= pos[1] + 1 and bz >= pos[3] -1 and bz <= pos[3] + 1) then
                    task.movie:Play();
                    _G.FinishLaJiFenLeiMovieTask(index);
                end
            end
            sleep(100);
        end
    end);
end

local owned = KeepWorkItemManager.HasGSItem(40008);
if (not owned) then Tip("未登录") end
__ClientData__ = KeepWorkItemManager.GetClientData(40008) or {};

local function PushClientData(success, fail)
    KeepWorkItemManager.SetClientData(40008, __ClientData__, __safe_callback__(function()
        if (type(success) == "function") then success() end 
    end), __safe_callback__(function()
        if (type(fail) == "function") then fail() end 
    end));
end

local function FinishLaJiFenLeiMovieTask(index)
    local refuseClassificationData = __ClientData__.refuseClassificationData or {};
    __ClientData__.refuseClassificationData = refuseClassificationData;
    refuseClassificationData[index] = 1;
    PushClientData(function()
        Tip(string.format("%s 任务完成", LaJiFenLeiMovieTasks[index].title));
    end)
end
_G.FinishLaJiFenLeiMovieTask = FinishLaJiFenLeiMovieTask;

InitLaJiFenLeiMovieTasks();

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
    if (__winter_camp_ui__) then return end 
    -- __winter_camp_ui__ = Page.ShowWinterCampPage({
    __winter_camp_ui__ = ShowWindow({
        DefaultTabIndex = defaultTabIndex,
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