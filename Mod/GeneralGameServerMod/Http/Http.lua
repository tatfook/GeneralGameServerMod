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
local Request = NPL.load("./Request.lua", IsDevEnv);
local Response = NPL.load("./Response.lua", IsDevEnv);
local Context = NPL.load("./Context.lua", IsDevEnv);
local Router = NPL.load("./Router.lua", IsDevEnv);

local Http = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Http:Property("NeuronFile", "Mod/GeneralGameServerMod/Http/Http.lua");
Http:Property("Port", 8888);
Http:Property("Ip", "0.0.0.0");

function Http:ctor()
    self.middlewares = {};
end

function Http:Init()
    -- 指定Http接口文件
    NPL.AddPublicFile(self:GetNeuronFile(), -10);
end

-- 启动服务器
function Http:Start()
    NPL.StartNetServer(self:GetIp(), tostring(self:GetPort()));
end

-- 注册路由
function Http:Get(path, callback)
    Router:Router(path, callback, "GET");
end

function Http:Post(path, callback)
    Router:Router(path, callback, "POST");
end

function Http:Del(path, callback)
    Router:Router(path, callback, "DELETE");
end

function Http:All(path, callback)
    Router:Router(path, callback, "ALL");
end

function Http:Router(path, callback, description)
    Router:Router(path, callback, description);
end

-- 请求处理函数
function Http:Handle(ctx)
    local middlewares = self.middlewares;
    local function handle(ctx, index)
        if (ctx:IsFinished()) then return end

        index = index or 1;
        if (index > #middlewares) then
            -- 中间件处理完成 执行控制器逻辑
            Router:Handle(ctx);
        else
            -- 执行中间件逻辑
            (middlewares[index])(ctx, function() handle(ctx, index + 1) end);
        end
    end
    handle(ctx);
end

-- 注册中间件
function Http:Use(callback)
    table.insert(self.middlewares, callback);
    return self;
end

function Http:OnActivate(msg)
    if (type(msg) ~= "table") then return end
    
    local request = Request:new():Init(msg);
    local response = Response:new():Init(request);
    local context = Context:new():Init(request, response);

	self:Handle(context);
end

-- 单列模式
Http:InitSingleton():Init();

NPL.this(function()
    Http:OnActivate(msg);
end)