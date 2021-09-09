--[[
Title: AutoUpdater
Author(s):  wxa
Date: 2021-08-12
Desc: 自动更新
use the lib:
------------------------------------------------------------
local AutoUpdater = NPL.load("Mod/GeneralGameServerMod/Command/AutoUpdater/AutoUpdater.lua");
------------------------------------------------------------
]]
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local FileSyncConnection = NPL.load("Mod/GeneralGameServerMod/CommonLib/FileSyncConnection.lua", IsDevEnv);

local __AutoUpdater__ = NPL.load("AutoUpdater");
local __AutoUpdaterState__ = __AutoUpdater__.State;

local AutoUpdater = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

AutoUpdater:Property("Installing", false, "IsInstalling");            -- 是否在安装中
AutoUpdater:Property("AutoInstall", false, "IsAutoInstall");          -- 是否自动安装
AutoUpdater:Property("DownloadFinish", false, "IsDownloadFinish");    -- 是否完成下载
AutoUpdater:Property("DownloadFinishCallBack");                       -- 是否完成回调
AutoUpdater:Property("DownloadFailedCallBack");                       -- 是否完成回调
AutoUpdater:Property("Downloading", false, "IsDownloading");          -- 是否下载中
AutoUpdater:Property("InstallDirectory");                             -- 安装目录
AutoUpdater:Property("ConfigFilePath");                               -- 配置文件路径
AutoUpdater:Property("ProxyURL");                                     -- 代理URL

-- AutoUpdater:Property("DownloadFromClient", false, "IsDownloadFromClient");  -- 是否通过客户端下载
AutoUpdater:Property("ServerIp", nil);
AutoUpdater:Property("ServerPort", nil);

local latest_version_path = CommonLib.ToCanonicalFilePath(ParaIO.GetWritablePath() .. "/caches/latest/");
local latest_version_tmp_path = CommonLib.ToCanonicalFilePath(ParaIO.GetWritablePath() .. "/caches/latest_tmp/");


function AutoUpdater:Init(opts)
    opts = opts or {};

    self:SetAutoInstall(opts.isAutoInstall);
    -- self:SetInstallDirectory(opts.installDirectory or (IsDevEnv and CommonLib.ToCanonicalFilePath(CommonLib.GetTempDirectory() .. "/AutoUpdater/") or CommonLib.GetRootDirectory()));
    self:SetInstallDirectory(opts.installDirectory or CommonLib.GetRootDirectory());
    self:SetConfigFilePath(opts.configFilePath or "config/autoupdater/paracraft_win32.xml");

    self.__auto_updater__ = __AutoUpdater__:new();

    -- let us skip all dll and exe files
	self.__auto_updater__.FilterFile = function(self, filename)
		if(filename:match("%.exe") or filename:match("%.dll")) then
			return true;
		end
	end

	local storageFilters = {
		["database/globalstore.db.mem.p"] = "Database/globalstore.db.mem.p",
		["database/globalstore.teen.db.mem.p"] = "Database/globalstore.teen.db.mem.p",
		["database/characters.db.p"] = "Database/characters.db.p",
		["database/extendedcost.db.mem.p"] = "Database/extendedcost.db.mem.p",
		["database/extendedcost.teen.db.mem.p"] = "Database/extendedcost.teen.db.mem.p",
		["npl_packages/paracraftbuildinmod.zip.p"] = "npl_packages/ParacraftBuildinMod.zip.p",
		["config/gameclient.config.xml.p"] = "config/GameClient.config.xml.p",
		
	}

	-- fix lower case issues on linux system
	self.__auto_updater__.FilterStoragePath = function(self, filename)
		return storageFilters[filename] or filename
	end

    self.__on_event__ = function(...)
        self:OnEvent(...);
    end

    return self;
end

