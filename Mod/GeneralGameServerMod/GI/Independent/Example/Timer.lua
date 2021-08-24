
-- local Timer = require("Timer");

-- function main()
--     print("=============main=============");

--     Timer.Timeout(1000, function()
--         print("timeout")
--     end);

--     local count = 1;
--     Timer.Interval(1000, function(timer)
--         print("interval", count);
--         count = count + 1;
--         if (count > 5) then
--             timer:Stop();
--         end
--     end)
-- end

-- local last_tick1 = 0;
-- __run__(function()
--     while(__is_running__()) do
--         local tick = __get_tick_count__();
--         sleep(1000);
--         print("-------------------------1", tick, tick - last_tick1)
--         last_tick1 = tick;
--     end
-- end)

-- local last_tick2 = 0;
-- __run__(function()
--     while(__is_running__()) do
--         local tick = __get_tick_count__();
--         sleep(1000);
--         print("-------------------------2", tick, tick - last_tick2)
--         last_tick2 = tick;
--     end
-- end)

-- local last_tick3 = 0;
-- __run__(function()
--     while(__is_running__()) do
--         local tick = __get_tick_count__();
--         sleep(1000);
--         print("-------------------------3", tick, tick - last_tick3)
--         last_tick3 = tick;
--     end
-- end)

SetTimeout(1000, function()
    print("SetTimeout");
end)

SetInterval(1000, function()
    print("SetInterval")
end)