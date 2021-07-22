

RPC_OnBroadcast(function(data)
    print("RPC_OnBroadcast", data);
end);

RPC_Call("Login", {username = GetUserName()}, function(data)
    print("login success", data)
    print("-------------------------")
    RPC_Broadcast("hello world")
end);