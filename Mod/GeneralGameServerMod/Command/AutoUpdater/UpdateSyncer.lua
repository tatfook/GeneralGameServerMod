--[[
Title: UpdateSyncer
Author(s):  hyz
Date: 2022-04-08
Desc: 更新同步器，用于同步局域网内更新服务器的更新
use the lib:
------------------------------------------------------------
local UpdateSyncer = NPL.load("Mod/GeneralGameServerMod/Command/AutoUpdater/UpdateSyncer.lua");
------------------------------------------------------------
]]

local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local Broadcast = NPL.load("Mod/GeneralGameServerMod/CommonLib/Broadcast.lua",IsDevEnv);
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua",IsDevEnv);
local Net = NPL.load("Mod/GeneralGameServerMod/Command/Lan/Net.lua",IsDevEnv);
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua");
local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
local ClientUpdateDialog = commonlib.gettable("MyCompany.Aries.Game.MainLogin.ClientUpdateDialog");

local DefaultPort = "8099";


local UpdateSyncer = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local MSG_SERVER_BROADCAST = "this_is_lan_update_server"
local CLIENT_CAHCE_PATH = "caches/"

local MAX_UPLOAD_SIZE = 1024*1024*10 --服务器的上传池，最大是10M

local ConType = {
    server = "server",
    client = "client",
}

--客户端的下载状态
local DownloadState = {
    none = nil,
    deal_one = "deal_one", --正在下载某一个文件
    finish_one = "finish_one", --一个文件下载完成
    allFinished = "allFinished", --所有文件下载完成
    retrying = "retrying", --开始失败重试
    failed = "failed",--下载失败，重试也失败
}

function UpdateSyncer:ctor()
    self:Init()
end

--通过命令行参数确认是否用的最新版launcher
function UpdateSyncer:checkLauncherIsNew()
    local launcherVer = ParaEngine.GetAppCommandLineByParam("launcherVer","")
    print("-----command line launcherVer:",launcherVer)
    launcherVer = launcherVer:gsub("^[\"\'%s]+", ""):gsub("[\"\'%s]+$", "")--去掉字符串首尾的空格、引号
    launcherVer = tonumber(launcherVer)
    print("tonumber(launcherVer)",tonumber(launcherVer))
    if launcherVer and launcherVer>=3 then
        print("checkLauncherIsNew true")
        return true
    end
    print("checkLauncherIsNew false")
    return false
end

function UpdateSyncer:Init()
    if self._net~=nil then
        return
    end
    self._type = nil
    self._net = Net;
    
    GameLogic.GetFilters():add_filter("start_lan_client", function(opt)
        self.realLatestVersion = opt.realLatestVersion
        self.isAutoInstall = opt.isAutoInstall
        self.needShowDownloadWorldUI = opt.needShowDownloadWorldUI
        self.onUpdateError = opt.onUpdateError
        self:initClient()
        return opt
    end);
    GameLogic.GetFilters():add_filter("start_lan_server", function(opt)
        if not self:checkLauncherIsNew() then
            LOG.std(nil, "warning", "UpdateSyncer", "launcher版本号过低无法启动服务器");
            return opt
        end
        -- GameLogic.AddBBS(nil,"作为服务器开启了")
        self._updater = opt._updater --下载清单文件用
        self.realLatestVersion = opt.realLatestVersion
        self:getManifestAndDeletelist(function(downloads)
            if downloads==nil or #downloads==0 then
                LOG.std(nil, "warning", "UpdateSyncer", "清单有误,不能作为更新源");
                return
            end
            self.downloadlist = self:getKeyFileList(downloads)
            print("2---------下载清单:")
            echo(self.downloadlist)
            self:initServer()
        end)
        return opt
    end);
    GameLogic.GetFilters():add_filter("check_is_downloading_from_lan", function(opt)
        
        local _hasStartDownloaded = self:HasStartDownload()
        --print("_hasStartDownloaded",_hasStartDownloaded,self._downloadState)
        
        if opt.needShowDownloadWorldUI then
            self.needShowDownloadWorldUI = true
            if _hasStartDownloaded then
                DownloadWorld.ShowPage(L"局域网")
                DownloadWorld.UpdateProgressText(self.curText)
            end
        end
        if opt.installIfAlldownloaded and self:IsAllDownloadFinished() then
            self:onBtnApply()
        end
        opt._hasStartDownloaded = _hasStartDownloaded
        return opt
    end);

    --还没有初始化客户端的时候，就先开始监测一波，仅用于判断是否有局域网更新
    local onBroadcast;
    onBroadcast = function(msg)
        Broadcast:RemoveBroadcaseEvent(MSG_SERVER_BROADCAST,onBroadcast) --广播每次只监听一次
        if self._type ~= nil then
            return
        end
        
        local ip = msg.ip
        local port = msg.port
        local data = msg.__data__.msg
        local remoteVer = data.ver
        
        local localVer = self:getVersionByPath(CommonLib.GetRootDirectory())
        if CommonLib.CompareVer(localVer,remoteVer)<0 then --有更新
            self._hasUpdate = true
        end
    end
    --接收教师服务器的广播
    Broadcast:RegisterBroadcaseEvent(MSG_SERVER_BROADCAST,onBroadcast)
