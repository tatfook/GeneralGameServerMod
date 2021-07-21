--[[
Title: Http
Author(s):  wxa
Date: 2021-06-23
Desc: Http
use the lib:
------------------------------------------------------------
local Http = NPL.load("Mod/GeneralGameServerMod/Server/Http/Http.lua");
------------------------------------------------------------
]]

local Util = NPL.load("./Util.lua", IsDevEnv);
local MimeType = NPL.load("./MimeType.lua", IsDevEnv);
local Request = NPL.load("./Request.lua", IsDevEnv);
local Response = NPL.load("./Response.lua", IsDevEnv);
local Context = NPL.load("./Context.lua", IsDevEnv);
local Router = NPL.load("./Router.lua", IsDevEnv);

local Cors = NPL.load("./Middleware/Cors.lua", IsDevEnv);

local Http = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Http:Property("NeuronFile", "Mod/GeneralGameServerMod/Server/Http/Http.lua");
Http:Property("StaticDirectory");  -- 静态文件目录
Http:Property("Port", 9000);
Http:Property("Ip", "0.0.0.0");

function Http:ctor()
    self.middlewares = {};
    self.virtual_directory = {};
end

function Http:Init()
    -- 指定Http接口文件
    NPL.AddPublicFile(self:GetNeuronFile(), -10);

    self:UseCors();
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

-- 添加虚拟目录 静态文件目录
function Http:AddVirtualDirectory(path, directory)
    self.virtual_directory[path] = directory;
end

function Http:HandleStaticFile(ctx)
    local method = ctx:GetMethod();
    local path = ctx:GetPath();
    local filepath = nil;

    for static_path, dir in pairs(self.virtual_directory) do
        if (string.find(path, static_path, 1, true)) then
            filepath = dir .. string.sub(path, string.len(static_path) + 1);
        end
    end

    if (not filepath) then return end
    ctx:SendFile(filepath);
end

-- 请求处理函数
function Http:Handle(ctx)
    -- 优先处理静态文件
    self:HandleStaticFile(ctx);
    -- 出来API
    local middlewares = self.middlewares;
    local function handle(ctx, index)
        if (ctx:IsFinished()) then return end

        index = index or 1;
        if (index > #middlewares) then
            -- 中间件处理完成 执行控制器逻辑
            Router:Handle(ctx);
            if (not ctx:IsFinished()) then
                ctx:Send();
            end
        else
            -- 执行中间件逻辑
            local middleware = middlewares[index];
            local isExecNext = false;
            local function next() 
                if (isExecNext) then return end
                isExecNext = true;
                handle(ctx, index + 1)
            end
            if (type(middleware) == "function") then
                middleware(ctx, next);
            elseif (type(middleware) == "table" and type(middleware.Handle) == "function") then
                middleware.Handle(middleware, ctx, next);
            end
            next();
        end
    end
    handle(ctx);
end

-- 注册中间件
function Http:Use(callback)
    if (type(callback) == "table" and type(callback.Handle) == "function") then table.insert(self.middlewares, function(ctx, next) callback:Handle(ctx, next) end) end
    if (type(callback) == "function") then table.insert(self.middlewares, callback) end 
    return self;
end

-- Cors 中间件
function Http:UseCors(options)
    if (self.__cors_callback__) then return self end 

    local __cros__ = Cors:new():Init(options);
    self.__cors_callback__ = function(ctx, next) __cros__:Handle(ctx, next) end
    self:Use(self.__cors_callback__);
    
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