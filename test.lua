


local obj = {a = 1}
setmetatable(obj, {__index = {key = 1}})

for key, value in pairs(obj) do
    print(key, value);
end