function AutoUpdater:StartWebServer(ip, port)
    CommonLib.StartNetServer(ip, port);
    local Http = NPL.load("Mod/GeneralGameServerMod/Server/Http/Http.lua");
    Http:AddVirtualDirectory("/coredownload/update/", latest_version_path);
end

function AutoUpdater:CheckLatestVersion()
    if (not CommonLib.IsWin32Platform()) then return end 

    local oldInstallDirectory = self:GetInstallDirectory();
    local oldDownloadFinishCallBack = self:GetDownloadFinishCallBack();
    local oldDownloadFailedCallBack = self:GetDownloadFailedCallBack();
    local install_version = self:GetInstallVersion();

    self:SetInstallDirectory(latest_version_path);
    
    local function InstallLatestVersion()
        local latest_version = self:GetLatestVersion();
        if (latest_version ~= install_version) then
            -- 提示可以升级
            local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
            Page.ShowMessageBoxPage({
                text = "最新版本安装文件已准备就绪是否重启程序完成安装?",
                confirm = function()
                    self:InstallLatestVersion();
                end,
            });
        else
            print("安装版本已是最新版");
        end
    end

    self:Check(nil, function(bNeedUpdate)
        if (not bNeedUpdate) then 
            print("已是最新版本无需更新");
            self:SetInstallDirectory(oldInstallDirectory);
            InstallLatestVersion();
            return ;
        end
        -- 切换到临时目录下载
        self:SetInstallDirectory(latest_version_tmp_path);
        -- 删除临时目录
        CommonLib.DeleteDirectory(latest_version_path);
        -- 创建临时目录
        ParaIO.CreateDirectory(latest_version_tmp_path);
        -- 检测下载
        self:Check(nil, function()
            -- 下载完成回调
            self:SetDownloadFinishCallBack(function()
                self:SetInstallDirectory(oldInstallDirectory);
                self:SetDownloadFinishCallBack(oldDownloadFinishCallBack);
                self:SetDownloadFailedCallBack(oldDownloadFailedCallBack);
                -- 最新版下载完成
                local latest_version = self:GetLatestVersion();
                if (latest_version ~= install_version) then
                    InstallLatestVersion();
                else
                    print("安装版本已是最新版");
                end
            end);
            -- 下载失败
            self:SetDownloadFailedCallBack(function()
                self:SetInstallDirectory(oldInstallDirectory);
                self:SetDownloadFinishCallBack(oldDownloadFinishCallBack);
                self:SetDownloadFailedCallBack(oldDownloadFailedCallBack);
            end);
            -- 开始下载
            if (self:IsDownloadFromClient()) then
                self:DownloadFromClient()
            else
                self:Download();
            end
        end);
    end);
end

function AutoUpdater:CheckInstallLatestVersion()
    self:CheckLatestVersion();
end

function AutoUpdater:CheckInstallVersion()
    self:Check(nil, function(bNeedUpdate)
        if (not bNeedUpdate) then return end 
        if (self:IsDownloadFromClient()) then
            self:DownloadFromClient()
        else
            self:Download();
        end
    end);
end

function AutoUpdater:IsDownloadFromClient()
    return self:GetServerIp() and self:GetServerPort();
end

function AutoUpdater:AddHost(host, index)
    if (not host) then return end

    index = index or 1;
    local hosts = self.__auto_updater__.configs.hosts;
    for i, val in ipairs(hosts) do
        if (val == host) then
            hosts[i], hosts[index] = hosts[index], hosts[i];
            return;
        end
    end
    table.insert(hosts, index or 1, host);
end

function AutoUpdater:Check(version, callback)
    self.__auto_updater__:onInit(self:GetInstallDirectory(), self:GetConfigFilePath(), self.__on_event__);
    self.__auto_updater__:check(version, function(bSucceed)
        return type(callback) == "function" and callback(bSucceed and self.__auto_updater__:isNeedUpdate());
    end);
end

function AutoUpdater:OnFileChange()
end

