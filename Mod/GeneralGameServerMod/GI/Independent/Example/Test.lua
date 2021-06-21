



local GGS = require("GGS");

GGS:Connect(function()
	print("===========================s")
	GGS:SetUserData({nickname = "xiaoyao", score = 10});
end)

GGS:OnUserData(function(userdata)
	log(userdata)
end)

-- RegisterEventCallBack(EventType.KEY_DOWN, function(event)
-- 	local keyname = event.keyname;
-- 	print(keyname);
-- 	if (keyname == "DIK_A" or keyname == "DIK_LEFT") then
-- 	end
-- end)

-- function test(arg)
-- 	log(arg);
-- end

-- RegisterEventCallBack("ABC", function(ev)
-- 	log(ev)
-- end);
-- TriggerEventCallBack("ABC", 32, 3232)

-- print(GetPlayer():GetBlockPos())
-- local Log = require("Log");
-- print("---------1")
-- Log:Info("hello world")

-- SetInterval(1000, function()
--     print("timer");
-- end)
-- sleep(4000);
-- log("--------2121")

