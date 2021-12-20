冬奥会主世界：        (开发版：114607)   rls环境：待上传
程序课程Demo世界：     (开发版：114611)  rls环境：待上传

用户登录后先调一下11000这个兑换，就可以获得40008物品，之前的记录物品是这样获取的
夏令营世界ID: 70351

local clientData = KeepWorkItemManager.GetClientData(gsid) or {};
KeepWorkItemManager.SetClientData(gsid, clientData, function()
    ActRedhat.ShowPage();
end);