function AutoUpdater:OnEvent(state, param1, param2)
    if(not state) then return end 
    local State =__AutoUpdaterState__;

    if(state == State.PREDOWNLOAD_VERSION)then
        print("预下载版本号");
    elseif(state == State.DOWNLOADING_VERSION)then
        print("正在下载版本信息");
    elseif(state == State.VERSION_CHECKED)then
        print("版本验证完毕");
    elseif(state == State.VERSION_ERROR)then
        print("无法获取版本信息"); -- error 
        self:SetDownloading(false);
        self:OnDownloadFailed();
    elseif(state == State.PREDOWNLOAD_MANIFEST)then
        print("资源列表预下载");
    elseif(state == State.DOWNLOADING_MANIFEST)then
        -- self:
        print("资源列表下载中");
    elseif(state == State.MANIFEST_DOWNLOADED)then
        print("已经获取资源列表");
        -- if (self:GetProxyURL()) then
        --     table.insert(self.__auto_updater__.configs.hosts, self.__auto_updater__.validHostIndex, self:GetProxyURL());
        -- end
    elseif(state == State.MANIFEST_ERROR)then
        print("无法获取资源列表"); -- error
        self:SetDownloading(false);
        self:OnDownloadFailed();
    elseif(state == State.PREDOWNLOAD_ASSETS)then
        print("准备下载资源文件");
        local nowTime = 0
        local lastTime = 0
        local interval = 100
        local lastDownloadedSize = 0
        self.__timer__ = commonlib.Timer:new({callbackFunc = function(timer)
            local totalSize = self.__auto_updater__:getTotalSize()
            local downloadedSize = self.__auto_updater__:getDownloadedSize()
            nowTime = nowTime + interval;

            if downloadedSize > lastDownloadedSize then
                local downloadSpeed = (downloadedSize - lastDownloadedSize) / ((nowTime - lastTime) / 1000)
                lastDownloadedSize = downloadedSize
                lastTime = nowTime
                local tips = string.format("%.1f/%.1fMB(%.1fKB/S)", downloadedSize / 1024 / 1024, totalSize / 1024 / 1024, downloadSpeed / 1024)
                print(tips)
            end
            
            if(not self:IsDownloading() and self.__timer__) then
                self.__timer__:Change();
                self.__timer__ = nil;
            end
        end})
        self.__timer__:Change(0, 100);
    elseif(state == State.DOWNLOADING_ASSETS)then
        print("正在下载资源");
    elseif(state == State.ASSETS_DOWNLOADED)then
        print("全部资源下载完成");
        self:OnDownloadFinish();
    elseif(state == State.ASSETS_ERROR)then
        print("无法获取资源");
        self:OnDownloadFailed();
    elseif(state == State.PREUPDATE)then
        print("准备安装更新");
    elseif(state == State.UPDATING)then
        print("正在安装更新");
    elseif(state == State.UPDATED)then
        print("安装完成");
        self:SetInstalling(false);
    elseif(state == State.FAIL_TO_UPDATED)then
        self:SetInstalling(false);
        local filename, errorCode = param1, param2;
        if(errorCode == __AutoUpdater__.UpdateFailedReason.MD5) then
            print(format(L"文件MD5校验失败:%s, 请重新更新", filename or ""));
        elseif(errorCode == __AutoUpdater__.UpdateFailedReason.Uncompress) then
            print(format(L"无法解压文件:%s, 请重试", filename or ""));
        elseif(errorCode == __AutoUpdater__.UpdateFailedReason.Move) then
            print(format(L"无法应用更新: 无法移动文件到%s.", filename or "")..L"请确保目前只有一个实例在运行");
        else
            print(L"无法应用更新"..L"请确保目前只有一个实例在运行");
        end
    end    
end

