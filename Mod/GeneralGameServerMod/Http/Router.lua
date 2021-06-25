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
	any = "any",
}

local Route = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), {});
Route:Property("RegPath");
Route:Property("Path");
Route:Property("Paths");
Route:Property("Args");
Route:Property("Controller");

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
    local controller = self:GetController();

    if (not controller or not funcname) then return end 

    if (type(controller) == "function") then
        return controller(ctx);
    elseif type(controller) == "table" then
        local func = controller[funcname];
        if (type(func) == "function") then return func(controller, ctx) end
        funcname = self:GetActionMethod("any");
        func = controller[funcname];
        if (type(func) == "function") then return func(controller, ctx) end
    else
        --error("controller type error")
    end
end

function Route:ParseActionHandleString(action_headle_str)
    for handle_str in string.gmatch(action_headle_str or "any", '([^,]+)') do
		method, funcname = string.match(handle_str, "(.*):(.*)")
		if not method or method == "" then
			method = method_list[string.lower(handle_str)] or "any"
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
    route:SetRegExp(isregpath and regpath or nil);
    route:SetPaths(paths);
    route:SetArgs(argslist);

    return route;
end

Router:Property("UrlPrefix", "");

function Router:ctor()
    self.root_route = Route:new();
    self.regexp_routes = {}
    self.normal_routes = {}
end


-- path: url路劲
-- controller: table|function
-- action_headle_str: string 处理方式
function Router:Router(path, controller, action_headle_str)
    local route = self.root_route:GetRouteByPath(path);
    local regpath = route:GetRegPath();

    if (regpath) then 
        self.regexp_routes[regpath] = route;
    else
        self.normal_handler[path] = route;
    end

    route:SetController(controller);
    route:ParseActionHandleString(action_headle_str)

	return self
end

function Router:GetNormalRoute(path)
    return self.normal_routes[path];
end

function Route:GetRegExpRoute(path)
    for _, route in pairs(self.regexp_routes) do
        if (string.match(path, route:GetRegPath())) then
            return route;
        end
    end
end

function Router:Handle(ctx)
	local path = ctx:GetPath();
    local params = self:GetParams();
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

	if self.auto_match_url_prefix and #self.auto_match_url_prefix > 0 and (string.find(path, self.auto_match_url_prefix) == 1) then
		url_params = {}
		temp = string.gsub(path, self.auto_match_url_prefix, "")
		for word in string.gmatch(temp, '([^/]+)') do
			url_params[#url_params+1] = word
		end
		-- 控制器自动匹配
		controller = self:get_controller(url_params[1]) 
		table.remove(url_params, 1)
		
		--log(url_params)
		--log(controller)
		if url_params[1] == nil or tonumber(url_params[1]) then
			funcname = method
		else
			funcname = url_params[1]
			table.remove(url_params,1)
		end

		if type(controller) == "table" and controller[funcname] then
			ctx.request.url_params = url_params
			return (controller[funcname])(controller, ctx)
		end
	end

	ctx:Send(nil, 204);
    return;
end

function router:get_controller(ctrl_name)
	if not ctrl_name or ctrl_name == "" then
		return nil
	end

	local ctrl = nil
	for _, path in ipairs(self.controller_paths) do
		if ctrl then
			return ctrl
		end

		xpcall(function()
			ctrl = nws.import(path .. ctrl_name)
		end, function(e)
			log(e)
		end)
	end
	
	-- TODO 添加配置选项 是否开启自动构建控制
	if not ctrl then
		ctrl = controller:new(ctrl_name)
	end
	
	return ctrl
end

