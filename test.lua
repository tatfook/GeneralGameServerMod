


local obj = {}
local tmp = {};
setmetatable(obj, {
    __eq = function(mytable, newtable)
        print("----------------");
        return true;
    end
})

print(obj == tmp)
