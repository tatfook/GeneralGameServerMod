

-- NetConnect(function()
--     print("========connect success=========");

--     NetSend({"hello world"})

--     -- NetClose();
-- end)

-- NetOnDisconnected(function()
--     print("=================disconnection=============")
-- end)



-- SetInterval(1000, function()
--     print("========")
--     NetSend({"hello world"})
-- end)

local Net = require("Net");

Net:Connect(function(data)
    print("==============121")
    echo(data)
end);