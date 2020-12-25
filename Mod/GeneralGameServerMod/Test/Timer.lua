

-- local Timer = NPL.load("Mod/GeneralGameServerMod/Test/Timer.lua");
commonlib.TimerManager.SetTimeout(function()  
    print("=========timer============")
end, 1)
print("===begin for===")
for i = 1, 100000000 do
    for j = 1, 1000000 do
    end
end
print("===end for===")