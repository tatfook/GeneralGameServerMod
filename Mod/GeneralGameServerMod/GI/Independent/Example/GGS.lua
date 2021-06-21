local GGSState = require("GGSState");

local __GGS_STATE__ = GGSState:GetState();

__GGS_STATE__.level = __GGS_STATE__.level or 1;

local function ShowUI()
    UI.ShowWindow({
        GlobalScope = State:GetScope(),
        OnClick = function()
            __GGS_STATE__.level = __GGS_STATE__.level + 1;
        end
    }, {
        template = [[
<template>
    <div>{{__GGS_STATE__.level}}</div>
    <div onclick=OnClick>按钮</div>
</template>
        ]],
        width = 300,
        height = 300,
    });
end

-- 连接网络
GGS:Connect(function()
    GGS:Send("Connect Success");
    ShowUI();
end);

-- 接收数据
GGS:SetRecvCallBack(function(data)
    log(data);
end);