end

--去cdn下载全量下载清单
function UpdateSyncer:getManifestAndDeletelist(callback)
    local function _cb(downloads,deletes)
        if downloads then
            for i=1,#downloads do
                downloads[i] = string.gsub(downloads[i],".p$","")
            end
        end
    
        if callback then
            callback(downloads,deletes)
        end
    end
    if self._updater and self._updater.downloadManifest and self.realLatestVersion then
        local folder = CommonLib.GetRootDirectory().."temp/"
        ParaIO.CreateDirectory(folder)
        local folder = folder.."lan_update_manifest/"
        ParaIO.CreateDirectory(folder)
        local path_download_list = folder..self.realLatestVersion.."_download_list.list"
        if ParaIO.DoesFileExist(path_download_list) then
            local list_1,list_2
            local file = ParaIO.open(path_download_list,"r")
            if(file:IsValid())then
                local content = file:GetText();
                list_1 = commonlib.split(content,"\r\n")
            else
                print("======不可用",path_download_list)
                list_1 = {}
            end
            file:close()

            if _cb then
                _cb(list_1)
            end
        else
            self._updater:downloadManifest(function(list_1)
                list_1 = list_1 or {}
                local str_1 = table.concat(list_1,"\r\n")
                if str_1~="" then
                    CommonLib.WriteFile(path_download_list,str_1)
                end

                if _cb then
                    _cb(list_1)
                end
            end)
        end
        
    end
end

--=================================================UI部分 start=================================================
local page;
-- init function. page script fresh is set to false.
function UpdateSyncer.OnInit()
	page = document:GetPageCtrl();
end
function UpdateSyncer.ShowPage()
    if UpdateSyncer.needShowDownloadWorldUI then
        DownloadWorld.SetFromName(L"局域网")
        -- return
    end
    if page then
        return page
    end
	local width, height=400, 50;
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url = "Mod/GeneralGameServerMod/Command/AutoUpdater/UpdateSyncer.html", 
		name = "UpdateSyncer.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 1000,
		allowDrag = false,
		isTopLevel = false,
		directPosition = true,
			align = "_lb",
			x = 5,
			y = -35,
			width = width,
			height = height,
		cancelShowAnimation = true,
	});
end
function UpdateSyncer.UpdateProgressText(text)
    if UpdateSyncer.needShowDownloadWorldUI then
        if DownloadWorld.SetFromName then
            DownloadWorld.SetFromName(L"局域网")
        end
        DownloadWorld.UpdateProgressText(text);
        -- return
    end
    LOG.std(nil, "info", "UpdateSyncer", "progressText:%s",text);
    UpdateSyncer.curText = text
	if(page) then
		page:SetValue("progressText", text)
	end
end
function UpdateSyncer.ClosePage()
    if UpdateSyncer.needShowDownloadWorldUI then
        DownloadWorld.Close();
        -- return
    end
	if(page) then
		page:CloseWindow();
		page = nil;
	end
end

