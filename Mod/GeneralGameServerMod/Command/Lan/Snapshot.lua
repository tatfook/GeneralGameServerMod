--[[
Title: Snapshot
Author(s):  wxa
Date: 2020-06-12
Desc: Command
use the lib:
------------------------------------------------------------
local Snapshot = NPL.load("Mod/GeneralGameServerMod/Command/Lan/Snapshot.lua");
------------------------------------------------------------
]]
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local Net = NPL.load("./Net.lua");
local Snapshot =  commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Snapshot:Property("Directory");                                      -- 截图目录
Snapshot:Property("FilePath");                                       -- 截图文件路径
-- Snapshot:Property("LockScreen", false, "IsLockScreen");              -- 是否锁屏
Snapshot:Property("EnableServer", false, "IsEnableServer");
Snapshot:Property("EnableClient", false, "IsEnableClient");
Snapshot:Property("EnableSnapshotData", true, "IsEnableSnapshotData");

local HIGH_FPS, LOW_FPS = 2, 1/5;

function Snapshot:ctor()
    self:SetDirectory("temp/snapshots/");
    CommonLib.CreateDirectory(self:GetDirectory(), true);
    self:SetFilePath(self:GetDirectory() .. "snapshot.jpg");
    self:SetWidthHeight(400, 300);
    self:Take();
end

function Snapshot:SetWidthHeight(width, height)
    self.width, self.height = width, height;
end

function Snapshot:GetWidthHeight()
    return self.width, self.height;
end

function Snapshot:Take()
    if (not self:IsEnableSnapshotData()) then return end 

    local filepath = self:GetFilePath();
    local width, height = self:GetWidthHeight();
    if (not ParaMovie.TakeScreenShot(filepath, width, height)) then
        print("---------------------ParaMovie.TakeScreenShot Failed----------------------");
        return ;
    end
    -- print("generat snapshot:", filepath);
    Net:Call("Snapshot_Data", CommonLib.GetFileText(filepath));
	-- ParaAsset.LoadTexture("", filepath,1):UnloadAsset();
end

function Snapshot:Init()
end

function Snapshot:StartServer()
    self:SetEnableServer(true);
    -- self:ShowUI()
    if (not self.__server_tick_timer__) then
        self.__server_tick_timer__ = CommonLib.SetInterval(1000 * 15, function()
            self:ServerTick();
        end);
    end
end

function Snapshot:StopServer()
    self:SetEnableServer(false);
end

