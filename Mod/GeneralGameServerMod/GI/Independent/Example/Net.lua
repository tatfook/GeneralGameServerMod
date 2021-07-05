

NetConnect(function()
    print("========connect success=========");

    NetSend({"hello world"})
end)

-- SetInterval(1000, function()
--     print("========")
--     NetSend({"hello world"})
-- end)