--点击应用更新
function UpdateSyncer.onBtnApply()
    local launcherExe = System.options.launcherExeName or "ParaCraft.exe"
    local root = CommonLib.GetRootDirectory()
    
    local storagePath = CommonLib.ToCanonicalFilePath(root.."caches/")

    local applyManifestFile = storagePath.."lan_apply.manifest"

    local applyVerFile = storagePath.."lan_applyVer.txt"
    
    applyManifestFile = commonlib.Encoding.DefaultToUtf8(applyManifestFile) --防止中文路径Launcher识别不到
    applyVerFile = commonlib.Encoding.DefaultToUtf8(applyVerFile) --防止中文路径Launcher识别不到
    local isFixMode = false
    local cmdStr = string.format('isFixMode=%s justNeedCopy=true applyManifestFile="%s" applyVerFile="%s"',tostring(isFixMode),applyManifestFile,applyVerFile)
    print("cmdStr",cmdStr)

    ParaGlobal.ShellExecute("open", launcherExe, cmdStr, "", 1);
    ParaGlobal.ExitApp();
    ParaGlobal.ExitApp();
end

function UpdateSyncer.RefreshPage()
    if(page) then
		page:Refresh(0);
	end
end
--=================================================UI部分 end=================================================


--=================================================服务器部分 start=================================================
-- --更新服务地址配置
-- local configFilePath = "config/autoupdater/paracraft_win32.xml"
-- local __AutoUpdater__ = NPL.load("AutoUpdater");
-- local __AutoUpdaterState__ = __AutoUpdater__.State;

function UpdateSyncer:initServer()
    if self._type==ConType.server then 
        return
    end
    LOG.std(nil, "info", "UpdateSyncer.s", "开启局域网更新服务器 myIp:%s",NPL.GetExternalIP());
    --服务端初始化参数
    self._type = ConType.server
    self._uploadTaskList = {} --收到的客户端下载请求队列
    self._isUploading = false
    self._isFree = true;--当前服务器是否空闲，只有第一个来问的客户端会得到true返回，直至向该客户端推送完成或者中途出错

    self:StartWebServer()

    if self.timer_0~=nil then
        self.timer_0:Change()
    end

    self:initMsgBind()

    
    self.timer_0 = commonlib.Timer:new({callbackFunc = function() --不停的广播告诉局域网内的电脑，我是更新服务器，以便自动连接
        self:_sendBoradcast()
    end});
    self.timer_0:Change(1000*1, 1000*5);

    self._net:StartServer()
end

function UpdateSyncer:_sendBoradcast()
    if self._type ~= ConType.server then
        -- print("_sendBoradcast return 1")
        return
    end
    if self._isUploading then --改成每次只对一个客户端负责
        -- print("_sendBoradcast return 2")
        return
    end
    if not self._isFree then
        -- print("self is not free 不广播")
        return
    end
    
    local profile = KeepWorkItemManager.GetProfile()
    profile = profile or {}
    local taskSize = 0
    for k,v in pairs(self._uploadTaskList) do
        taskSize = taskSize + v.file_size
    end
    if taskSize>MAX_UPLOAD_SIZE then --当前任务量超过最大任务量的，就不主动招惹客户端了
        return
    end
    local obj = {
        ver = self:getVersionByPath(CommonLib.GetRootDirectory()),
        username = profile.username,
        userid = profile.id,
        cellphone = profile.cellphone,
        taskSize = taskSize
    }
    Broadcast:SendBroadcaseMsg(MSG_SERVER_BROADCAST,obj)
end

function UpdateSyncer:StartWebServer(ip, port)
    ip = ip or "0.0.0.0";
    port = port or DefaultPort;
    NPL.load("(gl)script/apps/WebServer/WebServer.lua");
    print(string.format("StartWebServer %s:%s", ip, port));
    return WebServer:Start("script/apps/WebServer/admin", ip, port)
end

