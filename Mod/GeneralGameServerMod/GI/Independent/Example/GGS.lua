local GGS = require("GGS");

-- 连接网络
GGS:Connect();

-- 接收数据
GGS:SetRecvCallBack(function(data)
    echo(data);
end);