function Snapshot:ServerTick()
    self:RefreshUI();

    if (not self:IsShowUI()) then
        Net:Broadcast("Snapshot_Data_Enable", {all = true, enable = false});
    elseif (#(self.__ui_G__.keys)  < 15) then
        Net:Broadcast("Snapshot_Data_Enable", {all = true, enable = true});
    else 
        local keys = self.__ui__:GetG().GetKeyVisible();
        Net:Broadcast("Snapshot_Data_Enable", {keys});
    end
end

function Snapshot:StartClient()
    self:SetEnableClient(true);

    if (not self.__client_tick_timer__) then
        self.__client_tick_timer__ = CommonLib.SetInterval(1000 * 3, function()
            self:ClientTick();
        end);
    end
end

function Snapshot:StopClient()
    self:SetEnableClient(false);
end

function Snapshot:ClientTick()
    self:Take();

    local __LockScreenData__ = Snapshot.__LockScreenData__;
    local cur_time = CommonLib.GetTimeStamp();
    if (__LockScreenData__ and (cur_time - __LockScreenData__.updateAt) > (1000 * 60)) then
        self:CloseLockScreenUI();
    end
end

function  Snapshot:IsShowUI()
    return self.__ui__ ~= nil;
end

function Snapshot:ShowUI()
    if (self.__ui__) then return end 

    local all_connections = Net:GetAllConnection();
    self.__ui_G__ = {
        HIGH_FPS = HIGH_FPS, LOW_FPS = LOW_FPS,
        keys = {}, 
        all_connections = all_connections,
        is_focus = function(key)
            local connection = all_connections[key];
            return connection and connection.appHasFocus;
        end,
        get_snapshot = function(key)
            local connection = all_connections[key];
            return connection and connection.snapshot and connection.snapshot.filepath;
        end,
        get_userinfo = function(key)
            local connection = all_connections[key];
            return connection and connection.userinfo or {};
        end,
        get_ip = function(key)
            return all_connections[key] and all_connections[key].ip;
        end,
        broadcast_fps = function(data)
            self:BroadcastFPS(data);
        end,
        get_total_user_count = function()
            return #(self.__ui_G__.keys);
        end,
        OnClose = function()
            self.__ui__ = nil;
        end
    };
    self.__ui__ = Page.Show(self.__ui_G__, {
        url = "Mod/GeneralGameServerMod/Command/Lan/Snapshot.html",
        width = IsDevEnv and 1280 or "100%",
        height = IsDevEnv and 720 or "100%",
        draggable = false,
    });

    Net:Broadcast("Snapshot_ShowUI");
end

function Snapshot:RefreshUI()
    if (not self.__ui__) then return end 

    CommonLib.ClearTable(self.__ui_G__.keys);
    local list = {};
    for key, connection in pairs(Net:GetAllConnection()) do
        table.insert(list, {key = key, username = connection.userinfo and connection.userinfo.username or connection.ip});
    end
    table.sort(list, function(item1, item2) return item1.username < item2.username end);
    for _, item in ipairs(list) do table.insert(self.__ui_G__.keys, item.key) end
    if (self.__ui__) then self.__ui_G__.RefreshWindow() end
end

function Snapshot:CloseUI()
    if (not self.__ui__) then return end 
    self.__ui__:CloseWindow();
    self.__ui__ = nil;
end

function Snapshot:SendLockScreenData()
    local filepath = self:GetFilePath();
    if (not ParaMovie.TakeScreenShot(filepath, 1280, 720)) then
        print("---------------------ParaMovie.TakeScreenShot Failed----------------------");
        return ;
    end
    if (IsDevEnv) then print("=========================Broadcast Snapshot_LockScreenData==========================") end 
    Net:Broadcast("Snapshot_LockScreenData", CommonLib.GetFileText(filepath));
end

function Snapshot:ShowLockScreenUI(BackgroundImage)
    self.__lock_screen_ui_G__ = self.__lock_screen_ui_G__ or {};
    self.__lock_screen_ui_G__.BackgroundImage = BackgroundImage;
    if (self.__lock_screen_ui__) then return self.__lock_screen_ui_G__.RefreshWindow() end 
    self.__lock_screen_ui__ = Page.Show(self.__lock_screen_ui_G__, {
        url = "Mod/GeneralGameServerMod/Command/Lan/LockScreen.html",
        width = IsDevEnv and 1280 or "100%",
        height = IsDevEnv and 720 or "100%",
        draggable = false,
    });
end

function Snapshot:CloseLockScreenUI()
    if (not self.__lock_screen_ui__) then return end 
    self.__lock_screen_ui__:CloseWindow();
    self.__lock_screen_ui__ = nil;
end

function Snapshot:IsLockScreen()
    return self.__lock_screen_timer__ ~= nil;
end

function Snapshot:IsPPTClosed()
    local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
    return RedSummerCampPPtPage.IsClose();
end

function Snapshot:LockScreen()
    -- self:SetLockScreen(true);
    if (self.__lock_screen_timer__) then return end 

    self.__ppt_refresh_at__ = CommonLib.GetTimeStamp();
    self:SendLockScreenData();
    self.__lock_screen_timer__ = CommonLib.SetInterval(1000 * 10, function()
        -- ppt 是否打开, 如果未打开则解除的锁屏 TODO 
        local curtime = CommonLib.GetTimeStamp();
        if (self:IsPPTClosed()) then
            if ((curtime - self.__ppt_refresh_at__) > 30 * 1000) then
                -- 关闭时间超过30s, 则自动解除锁屏
                print("----------------------------------auto unlock---------------------------------");
                self:UnlockScreen();
            end
        else
            self.__ppt_refresh_at__ = curtime;
            self:SendLockScreenData();
        end
    end);
    Net:Broadcast("Snapshot_LockScreen");
end

function Snapshot:UnlockScreen()
    -- self:SetLockScreen(false);
    if (self.__lock_screen_timer__) then
        self.__lock_screen_timer__:Change();
        self.__lock_screen_timer__ = nil;
    end
    Net:Broadcast("Snapshot_UnlockScreen");
end

function Snapshot:GetInfo()
    local connection = Net:GetCurrentConnection();
    if (connection.snapshot) then return connection.snapshot end 
    local snapshot = {size = 2, list = {}, index = 1, buffer_index = 1};
    for i = 1, snapshot.size do
        local filepath = string.format("%s%s_%s.jpg", Snapshot:GetDirectory(), connection.nid, i);
        snapshot.list[i] = {filepath = filepath, loading = false, buffer = ParaAsset.LoadTexture("", filepath, 1)};
    end
    snapshot.filepath = snapshot.list[snapshot.index].filepath;
    connection.snapshot = snapshot;
    return snapshot;
end

function Snapshot:SetFPS(fps)
    if (self.__fps__ == fps) then return end 
    local interval = math.floor(1000 / fps);
    -- print("========================================set fps", fps, interval);
    self.__fps__ = fps;
    if (self.__client_tick_timer__) then
        self.__client_tick_timer__:Change(interval, interval);
    end
end


function Snapshot:BroadcastFPS(data)
    Net:Broadcast("Snapshot_FPS", data);
end

Net:Register("Snapshot_Data", function(data)
    if (not Snapshot:IsEnableServer()) then return end 

    local snapshot = Snapshot:GetInfo();
    local filepath = snapshot.list[snapshot.buffer_index].filepath;
    local buffer = snapshot.list[snapshot.buffer_index].buffer;
    if (buffer.loading and buffer:IsLoaded()) then
        buffer.loading = false;
        snapshot.index = snapshot.buffer_index;
        snapshot.filepath = snapshot.list[snapshot.index].filepath;
        snapshot.buffer_index = snapshot.buffer_index == snapshot.size and 1 or (snapshot.buffer_index + 1);
        Snapshot:RefreshUI();
        filepath = snapshot.list[snapshot.buffer_index].filepath;
        buffer = snapshot.list[snapshot.buffer_index].buffer;
    end
    CommonLib.WriteFile(filepath, data);
    buffer:UnloadAsset();
    buffer:LoadAsset();
    buffer.loading = true;
end);

-- 广播给所有用户, 让用户控制自己的帧率
Net:Register("Snapshot_FPS", function(data)
    if (not Snapshot:IsEnableClient()) then return end 
    
    local key = Net:GetServerKey();
    -- print("==============Snapshot_FPS=========", key, data.key)
    if (data.all) then              -- 全体设置
        Snapshot:SetFPS(data.fps or data.default_fps);
    elseif (data.key == key) then   -- 激活用户
        if (data.fps) then Snapshot:SetFPS(data.fps) end 
        if (data.width and data.height) then self:SetWidthHeight(data.width, data.height) end
    elseif (data.default_fps) then  -- 用于取消上次激活用户
        Snapshot:SetFPS(data.default_fps)
    end
end);


-- 截屏数据是否开启
Net:Register("Snapshot_Data_Enable", function(data)
    local key = Net:GetServerKey();
    if (data.all) then
        Snapshot:SetEnableSnapshotData(data.enable);
    elseif (data.keys) then
        Snapshot:SetEnableSnapshotData(data.keys[key]);
    end
end);

-- 截屏数据是否开启
Net:Register("Snapshot_ShowUI", function()
    Snapshot:SetEnableSnapshotData(true);
    Net:ClientTick();
end);

Net:Register("Snapshot_LockScreenData", function(data)
    if (not Snapshot.__LockScreenData__) then
        Snapshot.__LockScreenData__ = {
            buffers = {},
            buffer_size = 2,
            buffer_index = 1,
            filepath = "",
        }
        local filepath = string.format("%s%s_%s.jpg", Snapshot:GetDirectory(), "lockscreen", 1);
        table.insert(Snapshot.__LockScreenData__.buffers, {filepath = filepath, loading = false, buffer = ParaAsset.LoadTexture("", filepath, 1)});
        filepath = string.format("%s%s_%s.jpg", Snapshot:GetDirectory(), "lockscreen", 2);
        table.insert(Snapshot.__LockScreenData__.buffers, {filepath = filepath, loading = false, buffer = ParaAsset.LoadTexture("", filepath, 1)});
    end

    local __LockScreenData__ = Snapshot.__LockScreenData__;
    local filepath = __LockScreenData__.buffers[__LockScreenData__.buffer_index].filepath;
    local buffer = __LockScreenData__.buffers[__LockScreenData__.buffer_index].buffer;
    if (buffer.loading and buffer:IsLoaded()) then
        buffer.loading = false;
        __LockScreenData__.filepath = __LockScreenData__.buffers[__LockScreenData__.buffer_index].filepath;
        __LockScreenData__.buffer_index = __LockScreenData__.buffer_index == __LockScreenData__.buffer_size and 1 or (__LockScreenData__.buffer_index + 1);
        -- Snapshot:RefreshUI();
        filepath = __LockScreenData__.buffers[__LockScreenData__.buffer_index].filepath;
        buffer = __LockScreenData__.buffers[__LockScreenData__.buffer_index].buffer;
        Snapshot:ShowLockScreenUI(__LockScreenData__.filepath);
    end
    CommonLib.WriteFile(filepath, data);
    buffer:UnloadAsset();
    buffer:LoadAsset();
    buffer.loading = true;
    __LockScreenData__.updateAt = CommonLib.GetTimeStamp();
end);

Net:Register("Snapshot_LockScreen", function()
    Snapshot:ShowLockScreenUI();
end);

Net:Register("Snapshot_UnlockScreen", function()
    Snapshot:CloseLockScreenUI();
end)
Snapshot:InitSingleton():Init();

-- Snapshot:Test();


-- self.frontBuffer =  
-- self.frontBuffer:UnloadAsset();
-- self:SwapBuffer()