-- /**
--  * CORS middleware
--  * @param {Object} [options]
--  *  - {String|Function(ctx)} origin `Access-Control-Allow-Origin`, default is request Origin header
--  *  - {String|Array} allowMethods `Access-Control-Allow-Methods`, default is 'GET,HEAD,PUT,POST,DELETE,PATCH'
--  *  - {String|Array} exposeHeaders `Access-Control-Expose-Headers`
--  *  - {String|Array} allowHeaders `Access-Control-Allow-Headers`
--  *  - {String|Number} maxAge `Access-Control-Max-Age` in seconds
--  *  - {Boolean} credentials `Access-Control-Allow-Credentials`
--  *  - {Boolean} keepHeadersOnError Add set headers to `err.header` if an error is thrown
--  */

--[[
Title: Cors
Author(s):  wxa
Date: 2021-06-23
Desc: 跨域中间件
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Http/Middleware/Cors.lua");
------------------------------------------------------------
]]

local Cors = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Cors:Property("AllowOrigin");                                     -- Access-Control-Allow-Origin
Cors:Property("AllowMethods", "GET,HEAD,PUT,POST,DELETE,PATCH");  -- Access-Control-Allow-Methods
Cors:Property("ExposeHeaders");   -- Access-Control-Expose-Headers
Cors:Property("AllowHeaders");    -- Access-Control-Allow-Headers
Cors:Property("MaxAge");          -- Access-Control-Max-Age  单位秒
Cors:Property("AllowCredentials");    -- Access-Control-Allow-Credentials


function Cors:ctor()
end

function Cors:Init(options)
    options = options or {};

    self:SetAllowOrigin(options.origin);

    if (type(options.allowMethods) == "table") then
        self:SetAllowMethods(table.concat(options.allowHeaders, ","));
        self:SetAllowMethods(string.upper(self:GetAllowMethods()));
    end

    if (type(options.exposeHeaders) == "table") then
        self:SetExposeHeaders(table.concat(options.exposeHeaders, ","));
    end

    if (type(options.allowHeaders) == "table") then
        self:SetAllowHeaders(table.concat(options.allowHeaders, ","))
    end

    if (type(options.credentials) == "function") then
        self:SetAllowCredentials(options.credentials);
    else
        self:SetAllowCredentials(not (not options.credentials));
    end

    if (options.maxAge) then self:SetMaxAge(tostring(options.maxAge)) end

    return self;
end

function Cors:Handle(ctx, next)
    local requestOrigin = ctx:Get("origin");
    if (not requestOrigin) then return next() end 

    local origin = nil;
    local allowOrigin = self:GetAllowOrigin();
    if (type(allowOrigin) == "function") then 
        origin = allowOrigin(ctx);
        if (not origin) then return next() end
    else 
        origin = allowOrigin or requestOrigin;
    end

    local credentials = nil;
    local allowCredentials = self:GetAllowCredentials();
    if (type(allowCredentials) == "function") then 
        credentials = allowCredentials(ctx);
    else 
      credentials = allowCredentials;
    end

    local method = ctx:GetMethod();
    if (method ~= "options") then
        ctx:Set('Access-Control-Allow-Origin', origin);
        if (credentials) then ctx:Set('Access-Control-Allow-Credentials', 'true') end 
        if (self:GetExposeHeaders()) then set('Access-Control-Expose-Headers', self:GetExposeHeaders()) end
        return next();
    else
        if (not ctx:Get("access-control-request-method")) then return next() end 
        ctx:Set("Access-Control-Allow-Origin", origin);
        if (credentials) then ctx:Set('Access-Control-Allow-Credentials', 'true') end 
        if (self:GetMaxAge()) then ctx:Set("Access-Control-Max-Age", self:GetMaxAge()) end
        if (self:GetAllowMethods()) then ctx:Set("Access-Control-Allow-Methods", self:GetAllowMethods()) end
        local allowHeaders = self:GetAllowHeaders() or ctx:Get("Access-Control-Request-Headers");
        ctx:Set("Access-Control-Allow-Headers", allowHeaders);
        ctx:SetStatusCode(204);
    end
end