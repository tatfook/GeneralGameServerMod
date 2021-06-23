--[[
Title: Http
Author(s):  wxa
Date: 2021-06-23
Desc: Http
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Http/Http.lua");
------------------------------------------------------------
]]

local Util = NPL.load("./Util.lua", IsDevEnv);
local MimeType = NPL.load("./MimeType.lua", IsDevEnv);

local Http = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Http:Property("NeuronFile", "Mod/GeneralGameServerMod/Http/Http.lua");
Http:Property("Port", 8888);
Http:Property("Ip", "0.0.0.0");

function Http:ctor()
end

function Http:Init(options)
    -- 指定Http接口文件
    NPL.AddPublicFile(self:GetNeuronFile(), -10);
end

function Http:Start()
    NPL.StartNetServer(self:GetIp(), tostring(self:GetPort()));
end

function Http:OnActivate(msg)

end

-- 单列模式
Http:InitSingleton():Init();

NPL.this(function()
    Http:OnActivate(msg);
end)