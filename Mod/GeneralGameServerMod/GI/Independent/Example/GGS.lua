local GGS = require("GGS");

-- 监听自定义网络消息
GGS:On("msg", function(data)
    print(data);
end)

-- 发送自定义消息
GGS:Emit("msg", "hello world");