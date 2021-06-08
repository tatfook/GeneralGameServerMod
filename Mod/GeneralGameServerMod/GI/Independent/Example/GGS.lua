

-- 连接网络
GGS_Connect(function()
    -- 连接成功

    -- 发送数据
    GGS_Send({"hello world", "this is a test"});
end);

-- 接收数据
GGS_Recv(function(data)
    echo(data);
end);

