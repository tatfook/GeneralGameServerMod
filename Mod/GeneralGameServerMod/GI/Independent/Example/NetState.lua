require("NetState");

local __state__ = NetInitState("test", {
    ClickCount = 1
});


print(__state__.ClickCount)
ShowWindow({
    ClickCount = function()
        return __state__.ClickCount;
    end,
    OnClick = function()
        __state__.ClickCount = __state__.ClickCount + 1;
    end
}, {
    template = [[
<template style="width: 100%; height: 100%; background-color: #ffffff;">
<div>{{"点击次数" .. ClickCount()}}</div>
<div onclick=OnClick>按钮</div>
</template>
    ]],
    width = 300,
    height = 300,
});

