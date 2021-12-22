
local Enitiy = require("Entity");
local Movie = require("Movie");
local __ClientData__ = {};

-- 垃圾分类任务配置
local LaJiFenLeiMovieTasks = {
    -- targetPos 电影触发方块坐标   teleportPos 玩家传送方块坐标   moviePos 电影方块坐标 
    {targetPos = {18182,12,19191}, teleportPos = {18180,12,19191}, moviePos = {18186,12,19191}, state = 0, title = "厨余垃圾介绍"},
    {targetPos = {18182,12,19179}, teleportPos = {18180,12,19179}, moviePos = {18186,12,19179}, state = 0, title = "可回收物后续处理"},
    {targetPos = {18182,12,19187}, teleportPos = {18180,12,19187}, moviePos = {18186,12,19187}, state = 0, title = "可回收物介绍"},
    {targetPos = {18182,12,19183}, teleportPos = {18180,12,19183}, moviePos = {18186,12,19183}, state = 0, title = "厨余垃圾后续处理"},
    {targetPos = {18182,12,19177}, teleportPos = {18180,12,19177}, moviePos = {18186,12,19177}, state = 0, title = "有害垃圾后续处理"},
    {targetPos = {18182,12,19189}, teleportPos = {18180,12,19189}, moviePos = {18186,12,19189}, state = 0, title = "其他垃圾介绍"},
    {targetPos = {18182,12,19181}, teleportPos = {18180,12,19181}, moviePos = {18186,12,19181}, state = 0, title = "其他垃圾后续处理"},
    {targetPos = {18182,12,19185}, teleportPos = {18180,12,19185}, moviePos = {18186,12,19185}, state = 0, title = "有害垃圾介绍"},
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

local __winter_camp_ui__ = nil;
function ShowWinterCampMainWindow()
    if (__winter_camp_ui__) then return end 
    -- __winter_camp_ui__ = Page.ShowWinterCampPage({
    __winter_camp_ui__ = ShowWindow({
        LaJiFenLeiMovieTasks = LaJiFenLeiMovieTasks, 
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
        parent = GetRootUIObject(),
    });
end

function CloseWinterCampMainWindow()
    if (not __winter_camp_ui__) then return end 
    __winter_camp_ui__:CloseWindow();
    __winter_camp_ui__ = nil;
end

ShowWinterCampMainWindow();
-- FinishLaJiFenLeiMovieTask(1);
-- function 
-- "%ui%/App/WinterCamp/WinterCamp.lua"