--服务器监听
function UpdateSyncer:initMsgBind()
    --被询问是否空闲
    self._net:Register("CheckIsFree",function(msg)
        local ret = self._isFree
        self._isFree = false
        LOG.std(nil, "info", "UpdateSyncer.s", "self CheckIsFree? %s,clientIp:%s", ret and "true" or "false",msg.myIp);
        return ret
    end)
    --被当前客户端告知下载完成
    self._net:Register("IsDownloadFinish",function(msg)
        LOG.std(nil, "info", "UpdateSyncer.s", "收到 IsDownloadFinish,变空闲,clientIp:%s",msg.myIp);
        self._isFree = true
        self:_sendBoradcast()
        return ret
    end)

    --收到请求清单文件
    self._net:Register("manifestReq",function(msg)
        -- print("-----收到请求 manifestReq")
        -- echo(msg,true)
        return {
            downloadlist = self.downloadlist,
            deletelist = self.deletelist,
        }
    end)

    --收到请求下载一个文件
    self._net:Register("DownloadReq",function(obj)
        local taskSize = 0
        for k,v in pairs(self._uploadTaskList) do
            taskSize = taskSize + v.file_size
        end
        local ret = {
            taskSize = taskSize
        }
        self._curLeftNum = obj.leftNum --不算这次这个，当前客户端，还有几个文件需要下载
        -- if taskSize>MAX_UPLOAD_SIZE and not obj.force then --此服务器当前任务量超过最大任务量，就不响应新的下载请求，让客户端另请高明,force表示无论如何要通融一下
        --     ret.access = false
        -- else
            commonlib.TimerManager.SetTimeout(function()
                table.insert(self._uploadTaskList,obj)
                LOG.std(nil, "info", "UpdateSyncer.s", "收到下载请求,name:%s,客户端:%s,当前任务数量:%s", obj.file_name,obj.myIp,self._curLeftNum+1);
                self:CheckUploadToClient() --延时再开始推送文件
            end,1)
            ret.access = true
        -- end
        return ret
    end)

    --客户端某个环节下载出错了，收到这个释放当前服务端
    self._net:Register("downloadError",function(msg)
        self._isFree = true;
        LOG.std(nil, "error", "UpdateSyncer.s", "downloadError ,set _isFree=true");
        self:_sendBoradcast()
    end)
end

--是否有推送文件任务，有的话执行
function UpdateSyncer:CheckUploadToClient()
    if #self._uploadTaskList==0 then
        return
    end
    
    if self._isUploading then
        return
    end
    
    local obj = table.remove(self._uploadTaskList,1)
    
    if obj then
        self._isUploading = true
        local key = obj.key
        local file_path = CommonLib.ToCanonicalFilePath(CommonLib.GetRootDirectory()..obj.file_name)
        obj.file_content = CommonLib.GetFileText(file_path)
        -- print("-------服务器主动推送文件：")echo(obj,true)
        LOG.std(nil, "info", "UpdateSyncer.s", "upload file:%s,clientIp:%s", obj.file_name,obj.myIp);
        local _timer;
        _timer = commonlib.TimerManager.SetTimeout(function()
            LOG.std(nil, "waring", "UpdateSyncer.s", "upload timeout:%s,clientIp:%s", obj.file_name,obj.myIp);
            --上传文件超时
            self._net:CheckClientAlive(key,function(alive)
                LOG.std(nil, "waring", "UpdateSyncer.s", "timeout,client is alive? %s", alive and "true" or "false");
                if alive then
                    _timer = commonlib.TimerManager.SetTimeout(function() --再给1分钟，不行咱就别浪费时间了
                        self:onClientError()
                    end,1000*60)
                else
                    self:onClientError()
                end
            end)
        end,1000*10)
        local success = self._net:CallClientByKey(key,"DownloadRsp",obj,function(result)
            self._isUploading = false
            -- print("-----推送文件成功",obj.file_name)
            self:CheckUploadToClient()
            _timer:Change()
        end)
        if not success then
            print("error 找不到该客户端 key:",key,obj.file_name)
            self._isUploading = false
            self:CheckUploadToClient()
            _timer:Change()
        end
    end
end

function UpdateSyncer:onClientError()
    self._isUploading = false
    self._isFree = true
    LOG.std(nil, "error", "UpdateSyncer.s", "onClientError wait retry");
    self:_sendBoradcast()
end

