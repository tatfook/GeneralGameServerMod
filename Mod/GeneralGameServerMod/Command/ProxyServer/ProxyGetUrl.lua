--[[
Title: ProxyGetUrl
Author(s):  wxa
Date: 2020-06-12
Desc: Command
use the lib:
------------------------------------------------------------
local ProxyGetUrl = NPL.load("Mod/GeneralGameServerMod/Command/ProxyServer/ProxyGetUrl.lua");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/os/GetUrl.lua");

local ProxyGetUrl = NPL.export();

local __System_os_GetUrl__ = System.os.GetUrl;
local __proxy_handler__ = {};

System.os.GetUrl = function(url, callbackFunc, option)
    local options = nil;
    if (type(url) == "table") then
        options = url;
        url = options.url;
    else 
        options = {};
    end
    options.url = url;
    options.method = options.method or "GET";
    options.headers = options.headers or {};
    -- options.headers["X-Server-Type"] = "GGS_HTTP";

    -- 只代理Get请求
    local proxy_options = ProxyGetUrl.GetProxyOptions(options);
    local is_proxy = proxy_options ~= options;

	LOG.std(nil, "debug", "ProxyGetUrl", options);

    __System_os_GetUrl__(proxy_options, function(rcode, msg, data)
        -- 没有代理或已代理且存在返回
        if (not is_proxy or rcode ~= 0) then return type(callbackFunc) == "function" and callbackFunc(rcode, msg, data) end
        -- 代理服务器未处理
        if (rcode == 0) then return __System_os_GetUrl__(options, callbackFunc, option) end 
    end, option);
end

function ProxyGetUrl.RegisterProxyHandler(callback)
    __proxy_handler__[callback] = callback;
end 

function ProxyGetUrl.RemoveProxyHandler(callback)
    __proxy_handler__[callback] = nil;
end

function ProxyGetUrl.SetSystemOsGetUrl(geturl)
    __System_os_GetUrl__ = geturl;
end

function ProxyGetUrl.GetProxyOptions(options)
    local __is_allow_proxy_get_url__ = options.__is_allow_proxy_get_url__ == nil or options.__is_allow_proxy_get_url__ == true;
    options.__is_allow_proxy_get_url__ = nil;

    if (not __is_allow_proxy_get_url__ or string.upper(options.method) ~= "GET") then return options end 

    for _, callback in pairs(__proxy_handler__) do
        local proxy_options = callback(options);
        if (proxy_options) then return proxy_options end 
    end

    return options;
end

-- __System_os_GetUrl__({
--     url = "http://127.0.0.1:8099/heartbeat",
--     method = "GET",
--     headers = {
--         ["X-Server-Type"] = "GGS_HTTP",
--     },
-- }, function(rcode, msg, data)
--     print("===========================", rcode)
-- end);

