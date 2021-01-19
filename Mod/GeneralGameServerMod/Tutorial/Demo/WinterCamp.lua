--[[
Author: wxa
Date: 2020-10-26
Desc: 冬令营开幕式 
-----------------------------------------------
local WinterCamp = NPL.load("Mod/GeneralGameServerMod/Tutorial/Demo/WinterCamp.lua");

世界ID release: 1471  online: 41570

如何测试
更新 ggs 模块代码, 拷贝本文件内容至代码方块
开幕配声文件放置 assets/school_xxx.ogg (xxx 为学校ID) 默认配声文件 assets/principal_speech.ogg
响铃声音文件放置 assets/ring.mp3   Note: 文件都是相对当前世界根目录
开幕动画电影方块 OpeningCeremonyAnimBlockPos = {x = 0, y = 0, z = 0};  更改x,y,z 为正确位置
指定时间测试, 解除 IsDevEnv=true 的注释, 更新 local ServerTimeStamp = os.time({year=2021, month=1, day=25, hour=10, min=35, sec=57, isdst=false}) * 1000; 中时间值为服务器时间的起始值
-----------------------------------------------
]]

--IsDevEnv = true;
local TutorialSandbox = NPL.load("Mod/GeneralGameServerMod/Tutorial/TutorialSandbox.lua", IsDevEnv ~= nil and IsDevEnv or false);
local KeepworkAPI = TutorialSandbox:GetKeepworkAPI();
local MessageBox = TutorialSandbox:GetSystemMessageBox();
local ServerTimeStamp = os.time({year=2021, month=1, day=25, hour=10, min=35, sec=57, isdst=false}) * 1000;
local ServerDateObj = os.date("*t", math.floor(ServerTimeStamp / 1000));
local ClientTimeStamp = TutorialSandbox:GetTimeStamp();
local OpeningCeremonyAnimBlockPos = {x = 0, y = 0, z = 0};
local WinterCamp = gettable("WinterCamp");

TutorialSandbox:Reset();

-- 
TutorialSandbox:SetStepTask(1, function()
end);

function GetCurrentTimeStamp()
    return TutorialSandbox:GetTimeStamp() - ClientTimeStamp + ServerTimeStamp;
end

-- {year=2021, month=1, day=18, hour=18, min=3, sec=28, wday=2, yday=18, isdst=false}
function GetCurrentDateObject()
    return os.date("*t", math.floor(GetCurrentTimeStamp() / 1000));
end

-- 冬令营开幕
function IsWinterCampStartDate()
    local curdate = GetCurrentDateObject();
    return curdate.year == 2021 and curdate.month == 1 and curdate.day == 25;
end

-- 冬令营上课
function IsWinterCampAttendClassDate()
    local curdate = GetCurrentDateObject();
    return curdate.year == 2021 and ((curdate.month == 1 and curdate.day > 25) or (curdate.month == 2 and curdate.day < 6));
end

-- 冬令营结束
function IsWinterCampEndDate()
    local curdate = GetCurrentDateObject();
    return curdate.year == 2021 and curdate.month >= 2 and curdate.day >= 6;
end

-- 是否是vip学校学生
function IsVipSchoolStudent()
    return TutorialSandbox:GetSystemUser().isVipSchool;
end

-- 是否是vip
function IsVip()
    return TutorialSandbox:GetSystemUser().isVip;
end

-- 学校ID
function GetSchoolId()
    return TutorialSandbox:GetUserInfo().schoolId;
end

-- 开始前10分钟
function WinterCamp:StartBefore10Minute()
    tip("冬令营开营典礼马上就要开始了，请尽快前往大礼堂")
    playSound("assets/ring.mp3");
    -- wait(30);
    -- stopSound("assets/ring.mp3");
end

-- 开始前2分钟
function WinterCamp:StartBefore2Minute()
    tip("冬令营开营典礼将在两分钟后开始，请尽快前往大礼堂");
    playSound("assets/ring.mp3");
    -- wait(30);
    -- stopSound("assets/ring.mp3");
end

-- 开营典礼
function WinterCamp:OpeningCeremony(second)
    TutorialSandbox:SetKeyboardMouse(false, false);
    -- 播放声音
    local filename = string.format("school_%d.ogg", GetSchoolId());
    if (not TutorialSandbox:IsExistFile(filename)) then filename = "assets/principal_speech.ogg" end
    print(string.format("开幕典礼, 开始时间 = %ss 声音文件 = %s", second, filename));
    playSound(filename, nil, second);
    -- 播放动画
    if (self.isAllowInAuditorium) then
        setMovie("OpeningCeremony", OpeningCeremonyAnimBlockPos.x , OpeningCeremonyAnimBlockPos.y, OpeningCeremonyAnimBlockPos.z);
        playMovie("OpeningCeremony", second * 1000, -1);
        stopMovie("OpeningCeremony");
    end
    TutorialSandbox:SetKeyboardMouse(true, true);
