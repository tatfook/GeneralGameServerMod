--[[
Title: Coroutine
Author(s):  wxa
Date: 2021-06-01
Desc: 协程
use the lib:
------------------------------------------------------------
local Coroutine = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/Coroutine.lua");
------------------------------------------------------------
]]


local function __coroutine_run_before__(__coroutine_data__, __parent_coroutine_data__)
	if (__parent_coroutine_data__.__independent__) then
		__coroutine_data__.__parent_coroutine_data__ = __parent_coroutine_data__;
		__coroutine_data__.__independent__ = true;
		__parent_coroutine_data__.__children_coroutine_data_map__[__coroutine_data__] = __coroutine_data__;
	end
	__coroutine_data__.__exit__ = false;
end

local function __coroutine_run_after__(__coroutine_data__, __parent_coroutine_data__)
	-- 不独立数据共享, 只清楚引用
	__coroutine_data__.__exit__ = true;
	if (not __coroutine_data__.__independent__) then __all_coroutine_data__[__coroutine_data__.__co__] = nil end 
end

function __new_coroutine__(independent)
	local __parent_coroutine_data__ = __get_coroutine_data__();
	return __coroutine_create__(function(...)
		local __coroutine_data__ = __get_coroutine_data__();
		__coroutine_data__.__independent__ = independent;

		__coroutine_run_before__(__coroutine_data__, __parent_coroutine_data__);

		__xpcall__(...);

		__coroutine_run_after__(__coroutine_data__, __parent_coroutine_data__);
	end);
end

function __get_all_coroutine_data__(co)
    local __coroutine_data__ = __get_coroutine_data__(co, false);
	if (not __coroutine_data__) then return {} end

	-- 获取所有关联协程
	local __coroutine_data_list__ = {};
	local function GetAllCoroutineData(__coroutine_data__)
		table.insert(__coroutine_data_list__, __coroutine_data__);
		for _, __children_coroutine_data__ in pairs(__coroutine_data__.__children_coroutine_data_map__) do GetAllCoroutine(__children_coroutine_data__) end
		return __coroutine_data_list__;
	end

	return GetAllCoroutineData(__coroutine_data__);
end

function __coroutine_is_exit__(co)
    local __coroutine_data__ = __get_coroutine_data__(co, false);
    return not __coroutine_data__ or __coroutine_data__.__exit__;
end

function __coroutine_exit__(co, bAutoCleanCoroutineData) 
    local __coroutine_data__ = __get_coroutine_data__(co, false);
	if (not __coroutine_data__) then return end
	__coroutine_data__.__exit__ = true;
	if (bAutoCleanCoroutineData) then __clean_coroutine_data__(__coroutine_data__.__co__) end
end

-- 退出所有关协程
function __coroutine_exit_all__(co, bAutoCleanCoroutineData)
	for _, __coroutine_data__ in pairs(__get_all_coroutine_data__(co)) do 
		__coroutine_data__.__exit__ = true;
		if (bAutoCleanCoroutineData) then __clean_coroutine_data__(__coroutine_data__.__co__) end
	end 
end

function __independent_run__(...)
	local __co__ = __new_coroutine__(true);
	__coroutine_resume__(__co__, ...);
	return __co__;
end

function __run__(...)
    local __co__ = __new_coroutine__(false);
	__coroutine_resume__(__co__, ...);
	return __co__;
end

-- 废弃
function run(callback, ...)
	__run__(callback, ...)
end

function async_run(...)
	return __run__(...);
end

function sync_run(callback, ...)
	if (type(callback) ~= "function") then return end 
	callback(...);
end

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
			-- if (isSleeping and callback ~= null_function) then
			-- 	async_run(unpack());
			-- else
			-- 	sync_run(unpack());
			-- end
		end
	end

	-- 移除定时回调
	RemoveTickCallBack(SleepLoopCallBack);
	if (not __is_running__()) then __error__("环境已销毁") end
	if (__coroutine_is_exit__()) then __error__("协程已停止执行") end 
	if (isExit) then __error__("非函数激活退出") end  
end
