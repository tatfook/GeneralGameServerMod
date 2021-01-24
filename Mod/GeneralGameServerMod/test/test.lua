

-- local Test = NPL.load("Mod/GeneralGameServerMod/Test/Test.lua");

local base = {key = 1}

function base:func()
end

local obj = setmetatable({}, {__index = base});

print(obj.key, obj.func);

for key, val in pairs(obj) do
    print(key, val)
end