end

-- 开始开幕式
function WinterCamp:StartOpeningCeremony()
    local function GetWaitTime(curdate)
        local hour, min, sec = curdate.hour, curdate.min, curdate.sec;
        if (hour == 10 and min >=20 and min <= 27) then return 4, 1, true, false end
        if (hour == 10 and min >= 28 and min <= 30) then return 1, 1, false, true end
        if (hour == 13 and min >= 20 and min <= 27) then return 4, 2, true, false end
        if (hour == 13 and min >= 28 and min <= 30) then return 1, 2, false, true end
        if (hour == 15 and min >= 50 and min <= 57) then return 4, 3, true, false end
        if (hour == 15 and min >= 58 and min <= 59) then return 1, 3, false, true end
        if (hour == 17 and min >= 50 and min <= 57) then return 4, 4, true, false end
        if (hour == 17 and min >= 58 and min <= 59) then return 1, 4, false, true end
        return 60, (hour <= 10 and 0 or 5);
    end
    local function IsOpeningCeremonyTime(curdate)
        local hour, min, sec = curdate.hour, curdate.min, curdate.sec;
        if (hour == 10 and min >= 30 and min <= 39) then
            return true, (min - 30) * 60 + sec, 1;
        elseif (hour == 13 and min >= 30 and min <= 39) then
            return true, (min - 30) * 60 + sec, 2;
        elseif (hour == 16 and min >= 0 and min <= 9) then
            return true, min * 60 + sec, 3;
        elseif (hour == 18 and min >= 0 and min <= 9) then
            return true, min * 60 + sec, 4;
        end 
        return false, 0, (hour <= 10 and 0 or 5);
    end

    local sounds = {};
    -- 主逻辑循环
    while(true) do 
        local curdate = GetCurrentDateObject(curdate);
        local waitSecond, no, isStartBefore10Minute, isStartBefore2Minute = GetWaitTime(curdate);
        self.isOpeningCeremonyTime, self.openingCeremonyTimeSecond, self.openingCeremonyNo = IsOpeningCeremonyTime(curdate);
        -- 存在场次
        if ((no <= 4 and no >= 1) or self.isOpeningCeremonyTime) then
            local sound = sounds[no] or {};
            sounds[no] = sound;
            print("==========main loop=========", curdate.hour, curdate.min, curdate.sec, no, isStartBefore10Minute, isStartBefore2Minute, self.isOpeningCeremonyTime, self.openingCeremonyTimeSecond);
            if (isStartBefore10Minute and not sound.isStartBefore10Minute) then 
                self:StartBefore10Minute();
                sound.isStartBefore10Minute = true;
            elseif (isStartBefore2Minute and not sound.isStartBefore2Minute) then
                self:StartBefore2Minute();
                sound.isStartBefore2Minute = true;
            else
                -- 是开幕典礼时间
                if (self.isOpeningCeremonyTime) then
                    if (not sound.isOpeningCeremony) then
                        self:OpeningCeremony(self.openingCeremonyTimeSecond);
                        sound.isOpeningCeremony = true;
                    end
                else
                end
            end
        end
        wait(waitSecond);
    end
end

-- 随机开幕式位置
function WinterCamp:RandomOpeningCeremonyPosition()
    -- （19223,12,19250）附近，X、Z（+/- 3）
    local x = math.random(19220, 19226);
    local y = 12;
    local z = math.random(19247, 19253);
    TutorialSandbox:SetPlayerBlockPos(x, y, z);
end

