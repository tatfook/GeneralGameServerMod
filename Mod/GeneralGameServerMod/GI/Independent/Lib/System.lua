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

function __run__(callback, ...)
	if (type(callback) == "string") then
		local func, err = loadstring(callback, "__run__");
		if (not func or err) then return end
		setfenv(func, _G);
		callback = func;
	end
	if (type(callback) ~= "function") then return end 

	local co = __coroutine_create__(function(callback, ...)
		__xpcall__(callback, ...);
	end);
	__coroutine_resume__(co, callback, ...);
	
	return co;
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
	if (__is_tick_co_env__()) then
		print("======================TICK ENV: sleep execution not allowed=========================")
		return __error__("TICK ENV: sleep execution not allowed")
	end

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
		if (not isSleeping) then 
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
	RegisterTickCallBack(SleepLoopCallBack);

	local isExit = false;
	while (isSleeping) do 
		-- 打包返回值
		local callback = pack(__coroutine_yield__()); 
		
		if (type(callback) ~= "function") then
			-- 激活的不是函数则结束sleep退出当前协程
			isSleeping = false;
			isExit = true;
		else
			sync_run(unpack());
			-- 激活的是函数则创建新协程执行
			if (isSleeping and callback ~= null_function) then
				async_run(unpack());
			else
				sync_run(unpack());
			end
		end

	end

	-- 移除定时回调
	RemoveTickCallBack(SleepLoopCallBack);
	if (not __is_running__()) then __error__("环境已销毁") end
	if (isExit) then __error__("非函数激活退出") end  
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

local __checkyield_key__ = nil;
local __checkyield_count__ = 0;
local __checkyield_tick_count__ = 0;
function __checkyield__()
	local cur_tick_count = __get_tick_count__();
	if (__checkyield_tick_count__ == cur_tick_count) then
		__checkyield_count__ = __checkyield_count__ + 1;
	else
		__checkyield_tick_count__ = cur_tick_count;
		__checkyield_count__ = 0;
	end

	-- 同一时刻循环1000次 则让出协程
	if (__checkyield_count__ > 1000) then sleep() end
end

function __fileline__(filename, line_no, line_text)
	__current_filename__, __current_line_no__, __current_line_text__ = filename, line_no, line_text;
	if (__is_debug__) then
		print("__fileline__", __current_filename__, __current_line_no__, __current_line_text__);
	end
end