function AutoUpdater:DownloadFromClient()
    local filesync = FileSyncConnection:new():Init({__nid__ = CommonLib.AddNPLRuntimeAddress(self:GetServerIp(), self:GetServerPort())});
    filesync:Sync({
        local_file_path = self:GetDownloadDirectory(),
        remote_file_path = IsDevEnv and "/mnt/d/ParacraftDev/caches/latest/" or latest_version_path,
        finish_callback = function()
            print("===================finish_callback========================");
            self:Download();
        end,
        failed_callback = function()
            print("==================Unable to connect to proxy server===================");
            self:Download();
        end,
    });
end

function AutoUpdater:Download()
    local localLatestVersion = self:GetLocalLatestVersion();
    local latestVersion = self:GetLatestVersion();
    if (localLatestVersion == latestVersion) then
        print("最新版本已下载, 拷贝版本文件到安装缓存目录", latest_version_path,  self.__auto_updater__._assetsCachesPath);
        CommonLib.CopyDirectory(latest_version_path, self.__auto_updater__._assetsCachesPath, true);
    end

    self:SetDownloadFinish(false);
    self:SetDownloading(true);

    -- self:AddHost(self:GetProxyURL());
    self.__auto_updater__:download();
end

function AutoUpdater:OnDownloadFailed()
    local callback = self:GetDownloadFailedCallBack();
    if (type(callback) == "function") then callback() end 
end

function AutoUpdater:OnDownloadFinish()
    local download_version_path = CommonLib.ToCanonicalFilePath(self.__auto_updater__._assetsCachesPath .. "/");
    -- print(latest_version_path, download_version_path);
    -- 删除旧最新版本备份
    CommonLib.DeleteDirectory(latest_version_path);
    -- 备份最新版本
    CommonLib.CopyDirectory(download_version_path, latest_version_path, true);
    self:SetDownloading(false);
    self:SetDownloadFinish(true);

    self.__auto_updater__:decompress(latest_version_path .. "version.txt.p", latest_version_path .. "version.txt");

    local callback = self:GetDownloadFinishCallBack();
    if (type(callback) == "function") then callback() end 

    -- if (self:IsAutoInstall()) then
    --     self:Install();
    --     -- self.__auto_updater__:apply();
    -- end
end

function AutoUpdater:GetDownloadDirectory()
    return CommonLib.ToCanonicalFilePath(self.__auto_updater__._assetsCachesPath .. "/");
end

function AutoUpdater:LoadLocalVersion(version_filename)
    local version = CommonLib.GetFileText(version_filename) or "ver=0.0.0";
    version = string.gsub(version,"[%s\r\n]","");
    local __,v = string.match(version,"(.+)=(.+)");
    return v;
end

function AutoUpdater:GetCurrentVersion()
    self.__auto_updater__:getCurVersion();
end

function AutoUpdater:GetLatestVersion()
    return self.__auto_updater__:getLatestVersion();
end

function AutoUpdater:GetLocalLatestVersion()
    return self:LoadLocalVersion(latest_version_path .. "version.txt");
end

function AutoUpdater:GetInstallVersion()
    local version_filename = CommonLib.ToCanonicalFilePath(CommonLib.GetRootDirectory() .. "/version.txt");
    return self:LoadLocalVersion(version_filename);
end

function AutoUpdater:InstallLatestVersion()
    local upgrade_filename = CommonLib.ToCanonicalFilePath(CommonLib.GetTempDirectory() .. "/AutoUpgrade.lua");
    local cmdline_params = string.format([[servermode="true" bootstrapper="%s" latest_directory="%s" install_directory="%s"]], upgrade_filename, latest_version_path, self:GetInstallDirectory());
    print("AutoUpdater:InstallLatestVersion", cmdline_params);
    if (IsDevEnv) then cmdline_params = cmdline_params .. [[ logfile="D:\workspace\npl\GeneralGameServerMod\server.log"]] end 
    if (not ParaIO.CopyFile(CommonLib.ToCanonicalFilePath("Mod/GeneralGameServerMod/Command/AutoUpdater/AutoUpgrade.lua"), upgrade_filename, true)) then 
        print("Unable to generate upgrade script");
    else 
        print("generate auto upgrade file: ", upgrade_filename);
    end
    local npl_filename = CommonLib.ToCanonicalFilePath(CommonLib.GetRootDirectory() .. [[\ParaEngineClient.exe]]);
    if (not ParaGlobal.ShellExecute("open", npl_filename, cmdline_params, "", 1)) then return end 
    ParaGlobal.Exit(0);
    ParaGlobal.Exit(0);