-- 禁飞检测
function WinterCamp:ForbidFlyCheck()
    run(function()
        while(true) do
            local x, y, z = TutorialSandbox:GetPlayerBlockPos();
            local isInnerAuditorium = false;
            if (x >= 19241 and x <= 19285 and z >= 19230 and z <= 19270) then isInnerAuditorium = true end
            TutorialSandbox:SetCanFly(not isInnerAuditorium);
            if (isInnerAuditorium and not self.isAllowInAuditorium) then 
                -- 不允许进入会场
                TutorialSandbox:SetPlayerBlockPos(19237,12,19250);
                MessageBox("冬令营就要开始了！你所在的学校已经有。128名同学报名了冬令营的会员活动！你也立即来参加吧！", function(res)
                    if(res == 6) then
                        -- GameLogic.GetFilters():apply_filters("cellar.vip_notice.init");
                        GameLogic.GetFilters():apply_filters("VipNotice", true, "vip_wintercamp1_join", function()
                            if (IsVip()) then
                                self.isAllowInAuditorium = true;
                            end
						end);
                    end
                end, 10, nil,nil,nil,nil, {ok = "我要报名"});
            elseif (isInnerAuditorium and self.isAllowInAuditorium) then
                -- 允许进入会场
                if (self.isOpeningCeremonyTime) then
                    if (self.isJoinOpeningCeremony == nil) then
                        if (self.openingCeremonyTimeSecond < 300) then
                            self.isJoinOpeningCeremony = true;
                            -- 随机位置
                            self:RandomOpeningCeremonyPosition();
                        else
                            TutorialSandbox:SetPlayerBlockPos(19237,12,19250);
                            self.isJoinOpeningCeremony = false;
                            if (self.openingCeremonyNo < 4) then
                                MessageBox("你已迟到五分钟，请下一场再进来，切记不可再迟到");
                            else
                                MessageBox("你已迟到五分钟，错过了开营典礼。明天上课请不要再迟到了！");
                            end
                        end
                    else
                        TutorialSandbox:SetPlayerBlockPos(19237,12,19250);
                    end
                else
                    self.isJoinOpeningCeremony = nil;
                end
            end

            wait(1);
        end
    end)
    
    -- 这个会场最好四面都有隐形墙比较好, 程序检测都是隔几秒检测一次, 这个间隔时间由于用户飞行过快很容易就飞进去了    
end

-- 冬令营逻辑开始
function WinterCamp:Start()
    print("current date", os.date("%Y-%m-%d %H:%M:%S", GetCurrentTimeStamp() / 1000));

    if (IsWinterCampStartDate()) then
        self.isAllowInAuditorium = IsVipSchoolStudent() or IsVip() or false;
        self.isAllowInAuditorium = true;
        self.isJoinOpeningCeremony = nil;
        self:ForbidFlyCheck();
        self:StartOpeningCeremony();
    elseif (IsWinterCampAttendClassDate()) then
        self:AttendClassRingCheck();
    elseif (IsWinterCampEndDate()) then
    
    else
    
    end
end

-- 上课铃检测
function WinterCamp:AttendClassRingCheck()
    local function GetWaitTime(curdate)
        local hour, min, sec = curdate.hour, curdate.min, curdate.sec;
        if (hour == 10 and min >=20 and min <= 27) then return 10, 1, true, false end
        if (hour == 10 and min >= 28 and min <= 30) then return 1, 1, false, true end
        if (hour == 13 and min >= 20 and min <= 27) then return 10, 2, true, false end
        if (hour == 13 and min >= 28 and min <= 30) then return 1, 2, false, true end
        if (hour == 15 and min >= 50 and min <= 57) then return 10, 3, true, false end
        if (hour == 15 and min >= 58 and min <= 59) then return 1, 3, false, true end
        if (hour == 17 and min >= 50 and min <= 57) then return 10, 4, true, false end
        if (hour == 17 and min >= 58 and min <= 59) then return 1, 4, false, true end
        return 60, (hour <= 10 and 0 or 5);
    end
    local sounds = {};
    run(function()
        local curdate = GetCurrentDateObject(curdate);
        local waitSecond, no, isStartBefore10Minute, isStartBefore2Minute = GetWaitTime(curdate);
        if (no <= 4 and no >= 1) then
            local sound = sounds[no] or {};
            sounds[no] = sound;
            if (isStartBefore10Minute and not sound.isStartBefore10Minute) then 
                tip("马上就要开始上课了, 请大家尽快前往教学楼集合!")
                playSound("assets/ring.mp3");
                sound.isStartBefore10Minute = true;
            elseif (isStartBefore2Minute and not sound.isStartBefore2Minute) then
                tip("两分钟后就要开始上课了, 请大家尽快前往教学楼集合!")
                playSound("assets/ring.mp3");
                sound.isStartBefore2Minute = true;
            else
            end
        end
        wait(waitSecond);
    end)
end

-- 获取服务器时间
local function Main()
    if (IsDevEnv) then return WinterCamp:Start() end

    KeepworkAPI:Get("keepworks/currentTime"):Then(function(response)
        -- 请求成功
        local data = response.data;
        ServerTimeStamp = data.timestamp;
        ServerDateObj = os.date("*t", math.floor(ServerTimeStamp / 1000));
        ClientTimeStamp = TutorialSandbox:GetTimeStamp();

        WinterCamp:Start();
    end):Catch(function(response)
        -- 请求失败
    end);
end

registerStopEvent(function()
end)

Main();