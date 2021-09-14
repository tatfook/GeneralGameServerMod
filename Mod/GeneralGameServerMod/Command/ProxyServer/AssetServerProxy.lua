--[[
Title: AssetServerProxy
Author(s):  wxa
Date: 2020-06-12
Desc: Command
use the lib:
------------------------------------------------------------
local AssetServerProxy = NPL.load("Mod/GeneralGameServerMod/Command/ProxyServer/AssetServerProxy.lua");
AssetServerProxy.GetFile("texture/whitedot.png.p,dcd40f18341aba7f389ee0c7d57d02d1,94", function(content)
end)
------------------------------------------------------------
]]
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local Http = NPL.load("Mod/GeneralGameServerMod/Server/Http/Http.lua");

local FileCache = NPL.load("./FileCache.lua");

local __filecache__ = FileCache:new():Init();
local __System_os_GetUrl__ = System.os.GetUrl;
local __System_Asset_Server_Url__ = ParaAsset.GetAssetServerUrl();
local __Current_Asset_Server_Url__ = __System_Asset_Server_Url__;

local AssetServerProxy = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

function AssetServerProxy.SetSystemOsGetUrl(geturl)
    __System_os_GetUrl__ = geturl;
end

function AssetServerProxy:GetAssetServerUrl()
    return __Current_Asset_Server_Url__;
end

function AssetServerProxy:SetAssetServerUrl(assetServerUrl)
    if (not assetServerUrl or __Current_Asset_Server_Url__ == assetServerUrl) then return end 
    __Current_Asset_Server_Url__ = assetServerUrl;
    ParaAsset.SetAssetServerUrl(__Current_Asset_Server_Url__);
end

function AssetServerProxy:StartProxy(ip, port)
    self:SetAssetServerUrl(string.format([[http://%s:%s/paracraft_asset_server_proxy?filename=/]], ip, port));
end

function AssetServerProxy:StopProxy()
    self:SetAssetServerUrl(__System_Asset_Server_Url__);
end

function AssetServerProxy:GetFile(filename, callback)
    local cache_filename = CommonLib.MD5(filename);
    local text = __filecache__:GetFileCacheText(cache_filename);
    if (text ~= nil) then return type(callback) == "function" and callback(text) end 
    __System_os_GetUrl__(__System_Asset_Server_Url__ .. filename, function(rcode, msg, data)
        if (rcode ~= 200) then return type(callback) == "function" and callback(nil) end
        __filecache__:AddFileCache(cache_filename, data, true);
        return type(callback) == "function" and callback(data);
    end);
end

AssetServerProxy:InitSingleton();

Http:Get("/paracraft_asset_server_proxy", function(ctx)
    local params = ctx:GetParams();
    local filename = params.filename and string.gsub(params.filename, "^/", "");
    if (not filename) then return ctx:GetResponse():Err_404() end 
	LOG.std(nil, "debug", "AssetServerProxy", filename);
    AssetServerProxy:GetFile(filename, function(content)
        if(not content) then return ctx:GetResponse():Err_404() end 
        ctx:Set("Content-Length", #content);
        ctx:Set("Content-Type", "application/x-binary");
        ctx:Set("Content-Transfer-Encoding", "binary");
        ctx:Send(content, 200);
    end);
end);


-- AssetServerProxy:GetFile("texture/aquarius/common/multilineeditbox_32bits.png.p,2a0d25b655c78418da191394fdb8ac0c,194", function(content)
--     print("-----------------------", #content)
-- end);

-- __System_os_GetUrl__({
--     url = "http://127.0.0.1:8099/paracraft_asset_server_proxy?filename=/texture/aquarius/common/multilineeditbox_32bits.png.p,2a0d25b655c78418da191394fdb8ac0c,194",
--     method = "GET",
--     headers = {
--         ["X-Server-Type"] = "GGS_HTTP",
--     }
-- }, function(rcode, msg, data)
--     print("-----------------------", #data)
-- end);