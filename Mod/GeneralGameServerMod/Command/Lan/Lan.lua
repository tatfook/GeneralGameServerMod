--[[
Title: Lan
Author(s):  wxa
Date: 2020-06-12
Desc: Lan
use the lib:
------------------------------------------------------------
local Lan = NPL.load("Mod/GeneralGameServerMod/Command/Lan/Lan.lua");
------------------------------------------------------------
]]
local Keepwork = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local AutoUpdater = NPL.load("Mod/GeneralGameServerMod/Command/AutoUpdater/AutoUpdater.lua");

local ServerSetting = NPL.load("./ServerSetting.lua", IsDevEnv);
local Net = NPL.load("./Net.lua", IsDevEnv);
local Snapshot = NPL.load("./Snapshot.lua", IsDevEnv);

local Lan =  commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Lan:Property("Server", false, "IsServer");
Lan:Property("Client", false, "IsClient");
Lan:Property("ServerIp");
Lan:Property("ServerPort", 8099);
Lan:Property("EnableSnapshot", false, "IsEnableSnapshot");
Lan:Property("EnableAutoUpdater", false, "IsEnableAutoUpdater");
Lan:Property("Net");
Lan:Property("Snapshot");
Lan:Property("ServerSetting");

function Lan:StartNetServer(ip, port)
    if (CommonLib.IsServerStarted()) then return end 
    print("===================StartNetServer=============", ip, port);
    if (IsDevEnv) then
        CommonLib.StartNetServer(ip, port);
    else
        NPL.load("(gl)script/apps/WebServer/WebServer.lua");
        print(string.format("StartWebServer %s:%s", ip, port));
        WebServer:Start("script/apps/WebServer/admin", ip, port);
    end
end

function Lan:StartServer()
    -- 启动本地服务器只能用本地IP: 0.0.0.0
    local ip, port = "0.0.0.0" or self:GetServerIp(), self:GetServerPort();
    self:StartNetServer(ip, port);
    Net:StartServer();
    
    print("================StartServer", self:IsEnableSnapshot(), self:IsEnableAutoUpdater());
    if (self:IsEnableSnapshot()) then Snapshot:StartServer() end 
    if (self:IsEnableAutoUpdater()) then AutoUpdater:StartServer() end 
    self:SetServer(true);

    if System.options.isChannel_430 then 
        local Broadcast = NPL.load("Mod/GeneralGameServerMod/CommonLib/Broadcast.lua");
        local timer = commonlib.Timer:new({callbackFunc = function() --不停的广播告诉局域网内的学生，我是教师服务器，以便学生自动连接
            if not Lan:IsServer() then
                return
            end
            Broadcast:SendBroadcaseMsg("TeacherSay:IsMe")
        end});
        timer:Change(1000*1, 1000*20);
    end
end

function Lan:StopServer()
end

function Lan:StartClient(ip, port)
    if (not self:GetServerIp()) then return end 
    ip, port = ip or self:GetServerIp(), port or self:GetServerPort();
    Net:StartClient(ip, port);

    print("================StartClient", self:IsEnableSnapshot(), self:IsEnableAutoUpdater());
    if (self:IsEnableSnapshot()) then Snapshot:StartClient(ip, port) end 
    if (self:IsEnableAutoUpdater()) then AutoUpdater:StartClient(ip, port) end 
    self:SetClient(true);
end

function Lan:StopClient()
    self.is_start_client = false;
end

function Lan:GetConnectionCount()
    local count = 0;
    for _ in pairs(self:GetNet():GetAllConnection()) do
        count = count + 1;
    end
    return count;
end

function Lan:Init()
    Net:SetLan(self);
    ServerSetting:SetLan(self);

    self:SetNet(Net);
    self:SetSnapshot(Snapshot);
    self:SetServerSetting(ServerSetting);

    -- 检测服务器
    self:GetServerSetting():CheckServer();

    return self;
end

function Lan:GetUserInfo()
    return {
        username = Keepwork:GetUserName() or (IsDevEnv and tostring(ParaGlobal.timeGetTime()) or nil),
        nickname = Keepwork:GetNickName(),
        classname = Keepwork:GetGradeClassName(),
        worldId = Keepwork:GetCurrentWorldID(),
        worldName = Keepwork:GetCurrentWorldName();
    };
end

function Lan:IsConnected()
    return self:GetNet():IsConnected();
end

