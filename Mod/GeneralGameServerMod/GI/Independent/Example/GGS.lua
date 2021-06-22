local GGS = require("GGS");

-- 连接网络
GGS:Connect(function()
    GGS:Send("Connect Success");
    ShowUI();
end);


