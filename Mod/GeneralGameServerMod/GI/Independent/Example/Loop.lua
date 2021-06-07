

local LoopCount = 0;

function main()
    print("main exec"); 
end

function loop(event)
    LoopCount = LoopCount + 1;
    
    if (LoopCount > 1000) then
        exit(); -- 主动退出
    end
end

function clear()
    print("clear exec");
end