
local co1, co2 = nil, nil;
function func1(arg)
    print("func1 start");
    coroutine.resume(co2);
    print("func1 end");
end

function func2(arg)
    print("func2 start");
    ParaEngine.Sleep(3);
    print("func2 end");
end

-- co1 = coroutine.create(func1);
-- co2 = coroutine.create(func2);
-- coroutine.resume(co1);

local co_timer = nil
local function co_timer_func()
    print("----------1")
    commonlib.TimerManager.SetTimeout(function()  
        coroutine.resume(co_timer);
    end, 2000);
    coroutine.yield();
    print("-------------2")
end
-- co_timer = coroutine.create(co_timer_func);
-- coroutine.resume(co_timer);



-- NPL.load("Mod/GeneralGameServerMod/Test/Coroutine.lua", true);