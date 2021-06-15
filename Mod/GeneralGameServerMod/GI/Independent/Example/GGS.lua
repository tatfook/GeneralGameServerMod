local GGS = require("GGS");
local State = require("State");
local UI = require("UI");

local __GGS_STATE__ = GGS:GetState();

-- 关闭自动同步状态数据
GGS:SetAutoSyncState(false);
-- 初始化状态数据 
__GGS_STATE__.level = 1;
-- 初始化完毕开启状态同步
GGS:SetAutoSyncState(true);


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
        ]]
    });
end

-- 连接网络
GGS:Connect(function()
    GGS:Send("Connect Success");
    ShowUI();
end);

-- 接收数据
GGS:SetRecvCallBack(function(data)
    echo(data);
end);

