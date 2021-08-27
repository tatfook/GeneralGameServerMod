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

Coroutine:Property("CallBack");                   -- 回调函数
Coroutine:Property("Stop", true, "IsStop");       -- 是否停止
Coroutine:Property("Exit", false, "IsExit");      -- 是否退出

local __all_coroutine__ = {};

-- 构造函数
function Coroutine:ctor()
	self.__cos__ = {};                            -- 衍生协程
    -- self.__resume__ = function(...)
    --     -- 环境销毁则换醒协程退出
    --     if (__is_running__()) then 
    --         if (self:IsStop() or self:IsExit()) then return end 
    --     end

    --     -- 不能已销毁
    --     if (not self.__co__) then return end 

    --     -- 唤醒协程
    --     RemoveTickCallBack(self.__resume__);
    --     __coroutine_resume__(self.__co__, ...);
    -- end
    
    -- self.__yield__ = function()
    --     -- 环境停止则不在挂起执行
    --     if (not __is_running__()) then return end 

    --     self:SetStop(true);
    --     self:SetCallBack(nil);
    --     RegisterTickCallBack(self.__resume__);
    --     return __coroutine_yield__();
    -- end

    -- self.__co__ = __coroutine_create__(function(...)
    --     pack(...); 
    --     while(not self:IsExit() and __is_running__()) do
    --         if (not self:IsStop()) then
    --             local callback = self:GetCallBack();
    --             if (type(callback) == "function") then 
    --                 __xpcall__(callback, unpack());
    --             end 
    --         end
    --         pack(self.__yield__());
    --     end
    --     self:Exit();
    -- end);

	self.__co__ = __coroutine_create__(function(...)
		local callback = self:GetCallBack();
		if (type(callback) == "function") then 
			__xpcall__(callback, ...);
		end 
        self:Exit();
    end);

    __all_coroutine__[self.__co__] = self;

	local cur_co = __coroutine_running__();
	local __co__ = __all_coroutine__[cur_co];
	__co__:AddCoroutine(self);
end

function Coroutine:Init()
    return self;
end

-- 运行协程
function Coroutine:Run(callback, ...)
    if (self:IsExit()) then return end
    self:SetStop(false);
    self:SetCallBack(callback);
    self.__resume__(...);
    return self.__co__;
end

-- 是否在运行
function Coroutine:IsRunning()
    return not self:IsStop() and not self:IsExit();
end

-- 停止
function Coroutine:Stop()
    self:SetStop(true);
end

-- 退出
function Coroutine:Exit()
    self:SetExit(true);
    self:SetStop(true);
    __all_coroutine__[self.__co__] = nil;
    self.__co__ = nil;
end

function GetCoroutineByCo(co)
    if (not co) then co = __coroutine_running__() end
    return __all_coroutine__[co];
end

function __coroutine_is_stop__(co)
    local __co__ = GetCoroutineByCo(co);
    return not __co__ or not __co__:IsRunning();
end

function __coroutine_stop__(co) 
    local __co__ = GetCoroutineByCo(co);
    return __co__ and __co__:Stop();
end

function GetStopCoroutine()
    for _, __co__ in ipairs(__all_coroutine__) do
        if (__co__:IsStop()) then return __co__ end
    end
    return Coroutine:new():Init();
end

function __run__(...)
    return GetStopCoroutine():Run(...);
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
	if (__coroutine_is_stop__()) then __error__("协程停止执行") end 
	if (isExit) then __error__("非函数激活退出") end  
end
