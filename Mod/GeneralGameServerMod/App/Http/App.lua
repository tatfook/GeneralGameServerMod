
--[[
Title: App
Author(s):  wxa
Date: 2021-06-23
Desc: Http
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Http/App.lua");
------------------------------------------------------------
]]

local Http = NPL.load("Mod/GeneralGameServerMod/Server/Http/Http.lua");

local App = commonlib.inherit(Http, NPL.export());

App:AddVirtualDirectory("/statics", "Mod/GeneralGameServerMod/App/Http/Statics");

-- 启用跨域
App:UseCors();

function App:GetServers()
    return SERVERS;
end

App:Get("/", function(ctx)
    ctx:Send(App:GetServers());
end)

-- jian
App:Get("/heartbeat", function(ctx)
    return ctx:Send("OK");
end);

App:Get("/test", function(ctx)
    print(os.execute("ls"));
end)

-- print("================================start http server================================", __rts__:GetName())
-- System.os.run()
-- curl -I -m 10 -o /dev/null -s -w %{http_code} http://127.0.0.1:9000/heartbeat