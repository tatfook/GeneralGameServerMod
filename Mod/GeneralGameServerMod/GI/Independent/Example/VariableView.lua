
local VariableView = require("VariableView");

VariableView:AddWatchKeyValue("key", "hello world");
VariableView:AddWatchKeyValue("obj", {key = 1});

VariableView:ShowUI();