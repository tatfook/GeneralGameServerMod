--[[
Title: Router
Author(s):  wxa
Date: 2021-06-23
Desc: Router
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Http/Router.lua");
------------------------------------------------------------
]]

local Router = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local method_list = {
	get = "get",
	post = "post",
	delete = "delete",
	put = "put",
	head = "head",
	patch = "patch",
	options = "options",
	all = "all",
}

local Route = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), {});
Route:Property("RegPath");
Route:Property("Path");
Route:Property("Paths");
Route:Property("Args");
Route:Property("CallBack");

function Route:ctor()
    self.parent_route = nil;
    self.routes = {};  -- 子路由对象
    self.action_method = {}; -- 行为方法表
end

function Route:GetActionMethod(action)
    return action and self.action_method[action] or action;
end

function Route:Handle(ctx, action)
	local funcname =  self:GetActionMethod(action or ctx:GetMethod());
    local callback = self:GetCallBack();

    if (not callback or not funcname) then return end 

    if (type(callback) == "function") then
        return callback(ctx);
    elseif type(callback) == "table" then
        local func = callback[funcname];
        if (type(func) == "function") then return func(callback, ctx) end
        funcname = self:GetActionMethod("all");
        func = callback[funcname];
        if (type(func) == "function") then return func(callback, ctx) end
    else
        --error("controller type error")
    end
end

function Route:ParseActionHandleString(action_headle_str)
    for handle_str in string.gmatch(action_headle_str or "all", '([^,]+)') do
		method, funcname = string.match(handle_str, "(.*):(.*)")
		if not method or method == "" then
			method = method_list[string.lower(handle_str)] or "all"
			funcname = handle_str
		end

		if not funcname or funcname == "" then
			funcname = method
		end

		self.action_method[method] = funcname;
	end
end

-- 解析路径
function Route:GetRouteByPath(path)
	-- 是否正则path 正则串  路径参数名列表
	local int = '([%%d]+)'
	local number = '([%%d.]+)'
	local string = '([%%w]+)'
	local none = '([%%d%%w]+)'
	local regpath = ""
	local argslist = {}
	local argscount = 1
	local isregpath = false
	local paths = {}
	for word in string.gmatch(path, '([^/]+)') do
		local argname = string.match(word, '(:[%w]+)')
		local regstr = string.match(word, '(%(.*%))')
		--print(argname, regstr)
		paths[#paths+1] = word
		if argname or regstr then
			if argname and not regstr then
				word = string.gsub(word, argname, none)
			elseif argname and regstr then
				word = string.gsub(word, argname, "")
			end
			word = string.gsub(word, '(%(int%))', int)
			word = string.gsub(word, '(%(number%))', number)
			word = string.gsub(word, '(%(string%))', string)
			argslist[argscount] = argname or argscount
			argscount = argscount + 1
			isregpath = true
		end
		regpath = regpath .. '/' .. word 
	end
	regpath = '^' .. regpath .. '$'

    local route = self;
    for _, path in ipairs(paths) do 
        route.routes[path] = route.routes[path] or Route:new();
        route.routes[path].parent_route = route;
        route = route.routes[path];
    end

    route:SetPath(path);
    route:SetRegPath(isregpath and regpath or nil);
    route:SetPaths(paths);
    route:SetArgs(argslist);

    return route;
end

Router:Property("UrlPrefix", "");

function Router:ctor()
    self.root_route = Route:new();
    self.regexp_routes = {};
    self.normal_routes = {};
end

-- path: url路劲
-- controller: table|function
-- description: string 处理方式
function Router:Router(path, callback, description)
    local route = self.root_route:GetRouteByPath(path);
    local regpath = route:GetRegPath();

    if (regpath) then 
        self.regexp_routes[regpath] = route;
    else
        self.normal_routes[path] = route;
    end

    route:SetCallBack(callback);
    route:ParseActionHandleString(description)

	return self
end

function Router:GetNormalRoute(path)
    return self.normal_routes[path];
end

function Router:GetRegExpRoute(path)
    for _, route in pairs(self.regexp_routes) do
        if (string.match(path, route:GetRegPath())) then
            return route;
        end
    end
end

function Router:Handle(ctx)
	local path = ctx:GetPath();
    local params = ctx:GetParams();
    local route = nil;
	
	-- 普通完整匹配
	route = self:GetNormalRoute(path);
	if (route) then return route:Handle(ctx) end
	
    -- 正则路由
    route = self:GetRegExpRoute(path);
    if (route) then
		local url_params = {string.match(path, route:GetRegPath())};
        for i, v in ipairs(route:GetArgs()) do params[v] = url_params[i] end
        return route:Handle(ctx);
    end

    -- 控制器路径匹配
	route = self:GetNormalRoute(string.gsub(path, '/[%w%d]+$', ''));
	if (route) then
		local action = string.match(path,'/([%w%d]+)$');
		local id = tonumber(action);
		if (id) then params[1], action = id, nil end
        route:Handle(ctx, action);
    end

	ctx:Send(nil, 204);
    return;
end

-- 单列模式
Router:InitSingleton();