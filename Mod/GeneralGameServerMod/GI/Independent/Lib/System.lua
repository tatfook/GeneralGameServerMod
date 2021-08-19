--[[
Title: System
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local System = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/System.lua");
------------------------------------------------------------
]]


local System = module("System");

local __arguments__ = {n = 0};

function unpack()
	return __arguments__[1], __arguments__[2], __arguments__[3], __arguments__[4], __arguments__[5], __arguments__[6], __arguments__[7], __arguments__[8], __arguments__[9];
end

function pack(...)
	-- 先清除旧参数
	for i = 1, __arguments__.n do __arguments__[i] = nil end 
	-- 获取新参数大小
	__arguments__.n = __select__("#", ...);
	-- 设置新参数
	for i = 1, __arguments__.n do __arguments__[i] = __select__(i, ...) end 

	return unpack();
end

function select(index)
	if (index == "#") then return __arguments__.n end 

	index = index or 1;
    return __arguments__[index], __arguments__[index + 1], __arguments__[index + 2], __arguments__[index + 3], __arguments__[index + 4], __arguments__[index + 5], __arguments__[index + 6], __arguments__[index + 7], __arguments__[index + 8], __arguments__[index + 9];
end


function __run__(callback, ...)
	if (type(callback) == "string") then
		local func, err = loadstring(callback, "__run__");
		if (not func or err) then return end
		setfenv(func, _G);
		callback = func;
	end
	if (type(callback) ~= "function") then return end 

	__coroutine_resume__(__coroutine_create__(function(callback, ...)
		__xpcall__(callback, ...);
	end), callback, ...);
end

-- 废弃
function run(callback, ...)
	__run__(callback, ...)
end

function async_run(...)
	__run__(...);
end

function sync_run(callback, ...)
	if (type(callback) ~= "function") then return end 
	callback(...);
end

-- 空函数
local function null_function() end

function sleep(sleep)
	local sleepTo = __get_timestamp__() + (sleep or 0);
	local isSleeping = true;

	-- 获取当前协程
	local code_block_co = __get_code_globals__().cur_co;
	local cur_co = __coroutine_running__();
	local cur_co_is_code_block_co = code_block_co and code_block_co.co == cur_co;

	-- 唤醒检测函数
	local function SleepLoopCallBack()
		local curtime = __get_timestamp__();
		isSleeping = isSleeping and curtime < sleepTo and __is_running__();  -- 加上__is_running__如果沙盒可以快速停止相关协程的等待, 从而快速退出

		-- 如果挂起的不是执行协程, 则由执行协程唤醒继续执行, 定时立即唤醒防止无法退出, 若不考虑退出问题可以加上 not isSleeping 条件
		if (not isSleeping and cur_co ~= __co__) then 
			if (cur_co_is_code_block_co) then
				if (not code_block_co.isStopped) then
					-- 代码方块协程设置当前协程环境
					__get_code_globals__():SetCurrentCoroutine(code_block_co);
					-- 唤醒协程
					__coroutine_resume__(cur_co, null_function)
				end
			else
				-- 普通非默认协程直接唤醒
				__coroutine_resume__(cur_co, null_function)
			end
		end   
	end
	
	-- 注册主线程定时回调, 由主线唤醒当前协程的挂起
	RegisterEventCallBack(EventType.LOOP, SleepLoopCallBack);

	while (isSleeping) do 
		-- 打包返回值
		local callback = pack(__coroutine_yield__()); 
		
		if (type(callback) ~= "function") then
			-- 激活的不是函数则结束sleep退出
			isSleeping = false;
		else
			sync_run(unpack());
			-- 激活的是函数则创建新协程执行
			-- if (isSleeping and callback ~= null_function) then
			-- 	run(unpack());
			-- else
			-- 	sync_run(unpack());
			-- end
		end
	end
	
	-- 移除定时回调
	RemoveEventCallBack(EventType.LOOP, SleepLoopCallBack);
	if (not __is_running__()) then __error__("环境已销毁") end 
end

function __independent_run__(callback, G)
	G = G or {};
	local __all_window__ = {};
	local __all_entity__ = {};
	local __all_timer__ = {};
	G.CreateEntity = function(...)
		local entity = CreateEntity(...);
		if (entity) then table.insert(__all_entity__, entity) end
		return entity;
	end

	G.ShowWindow = function(...)
		local window = ShowWindow(...);
		if (window) then table.insert(__all_window__, window) end
		return window;
	end

	G.SetTimeout = function(...)
		local timer = SetTimeout(...);
		if (timer) then end
	end
end

function GetFullPath(path, directory)
	directory = directory or __module__.__directory__ or "";
	if (string.match(path, "^[^/\\@%%]")) then path = directory .. "/" .. path end
	path = ToCanonicalFilePath(path, "linux");
	local paths = split(path, "/");
	local filenames = {};
	for _, filename in ipairs(paths) do
		if (filename == ".") then
		elseif (filename == "..") then
			table.remove(filenames, #filenames);
		else
			table.insert(filenames, #filenames + 1, filename);
		end
	end
	local full_path = table.concat(filenames, "/");
	return ToCanonicalFilePath(full_path);
end
