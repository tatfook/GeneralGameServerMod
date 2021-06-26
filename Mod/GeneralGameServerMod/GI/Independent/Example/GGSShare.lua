
SetInterval(1000, function()
    local score = GetSharedData("score") or 0;
    SetSharedData("score", score + 1)
    print("---", score + 1)
end)

OnSharedDataChanged("score", function(value)
    print("===", value);
end)

RegisterGGSConnectEvent(function()
    print(GetSharedData("score"));
end)
    