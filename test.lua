

local str = [[
return text
]]

function func()
    print("this is a test");
end

func 1;

local code_func, errmsg = loadstring(str);
if (not code_func) then
    print(errmsg);
    return
end
--setfenv(code_func, {text = "tet"});
print(code_func())