function Lan:checkAutoConnectTeacher()
    local Broadcast = NPL.load("Mod/GeneralGameServerMod/CommonLib/Broadcast.lua");
    local Lan = NPL.load("Mod/GeneralGameServerMod/Command/Lan/Lan.lua");
    local __server_setting__ = NPL.load("Mod/GeneralGameServerMod/Command/Lan/ServerSetting.lua");

    local onBroadcast;
    onBroadcast = function(msg)
        local ip = msg.ip
        local port = msg.port

        if __server_setting__:IsEnableLocalServer() then
            return
        end
        
        local myIp = NPL.GetExternalIP()
        if Lan:IsClient() and Lan:IsConnected() then
            print("--------已经作为局域网客户端连接上教师服务器了，不再重新连接")
            Broadcast:RemoveBroadcaseEvent("TeacherSay:IsMe",onBroadcast)
            return
        end
        GameLogic.AddBBS(nil,L"找到教师服务器:"..ip)
        print("找到教师服务器:"..ip,Lan:IsClient(),Lan:IsConnected())
        -- print("---------aaaaaaa1111 收到老师喊话",ip,port)
        GameLogic.RunCommand(string.format("/lan -serverIp=%s -serverPort=%s -server=false -client=true ",ip,port))-- -autoupdater=true
    end
    --接收教师服务器的广播
    Broadcast:StartUDPServer()
    Broadcast:RegisterBroadcaseEvent("TeacherSay:IsMe",onBroadcast)
end

Lan:InitSingleton():Init();

Commands["lan"] = {
	mode_deny = "",
    name = "lan",
    quick_ref = "/lan 局域网命令集",
    desc = [[
示例:         
/lan -serverIp=127.0.0.1 -serverPort=8099 设定服务器IP和端口, 默认会进行连接(-server=false)
/lan -server=true 开启服务器  -client=true 是否是客户端
/lan -snapshot=true 是否启用截屏, 默认关闭. 客户端定时发送Paracraft UI信息到服务器
/lan -autoupdater=true 是否启用自动更新, 默认关闭
/lan -lockscreen=true 锁屏|解锁
/lan -server_setting=true 打开服务器设置
/lan -auto_find_teacher=true 如果不是老师，自动找到老师，然后连接
    ]],
    handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
        local opts = CommonLib.ParseOptions(cmd_text);
        
        if (opts.server ~= nil) then Lan:SetServer(opts.server) end
        if (opts.client ~= nil) then Lan:SetClient(opts.client) end  
        if (opts.snapshot ~= nil) then Lan:SetEnableSnapshot(opts.snapshot) end 
        if (opts.autoupdater ~= nil) then Lan:SetEnableAutoUpdater(opts.autoupdater) end 

        if (opts.serverIp ~= nil) then 
            Lan:SetServerIp(opts.serverIp);
        end
        
        if (opts.server_setting) then Lan:GetServerSetting():ShowUI() end 
        
        if (Lan:IsServer()) then Lan:StartServer() end 
        if (Lan:IsClient()) then Lan:StartClient() end 

        if (opts.lockscreen ~= nil) then 
            Lan:SetEnableSnapshot(true);
            Lan:StartServer();
            if (opts.lockscreen) then
                Lan:GetSnapshot():LockScreen();
            else
                Lan:GetSnapshot():UnlockScreen();
            end
        end

        if opts.auto_find_teacher then 
            Lan:checkAutoConnectTeacher()
        end
    end
}


-- if (IsDevEnv) then
--     local IsServer = ParaEngine.GetAppCommandLineByParam("IsServer","false") == "true";
--     print("============================================================================", IsServer)
--     Lan:SetEnableSnapshot(true);
--     if (IsServer) then
--         Lan:SetServer(true)
--         Lan:StartServer();
--     else
--         Lan:SetServerIp("127.0.0.1");
--         Lan:StartClient();
--     end
-- end

--[[
TEST 测试方法:
/lan -serverIp=192.168.249.2 -client=true -snapshot=true
服务端
1. 执行命令 /lan -server_setting=true  打开服务器IP设定界面, 启用本地服务器
2. 执行命令 /lan -snapshot=true 启用监控服务并打开监控UI 

客户端
1. 执行命令 /lan -server_setting=true  打开服务器IP设定界面, 设置服务器IP 默认会开启客户端监控功能
]]

--[[
-- 命令方式 /lan -server=true -snapshot=true

-- 获取局域网实例
local Lan = NPL.load("Mod/GeneralGameServerMod/Command/Lan/Lan.lua");
-- 开启快照功能
Lan:SetEnableSnapshot(true);
-- 启动server,   会自动打开监控UI  Lan:GetSnapshot():ShowUI();
Lan:StartServer();
-- 打开UI
Lan:GetSnapshot():ShowUI();
-- 关闭UI
Lan:GetSnapshot():CloseUI();
-- 锁屏
Lan:GetSnapshot():LockScreen();
-- 解锁
Lan:GetSnapshot():UnlockScreen();
-- 获取当前连接数(学生数)
Lan:GetConnectionCount();
--]]
