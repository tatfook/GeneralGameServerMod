local NetState = require("NetState");

local __GGS_ALL_USER_STATE__ = NetState:GetAllUserState();
local __GGS_USER_STATE__ = NetState:GetUserState();

__GGS_USER_STATE__.ClickCount = __GGS_USER_STATE__.ClickCount or 1;

ShowWindow({
    __GGS_USER_STATE__ = __GGS_USER_STATE__,
    __GGS_ALL_USER_STATE__ = __GGS_ALL_USER_STATE__,
    OnClick = function()
        __GGS_USER_STATE__.ClickCount = __GGS_USER_STATE__.ClickCount + 1;
    end
}, {
    template = [[
<template style="width: 100%; height: 100%; background-color: #ffffff;">
<div>{{"点击总和" .. GenerateTotalClickCount()}}</div>
<div>{{"点击次数" .. __GGS_USER_STATE__.ClickCount}}</div>
<div style="white-space: pre;">{{GenerateAllUserState()}}</div>
<div onclick=OnClick>按钮</div>
</template>
<script>
function GenerateTotalClickCount()
    local total = 0;
    for username, state in pairs(__GGS_ALL_USER_STATE__) do
        total = total + (state.ClickCount or 1)
    end
    return total;
end

function GenerateAllUserState()
    local text = "";
    for username, state in pairs(__GGS_ALL_USER_STATE__) do
        text = text .. "用户:" .. username .. "   点击次数" .. (state.ClickCount or 1) .. "\n";
    end
    return text;
end
</script>
    ]],
    width = 300,
    height = 300,
});

