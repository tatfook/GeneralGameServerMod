
obj = {}

function test()
    local obj = {key};
    return function()
        print(obj);
    end
end

local func = test();


print("global", obj);
print("local", func());