--需要同步哪些文件，列个清单出来，返回给客户端
function UpdateSyncer:getKeyFileList(bin_files)
    local root = CommonLib.ToCanonicalFilePath(CommonLib.GetRootDirectory());
    
    local launcherExe,isContain = System.options.launcherExeName or "ParaCraft.exe",false
    for k,v in pairs(bin_files) do
        if v==launcherExe then
            isContain = true
            break;
        end
    end
    if not isContain then --确保launcher是同一个
        table.insert(bin_files,launcherExe)
    end

    local list = {}
    local function addFilePath(path)
        table.insert(list,path)
    end
    for _,_filename in pairs(bin_files) do
        local _path = root.._filename
        local temp = CommonLib.GetFileList(_path,true,true)
        for k,v in ipairs(temp) do
            if v.file_size>0 then
                table.insert(list,v)
            end
        end
    end

    local size = string.len(CommonLib.GetDirectory(root));
    for _, item in ipairs(list) do
        item.file_path = CommonLib.ToCanonicalFilePath(item.file_path)
        item.file_name = string.sub(item.file_path, size + 1);   -- 相对路径
        item.file_rel_path = nil
        item.file_path = nil
    end

    -- list = {
    --     {
    --         file_md5="f107e29fdb0638488d5936dcb776ab9e",
    --         file_name="version.txt",
    --         file_size=11 
    --     }
    -- }
    return list
end

--=================================================服务器部分 end=================================================

--=================================================客户端部分 start=================================================
function UpdateSyncer:initClient()
    if self._type==ConType.client then 
        return
    end
    self._myIp = NPL.GetExternalIP()
    LOG.std(nil, "info", "UpdateSyncer", "初始化局域网更新客户端 myIp:%s",self._myIp);
    --客户端初始化参数
    self._type = ConType.client
    self._remoteVer = nil; --远程版本号
    self._allDownloadList = nil --需要下载的列表
    self._downloadingList = nil --正在下载的列表
    self._downloadFailList = {} --失败列表
    self._downloadState = DownloadState.none

    self._onBroadcast = function(msg)
        if self._type ~= ConType.client then
            return
        end
        Broadcast:RemoveBroadcaseEvent(MSG_SERVER_BROADCAST,self._onBroadcast) --广播每次只监听一次，除非下载失败，会再次监听
        local ip = msg.ip
        local port = msg.port
        local data = msg.__data__.msg
        local remoteVer = data.ver
        local taskSize = data.taskSize --发消息这个服务器，当前的下载任务大小（用来排序，选择负担最小的服务器进行下载）
                
        local localVer = self:getVersionByPath(CommonLib.GetRootDirectory())
        if CommonLib.CompareVer(localVer,remoteVer)<0 then --有更新
            self._remoteVer = remoteVer
            self._hasUpdate = true
            self.ShowPage()
            
            self:checkConnectServer(ip,port,taskSize) --可能会处理多次,因为每个客户端下载完成以后，也会变成服务器
        end
    end
    --接收教师服务器的广播
    Broadcast:RegisterBroadcaseEvent(MSG_SERVER_BROADCAST,self._onBroadcast)

    self._net:Register("DownloadRsp",function(msg)
        self:_onDownloadRsp(msg)
    end)

    if self._hasUpdate then --之前就确定过，局域网存在更新源
        self.ShowPage()
        self.UpdateProgressText(L"正在查找更新源..")
    end
end

function UpdateSyncer:IsAllDownloadFinished()
    return self._downloadState == DownloadState.allFinished
end

--是否正在下载
function UpdateSyncer:HasStartDownload()
    return self._downloadState ~= DownloadState.none
end

--收到服务器推送的文件
function UpdateSyncer:_onDownloadRsp(obj)
    if self._timeout then --取消超时监听
        self._timeout:Change()
        self._timeout=  nil
    end

    local filepath = self:_getDownloadPath(obj.file_name)
    CommonLib.WriteFile(filepath, obj.file_content);
    local md5 = CommonLib.GetFileMD5(filepath)

    -- 
    -- print("下载返回,filepath",filepath,"md5",md5,"size",CommonLib.GetFileSize(filepath))
    if md5==obj.file_md5 then
        self._downloadState = DownloadState.finish_one
    else
        self._downloadState = DownloadState.finish_one
        print("-------下载的文件md5不对")
        obj.file_content = nil
        echo(obj,true)
        table.insert(self._downloadFailList,self._curDobj)
        ParaIO.DeleteFile(filepath)
    end
    self:checkDownloadingOne()
