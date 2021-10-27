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

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local Net = NPL.load("./Net.lua");
local Snapshot =  commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Snapshot:Property("Directory");  -- 截图目录
Snapshot:Property("FilePath");   -- 截图文件路径
Snapshot:Property("EnableServer", false, "IsEnableServer");
Snapshot:Property("EnableClient", false, "IsEnableClient");

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
    self:ShowUI()
    if (not self.__server_tick_timer__) then
        self.__server_tick_timer__ = CommonLib.SetInterval(1000 * 30, function()
            self:RefreshUI();
        end);
    end
end

function Snapshot:StopServer()
    self:SetEnableServer(false);
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
end

function Snapshot:ShowUI()
    if (self.__ui__) then return end 

    local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
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
end

function Snapshot:RefreshUI()
    CommonLib.ClearTable(self.__ui_G__.keys);
    for key, connection in pairs(Net:GetAllConnection()) do
        table.insert(self.__ui_G__.keys, key);
    end
    if (self.__ui__) then self.__ui_G__.RefreshWindow() end
end

function Snapshot:CloseUI()
    if (not self.__ui__) then return end 
    self.__ui__:CloseWindow();
    self.__ui__ = nil;
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
    Net:Call("Snapshot_FPS", data);
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

Snapshot:InitSingleton():Init();

-- Snapshot:Test();


-- self.frontBuffer =  
-- self.frontBuffer:UnloadAsset();
-- self:SwapBuffer()