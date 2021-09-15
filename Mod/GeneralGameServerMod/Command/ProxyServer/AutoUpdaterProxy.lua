--[[
Title: AutoUpdaterProxy
Author(s):  wxa
Date: 2020-06-12
Desc: Command
use the lib:
------------------------------------------------------------
local AutoUpdaterProxy = NPL.load("Mod/GeneralGameServerMod/Command/ProxyServer/AutoUpdaterProxy.lua");
------------------------------------------------------------
]]

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local Http = NPL.load("Mod/GeneralGameServerMod/Server/Http/Http.lua");
local ProxyGetUrl = NPL.load("./ProxyGetUrl.lua");
local FileCache = NPL.load("./FileCache.lua");

local AutoUpdaterProxy =  commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local __filecache__ = FileCache:new():Init();
local __System_os_GetUrl__ = System.os.GetUrl;

function AutoUpdaterProxy.SetSystemOsGetUrl(geturl)
    __System_os_GetUrl__ = geturl;
end

function AutoUpdaterProxy:GetFile(url, callback)
    local cache_filename = CommonLib.MD5(url);
    local text = __filecache__:GetFileCacheText(cache_filename);
    if (text ~= nil) then return type(callback) == "function" and callback(text) end 
    __System_os_GetUrl__(url, function(rcode, msg, data)
        if (rcode ~= 200) then return type(callback) == "function" and callback(nil) end
        __filecache__:AddFileCache(cache_filename, data, true);
        return type(callback) == "function" and callback(data);
    end);
end

function AutoUpdaterProxy:StartProxy(ip, port)
    local host = string.format("http://%s:%s", ip, port);
    local function GetUrlProxy(options)
        local url = options.url;
        if ((string.match(url, "^http[s]?://[^/]+/version.php")) or 
            (string.match(url, "^http[s]?://[^/]+/update61/coredownload/list/full.p")) or 
            (string.match(url, "^http[s]?://[^/]+/update61/coredownload/[^/]+/list/full.p"))) then
            return {
                -- headers = { ["X-Server-Type"] = "GGS_HTTP"},
                method = "GET",
                url = string.gsub(string.gsub(url, "^(http[s]?://[^/]+)", host), "%?(.*)", ""),
                qs = {src_url = url},
            };
        end
    end

    ProxyGetUrl:RegisterProxyHandler(GetUrlProxy);
    self.__GetUrlProxy__ = GetUrlProxy;
end

function AutoUpdaterProxy:StopProxy()
    if (not self.__GetUrlProxy__) then return end
    ProxyGetUrl:RemoveProxyHandler(self.__GetUrlProxy__);
    self.__GetUrlProxy__ = nil;
end

AutoUpdaterProxy:InitSingleton();

local function ProxyHandler(ctx)
    local src_url = ctx:GetParams()["src_url"];
    LOG.std(nil, "debug", "AutoUpdaterProxy", src_url);
    if (not src_url) then return ctx:GetResponse():Err_404() end 
    AutoUpdaterProxy:GetFile(src_url, function(content)
        if(not content) then return ctx:GetResponse():Err_404() end 
        ctx:Set("Content-Length", #content);
        ctx:Set("Content-Type", "application/x-binary");
        ctx:Set("Content-Transfer-Encoding", "binary");
        ctx:Send(content, 200);
    end);
end

Http:Get("/version.php", ProxyHandler);
Http:Get("/update61/coredownload/list/full.p", ProxyHandler);
Http:Get("/update61/coredownload/:version/list/full.p", ProxyHandler);

-- http://tmlog.paraengine.com/version.php