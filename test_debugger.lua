

local __directory__ = "C:/Users/xiaoyao/.vscode/extensions/yinfei.luahelper-0.2.19/debugger";
package.path =  __directory__ .. "/?/init.lua;" .. package.path;
package.path =  __directory__ .. "/?.lua;" .. package.path;

_G.lua_extension = _G.lua_extension or {};
_G.lua_extension.luasocket = _G["socket.core"];

require("LuaPanda").start("127.0.0.1", 8818);

print("this is a test", 1221)

local obj = {a = 1}
setmetatable(obj, {__index = {key = 1}})

for key, value in pairs(obj) do
    print(key, value);
end
