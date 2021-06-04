
local Timer = require("Timer");

function main()
    print("=============main=============");

    Timer.Timeout(1000, function()
        print("timeout")
    end);

    local count = 1;
    Timer.Interval(1000, function(timer)
        print("interval", count);
        count = count + 1;
        if (count > 5) then
            timer:Stop();
        end
    end)
end

