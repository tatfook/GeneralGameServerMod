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


local Coroutine = inherit(ToolBase, module());

Coroutine:Property("CallBack");                         -- 回调函数
Coroutine:Property("Running", false, "IsRunning");      -- 是否退出
Coroutine:Property("Exit", false, "IsExit");            -- 是否退出

-- 构造函数
function Coroutine:ctor()
	self.__co__ = __coroutine_create__(function(...)
		__xpcall__(self:GetCallBack(), ...);
        self:Exit();
    end);

	local __parent_coroutine_data__ = __get_coroutine_data__();
	local __coroutine_data__ = __get_coroutine_data__(self.__co__);

	if (__parent_coroutine_data__.__independent__) then
		__coroutine_data__.__parent_coroutine_data__ = __parent_coroutine_data__;
		__coroutine_data__.__independent__ = true;
		__parent_coroutine_data__.__children_coroutine_data_map__[__coroutine_data__] = __coroutine_data__;
	end

	__coroutine_data__.__coroutine__ = self;
	self.__coroutine_data__ = __coroutine_data__;
end

function Coroutine:Init()
	return self;
end

-- 运行协程
function Coroutine:Run(callback, ...)
    if (self:IsExit() or type(callback) ~= "function") then return end
    self:SetRunning(true);
	self:SetExit(false);
    self:SetCallBack(callback);
	local __co__ = self.__co__;    -- 先备份 callback 执行完协程可能退出将 __co__ 置空
	__coroutine_resume__(__co__, ...);
    return __co__;
end

-- 退出
function Coroutine:Exit()
    self:SetRunning(false);
    self:SetExit(true);
	-- 不独立数据共享, 只清楚引用
	if (not self.__coroutine_data__.__independent__) then __all_coroutine_data__[self.__co__] = nil end 
    self.__co__ = nil;
end

function __get_coroutine_by_co__(co)
	return __get_coroutine_data__(co).__coroutine__;
end

function __get_all_coroutine__(co)
    local __coroutine__ = __get_coroutine_by_co__(co);
	if (not __coroutine__) then return {} end

	-- 获取所有关联协程
	local __coroutines__ = {};
	local function GetAllCoroutine(__coroutine__)
		__coroutines__[__coroutine__] = __coroutine__;
		for _, __coroutine_data__ in pairs(__coroutine__.__coroutine_data__.__children_coroutine_data_map__) do GetAllCoroutine(__coroutine_data__.__coroutine__) end
		return __coroutines__;
	end

	return GetAllCoroutine(__coroutine__);
end

function __coroutine_is_exit__(co)
    local __coroutine__ = __get_coroutine_by_co__(co);
    return not __coroutine__ or __coroutine__:IsExit();
end

function __coroutine_exit__(co, bAutoCleanCoroutineData) 
    local __coroutine__ = __get_coroutine_by_co__(co);
	if (not __coroutine__) then return end
    __coroutine__:Exit();
	if (bAutoCleanCoroutineData) then __clean_coroutine_data__(__coroutine__.__co__) end
end

-- 退出所有关协程
function __coroutine_exit_all__(co, bAutoCleanCoroutineData)
	for _, __coroutine__ in pairs(__get_all_coroutine__(co)) do 
		local __coroutine_data__ = __coroutine__.__coroutine_data__;
		__coroutine__:Exit(); 
		if (bAutoCleanCoroutineData) then __clean_coroutine_data__(__coroutine_data__.__co__) end
	end 
end

function __independent_run__(...)
	local __coroutine__ = Coroutine:new():Init();
	__coroutine__.__coroutine_data__.__independent__ = true;
	return __coroutine__:Run(...);
end

function __run__(...)
    return Coroutine:new():Init():Run(...);
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
	if (__coroutine_is_exit__()) then __error__("协程已停止执行") end 
	if (isExit) then __error__("非函数激活退出") end  
end