end

function AutoUpdater:ShowServerSettingPage()
    local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
    Page.Show({}, {
        url = "Mod/GeneralGameServerMod/Command/AutoUpdater/ServerSettting.html",
    });
end

AutoUpdater:InitSingleton():Init();

Commands["autoupdater"] = {
	mode_deny = "",
    name = "autoupdater",
    quick_ref = "/autoupdater 客户端自动更新命令",
    desc = [[
示例:         
/autoupdater 不使用代理服务器, 官方更新
/autoupdater -severIp=127.0.0.1 -serverPort=9000 代理更新
/autoupdater -severIp=127.0.0.1 -serverPort=9000 -server=true 开启代理服务器
选项:
    -serverIp 代理服务器IP 
    -serverPort 代理服务器端口 
    -server 为真则为开启代理服务器 默认为假
    ]],
    handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
        local opts = CommonLib.ParseOptions(cmd_text);
        if (opts.server) then
            CommonLib.StartNetServer(opts.serverIp or "0.0.0.0", opts.serverPort or "9000");
        else
            if (opts.severIp) then AutoUpdater:SetServerIp(opts.severIp) end
            if (opts.serverPort) then AutoUpdater:SetServerIp(opts.serverPort) end
        end
        AutoUpdater:CheckLatestVersion();
    end
}
--[[
NPL.GetExternalIP();

客户端自动更新逻辑:
1. 检测caches/latest/本地最新版本文件是否最新, 是最新进入步骤2, 不是最新进行更新进入步骤3
2. 检测安装版本是否最新, 是最新版本则不进行后续处理, 不是最新进行更新进入步骤3
3. 检测远程版本是否与本地最新版caches/latest相同, 若相同则拷贝本地最新版到安装缓存目录, 不是则从远程下载置安装缓存目录
4. 下载完成备份至本地最新版本目录(caches/latest)
5. 重启完成安装 (launcher 需提供自动更新选项, 以及退出重启示例代码)

引入本地最新caches/latest缓存, 可供其它客户端更新:

WebServer 更新方式
方法:
启动WebServer添加虚拟目录映射: caches/latest/ => http://localhost:port/coredownload/update/

问题:
- 需要更新的文件列表并非静态文件(http://cdn.keepwork.com/update61/coredownload/1.0.10/list/full.p) 导致proxy URL被认为无效URL被跳过, 可规避.
- 所有文件下下载url携带md5值, 导致webserver虚拟目录无法查找正确文件
- WebServer是否需要支持多线程

FileSync 同步方式
方法:
启动NetServer, 对比本地安装缓存目录(caches/xxx.xx.xx/与代理服务器客户端本地最新版本目录(caches/latest/), 

问题:
- 多线支持

综上所述: webserver 问题偏多, 客户端自动更新方案暂定使用FileSync方式实现

测试:
local AutoUpdater = NPL.load("Mod/GeneralGameServerMod/Command/AutoUpdater/AutoUpdater.lua");
-- 开启客户单代理
AutoUpdater:SetDownloadFromClient(true);
AutoUpdater:SetServerIp("127.0.0.1");
AutoUpdater:SetServerPort("9000");
AutoUpdater:CheckInstallLatestVersion();
-- 不自动安装
-- AutoUpdater:SetAutoInstall(true);
-- AutoUpdater:CheckLatestVersion() -- 检测更新本地最新缓存
-- 自动更新安装版本
-- AutoUpdater:CheckInstallVersion();
]]