end

--检查是否有下载任务，有的话去下载
function UpdateSyncer:checkDownloadingOne()
    if self._downloadingList==nil then --未知错误
        return
    end
    if self._downloadState == DownloadState.deal_one then --一次下载一个
        return
    end

    if #self._downloadingList==0 then --要下载的下载完了
        if #self._downloadFailList>0 then
            self._downloadFailList = {}
            self:OnDownloadFailed()
        else
            self:OnDownloadFinish()
        end
        return
    end
    local _totalSize = 0 --总需要下载的大小
    for k,v in ipairs(self._allDownloadList) do
        _totalSize = _totalSize + v.file_size
    end

    local leftSize = 0; --还没下载的大小
    for k,v in ipairs(self._downloadingList) do
        leftSize = leftSize + v.file_size
    end
    local progress = (_totalSize-leftSize)/_totalSize
    
    self._curDobj = self._downloadingList[1] --当前正在下载的任务
    self.UpdateProgressText(string.format(L"正在下载(%d/%d):%s",#self._allDownloadList-#self._downloadingList+1,#self._allDownloadList,self._curDobj.file_name))
    
    self._curDobj.key = self._key --这个key其实是服务器用来标记连接来源客户端的
    self._curDobj.myIp = self._myIp
    self._curDobj.leftNum = #self._downloadingList-1 --不算当前这个，剩余任务数量
    
    local filepath = self:_getDownloadPath(self._curDobj.file_name)
    if ParaIO.DoesFileExist(filepath) and CommonLib.GetFileMD5(filepath)==self._curDobj.file_md5 then
        -- print("-----已经有了不需要下载",self._curDobj.file_name)
        table.remove(self._downloadingList,1)
        self:checkDownloadingOne()
    else
        -- print("-----下载单个:")echo(self._curDobj,true)
        -- print("请求下载：",self._curDobj.file_name)
        ParaIO.DeleteFile(filepath)
        --返回是异步的，服务器不即时返回，而是维护队列，通过发送DownloadRsp返回文件内容
        self._net:Call("DownloadReq",self._curDobj,function(ret)
            if ret.access then--有余力处理这个下载请求
                self._downloadState = DownloadState.deal_one
                table.remove(self._downloadingList,1)
            else --返回false表示服务器没空处理这个下载请求，另请高明，或者等一下再请求
                self:checkDownloadingOne()
            end
        end)
        
        self._timeout = commonlib.TimerManager.SetTimeout(function()
            self:onDownloadTimeOut()
        end,1000*20,"onDownloadTimeOut")
    end
end

--下载超时，请求发上去超过10秒还没返回
--检验一下是不是服务器挂了，挂了的话，重新来
function UpdateSyncer:onDownloadTimeOut()
    local _onCheckAlive
    _onCheckAlive = function(alive)
        print("------超时，检查服务器可用结果",alive)
        if alive then --服务器是可用的，可能这个文件单纯的大而已,再等30秒,还下载不下来，就重新打开服务器监听
            self._timeout = commonlib.TimerManager.SetTimeout(function()
                _onCheckAlive(false)
            end,1000*30,"onDownloadTimeOut")
        else
            self.UpdateProgressText(L"下载超时,稍后自动重试...")
            self._downloadingList = {}
            for k,v in ipairs(self._allDownloadList) do
                self._downloadingList[k] = v
            end
            self._downloadState = DownloadState.failed
            Broadcast:RegisterBroadcaseEvent(MSG_SERVER_BROADCAST,self._onBroadcast) --重新注册广播，允许新的服务器介入
        end
    end
    self._net:CheckServerAlive(_onCheckAlive)
    
end

function UpdateSyncer:_getDownloadPath(filename)
    filename = filename or ""
    local path = CommonLib.ToCanonicalFilePath(CommonLib.GetRootDirectory()..CLIENT_CAHCE_PATH..self._remoteVer.."/"..filename)
    return path
end

--所有下载完成了，使用launcher应用
function UpdateSyncer:OnDownloadFinish()

    self._net:Call("IsDownloadFinish",{
        myIp = self._myIp
    },function(ret)
        LOG.std(nil, "info", "UpdateSyncer", "已经通知服务器，我下完了 IsDownloadFinish");
    end)

    local launcherExe = System.options.launcherExeName or "ParaCraft.exe"
    local root = CommonLib.GetRootDirectory()
    local storagePath = CommonLib.ToCanonicalFilePath(root.."caches/")
    self._downloadState = DownloadState.allFinished
    self.RefreshPage()
    
    local progress = 1
    GameLogic.AddBBS(nil,"文件同步完成")

    --生成lan_apply.manifest 和 lan_applyVer.txt,方便调起Launcher 应用更新
    local len = #self._allDownloadList
    local arr = {}
    for i=1,len do
        local obj = self._allDownloadList[i]
        
        local url = string.format("xxx/%s,%s,%s.p",obj.file_name,obj.file_md5,obj.file_size)
        local path = string.format("caches/%s/%s",self._remoteVer,obj.file_name)
        local tab = {
            url,
            path,
            obj.file_name,
            tostring(true),
            tostring(true),
        }
        local line = table.concat(tab,"|")
        if ParaIO.DoesFileExist(self:_getDownloadPath(obj.file_name)) then
            
            if obj.file_name==launcherExe then --Launcher直接先复制过去,剩下的文件，再来由launcher复制
                local targetPath = root..obj.file_name
                print("-----move launcher to:",targetPath)
                if(not ParaIO.MoveFile(path, targetPath))then
                    print("-------move launcher failed")
                end
            else
                table.insert(arr,line)
            end
        else
            print("-----下载有误",self:_getDownloadPath(obj.file_name))
            self:OnDownloadFailed()
            return
        end
        
    end

    local str = table.concat(arr,"\r\n")

    local applyManifestFile = storagePath.."lan_apply.manifest"
    local file = ParaIO.open(applyManifestFile, "w");
    if(file:IsValid()) then
        file:WriteString(str);
        file:close();
    end

    local latest_version = self._remoteVer;
    local applyVerFile = storagePath.."lan_applyVer.txt"
    file = ParaIO.open(applyVerFile, "w");
    if(latest_version and file:IsValid()) then
        local content = string.format("ver=%s\n",latest_version);
        file:WriteString(content);
        file:close();
    end

    local isFixMode = false
    local cmdStr = string.format("isFixMode=%s justNeedCopy=true applyManifestFile=%s applyVerFile=%s",tostring(isFixMode),applyManifestFile,applyVerFile)
    
    self.ShowPage()
    self.UpdateProgressText(L"文件同步完成"..self.realLatestVersion)
    
    if ClientUpdateDialog.SetIsDownloadFinished then
        ClientUpdateDialog.SetIsDownloadFinished()
        DownloadWorld.Close()
    end
    if self.isAutoInstall then
        self:onBtnApply()
    else
        print("--cmdStr",cmdStr)
    end
end

function UpdateSyncer:OnDownloadFailed()
    print("------局域网下载失败,去重新连接服务器:")
    self.ShowPage()
    self.UpdateProgressText(L"下载发生错误,稍后自动重试...")
    self._downloadState = DownloadState.failed
    
    self._downloadingList = {}
    for k,v in ipairs(self._allDownloadList) do
        self._downloadingList[k] = v
    end
    Broadcast:RegisterBroadcaseEvent(MSG_SERVER_BROADCAST,self._onBroadcast) --重新注册广播，允许新的服务器介入
    self._net:Call("downloadError")
end

--作为客户端，去连接服务器、登录、下载清单文件、开始同步更新
function UpdateSyncer:checkConnectServer(ip,port,taskSize)
    if self._downloadState == DownloadState.allFinished then --已经下载完了
        return false
    end
    self.UpdateProgressText(L"正在连接更新源..")
    LOG.std(nil, "info", "UpdateSyncer", "checkConnectServer,ip:%s,port:%s", ip,port);
    local onGetKeyFileManifest;
    onGetKeyFileManifest = function (msg)
        self._allDownloadList = msg.downloadlist
        self._downloadingList = {}
        for k,v in ipairs(self._allDownloadList) do
            self._downloadingList[k] = v
        end
        self.UpdateProgressText(L"开始同步文件...")
        self:checkDownloadingOne()
        -- print("--------manifestReq 返回")
        -- echo(msg,true)
        if UpdateSyncer.needShowDownloadWorldUI then
            DownloadWorld.ShowPage(L"局域网")
        end
    end
    local _timer;
    local function onLoginSuccess()
        _timer:Change()
        local nid = self._net:GetClientNid() --当前连接的，服务器的地址
        local key = self._net:GetServerKey() --当前连接的，对于服务器来讲的，我的key
        self._key = key
        LOG.std(nil, "info", "UpdateSyncer", "onLoginSuccess self._downloadState:%s", tostring(self._downloadState));
        if self._downloadState == DownloadState.none or self._downloadState == DownloadState.failed then --只有没有开始下载的情况下处理
            self.UpdateProgressText(L"正在检查服务器状态...")
            --检测当前是否在空闲状态，只有第一个收到这条广播的客户端，才能继续往下处理
            self._net:Call("CheckIsFree",{key=key,myIp=self._myIp},function(isFree)
                LOG.std(nil, "info", "UpdateSyncer", "server isFreee? %s,serverIp:%s", isFree and "true" or "false",ip);
                if isFree then
                    self.UpdateProgressText(L"正在获取清单文件...")
                    self._net:Call("manifestReq",{},onGetKeyFileManifest)
                else
                    self.UpdateProgressText(L"等待新的更新源...")
                    Broadcast:RegisterBroadcaseEvent(MSG_SERVER_BROADCAST,self._onBroadcast)
                end
            end)
        else --正在下载呢
            self._net:CheckServerAlive(function(alive) --有可能原来的服务器挂了,要重新开始连服务器
                if not alive then
                    LOG.std(nil, "info", "UpdateSyncer", "当前服务器不可用,重新开启监听");
                    self:OnDownloadFailed()
                end
            end)
        end
    end

    self._net:StartClient(ip,port,onLoginSuccess) --连接服务器并发起登录
    
    _timer = commonlib.TimerManager.SetTimeout(function() --连接超时
        self._downloadState = DownloadState.none
        Broadcast:RegisterBroadcaseEvent(MSG_SERVER_BROADCAST,self._onBroadcast) --重新注册广播，允许新的服务器介入
    end,1000*3)
    return true
end


--获取路径下，version.txt的版本号
function UpdateSyncer:getVersionByPath(parentPath)
    if not ParaIO.DoesFileExist(parentPath) then
        print(string.format("path:%s 不存在,set ver=0.0.0",parentPath))
        return "0.0.0"
    end
    local version_filename = CommonLib.ToCanonicalFilePath(parentPath .. "/version.txt");
    -- print("_versionByPath :",version_filename)
    if not ParaIO.DoesFileExist(version_filename) then
        print(string.format("txt:%s 不存在,set ver=0.0.0",version_filename))
        return "0.0.0"
    end
    local version = CommonLib.GetFileText(version_filename) or "ver=0.0.0";
    version = string.gsub(version,"[%s\r\n]","");
    local __,v = string.match(version,"(.+)=(.+)");
    return v;
end

--=================================================客户端部分 end=================================================

UpdateSyncer:InitSingleton():Init();


--[[
更新流程：
    在外围，判断自身已经是最新版后，通过 start_lan_server 开启局域网服务端，并先去cdn下载最新的全量更新清单文件，
然后开始在局域网内开启定时广播，告知局域网内的其他机器，这里已经作为局域网更新服务器开启了。
    在外围判断自己不是最新版时，除了显示正常更新弹框意外，还通过 start_lan_client 开启局域网客户端，并监听服务端的广播，
收到服务器的广播，就去尝试连接(只有第一个连接的客户端会连接成功，因为一旦与一个客户端连接成功，服务器会被置为非空闲状态，直至该客户端下载完成或者下载超时。)
连接上服务器后，先请求清单文件，然后按照清单文件一个个的下载，下载完成以后，唤起launcher进行应用更新（所以必须是430版launcher）
    客户端下载完毕并应用更新再次启动后，同样会作为服务端开启

]]